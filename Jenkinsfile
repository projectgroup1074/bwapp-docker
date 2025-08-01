pipeline {
    agent any

    environment {
        // Change these values to your DefectDojo setup
        DEFECTDOJO_URL = 'http://192.168.28.140:8081'
        DEFECTDOJO_API_KEY = '2b45e401243a783e26ff8f81a5391ceb0bde9af1'
        DEFECTDOJO_ENGAGEMENT_ID = '1'   // Engagement ID for bWAPP-Sonar
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/raesene/bwapp.git'
            }
        }

        stage('Run ZAP Scan via Docker') {
            steps {
                sh '''
                echo "[INFO] Pulling OWASP ZAP Docker image..."
                docker pull ghcr.io/zaproxy/zaproxy:stable

                echo "[INFO] Running OWASP ZAP baseline scan..."
                docker run --rm --user root --network host \
                  -v $WORKSPACE:/zap/wrk \
                  ghcr.io/zaproxy/zaproxy:stable \
                  zap-baseline.py -t http://192.168.28.140/bWAPP/ \
                  -x /zap/wrk/zap_report.xml
                '''
            }
        }

        stage('Upload to DefectDojo') {
            steps {
                sh '''
                if [ -f "$WORKSPACE/zap_report.xml" ]; then
                    echo "[INFO] Uploading ZAP report to DefectDojo..."
                    curl -X POST "$DEFECTDOJO_URL/api/v2/import-scan/" \
                      -H "Authorization: Token $DEFECTDOJO_API_KEY" \
                      -F "engagement=$DEFECTDOJO_ENGAGEMENT_ID" \
                      -F "scan_type=ZAP Scan" \
                      -F "file=@$WORKSPACE/zap_report.xml"
                else
                    echo "[ERROR] ZAP report not found! Skipping upload."
                    exit 1
                fi
                '''
            }
        }
    }

    post {
        always {
            echo 'Cleaning up Docker...'
            sh 'docker system prune -f || true'
        }
    }
}
