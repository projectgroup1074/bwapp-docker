# jenkins/Dockerfile
FROM jenkins/jenkins:lts

USER root

# Install Docker CLI inside the Jenkins container
RUN apt-get update && apt-get install -y docker.io

# (Optional) Install docker-compose if needed
RUN curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose

USER jenkins
