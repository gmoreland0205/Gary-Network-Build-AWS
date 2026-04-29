#!/bin/bash
# Update system packages
sudo apt-get update -y

# Install Java (required for Jenkins)
sudo apt-get install -y openjdk-21-jre

# Add Jenkins GPG key (LTS release)
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

# Add Jenkins repository
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package list and install Jenkins
sudo apt-get update -y
sudo apt-get install -y jenkins

# Enable and start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins