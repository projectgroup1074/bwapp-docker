pipeline {
    agent any

    environment {
        // DefectDojo API details
        DEFECTDOJO_URL = "http://192.168.28.140:8080"   // Change to your DefectDojo instance
        DEFECTDOJO_API_KEY = credentials('defectdojo-api-key') // Store in Jenkins credentials
        DEFECTDOJO_PRODUCT_ID = "1"                     // Change to your product ID in Dojo

        // bWAPP target (Fix your correct URL here!)
        BWAPP_URL = "http://192.168.28.140/"             // Change to actual running bWAPP path
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/raesene/bwapp.git'
            }
        }

        stage('Run ZAP Scan via Docker') {
            steps {
                script {
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                        sh '''
                        echo "[INFO] Pulling OWASP ZAP Docker image..."
                        docker pull ghcr.io/zaproxy/zaproxy:stable

                        echo "[INFO] Running OWASP ZAP baseline scan..."
                        docker run --rm --user root --network host \
                            -v $WORKSPACE:/zap/wrk \
                            ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
                            -t ${BWAPP_URL} -x zap_report.xml
                        '''
                    }
                }
            }
        }

        stage('Upload to DefectDojo') {
            steps {
                script {
                    // Upload ZAP XML to DefectDojo
                    sh '''
                    echo "[INFO] Uploading ZAP results to DefectDojo..."
                    curl -k -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" \
                        -H "Authorization: Token ${DEFECTDOJO_API_KEY}" \
                        -F "minimum_severity=Low" \
                        -F "scan_type=ZAP Scan" \
                        -F "file=@zap_report.xml" \
                        -F "engagement=1" \
                        -F "product_id=${DEFECTDOJO_PRODUCT_ID}" \
                        -F "active=true" \
                        -F "verified=false"
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up Docker..."
            sh 'docker system prune -f || true'
        }
    }
}
