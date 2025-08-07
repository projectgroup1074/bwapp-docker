pipeline {
agent any

environment {
NIKTO_TARGET = "http://192.168.28.141:8080"
ZAP_TARGET = "http://192.168.28.141:9090/portal.php"
}

stages {

stage('Check Node.js Installation') {
steps {
sh "command -v node"
sh "node -v"
}
}

stage('Checkout Code') {
steps {
git branch: 'main', url: 'https://github.com/projectgroup1074/bwapp-docker.git'
}
}

stage('Secret Scan (Trufflehog3)') {
steps {
sh "trufflehog3 . -f json -o trufflehog_report.json || true"
archiveArtifacts artifacts: 'trufflehog_report.json', allowEmptyArchive: true
}
}



stage('Install Sonar Scanner') {
steps {
script {
echo "Installing Sonar Scanner..."
sh """
if [ ! -f sonar-scanner/bin/sonar-scanner ]; then
curl -sSL -o sonar.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
unzip -q sonar.zip
mv sonar-scanner-5.0.1.3006-linux sonar-scanner
rm sonar.zip
fi
"""
}
}
}

stage('SonarQube Analysis') {
steps {
script {
def sonarUsed = false
try {
withCredentials([string(credentialsId: 'sonartoken', variable: 'SONARQUBE_TOKEN')]) {
if (env.SONARQUBE_TOKEN?.trim()) {
sonarUsed = true
echo "Running SonarQube analysis..."
sh """
./sonar-scanner/bin/sonar-scanner \
-Dsonar.projectKey=bwapp-docker \
-Dsonar.projectVersion=${buildVersion} \
-Dsonar.sources=. \
-Dsonar.host.url=http://192.168.28.141:9000 \
-Dsonar.token=$SONARQUBE_TOKEN \
-Dsonar.nodejs.executable=${nodePath} \
-Dsonar.qualitygate.wait=false || true
"""
}
}
} catch (ignore) {
echo "No SonarQube token found, skipping analysis."
}
}
}
}
stage('Build Docker Image') {
steps {
sh 'docker build -t bwapp-docker . || true'
}
}
stage('Nikto Scan') {
steps {
sh '''
docker run --rm --network host \
-v "$WORKSPACE:/nikto-output" \
frapsoft/nikto \
-h "$NIKTO_TARGET" \
-o /nikto-output/nikto_report.html \
-Format htm || true
'''
archiveArtifacts artifacts: 'nikto_report.html', onlyIfSuccessful: false
}
}

stage('OWASP ZAP Scan') {
steps {
sh '''
echo 'Checking if target is up...'
for i in {1..10}; do
if curl -s --head "$ZAP_TARGET" | grep '200 OK'; then
echo 'Target is UP'
break
fi
echo 'Waiting for target to start...'
sleep 5
done

mkdir -p "$WORKSPACE/zap_output"
chmod 777 "$WORKSPACE/zap_output"

docker run --rm --network host \
-v "$WORKSPACE/zap_output:/zap/wrk" \
ghcr.io/zaproxy/zaproxy:stable \
zap-baseline.py \
-t "$ZAP_TARGET" \
-r zap_report.html || true

if [ -f "$WORKSPACE/zap_output/zap_report.html" ]; then
mv "$WORKSPACE/zap_output/zap_report.html" "$WORKSPACE/zap_report.html"
else
echo "<html><body><h2>ZAP Scan Failed or Target Unreachable</h2></body></html>" > "$WORKSPACE/zap_report.html"
fi
'''
archiveArtifacts artifacts: 'zap_report.html', onlyIfSuccessful: false
}
}

stage('Generate Security Dashboard') {
steps {
sh '''
mkdir -p "$WORKSPACE/security_dashboard"
build_date=$(date)

echo "<html><head><title>Security Dashboard</title></head><body>" > "$WORKSPACE/security_dashboard/index.html"
echo "<h1>Security Dashboard</h1>" >> "$WORKSPACE/security_dashboard/index.html"
echo "<p>Generated on: $build_date</p>" >> "$WORKSPACE/security_dashboard/index.html"
echo "<h2>Trufflehog Report</h2><a href='../trufflehog_report.json'>View JSON</a><br>" >> "$WORKSPACE/security_dashboard/index.html"
echo "<h2>Nikto Report</h2><a href='../nikto_report.html'>View HTML</a><br>" >> "$WORKSPACE/security_dashboard/index.html"
echo "<h2>OWASP ZAP Report</h2><a href='../zap_report.html'>View HTML</a><br>" >> "$WORKSPACE/security_dashboard/index.html"
echo "<h2>SonarQube Report</h2><a href='http://192.168.28.141:9000/dashboard?id=bwapp-docker' target='_blank'>View on SonarQube</a><br>" >> "$WORKSPACE/security_dashboard/index.html"
echo "</body></html>" >> "$WORKSPACE/security_dashboard/index.html"
'''
archiveArtifacts artifacts: 'security_dashboard/**', onlyIfSuccessful: false
}
}
}

post {
always {
echo "Pipeline finished."
}
failure {
echo "Pipeline failed. Please check logs."
}
}
}
