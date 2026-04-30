#!/bin/bash
# Update system packages
yum update -y

# Install dependencies
yum install -y yum-utils unzip wget git

# Install Java (required for Jenkins)
amazon-linux-extras install java-openjdk11 -y

# -------------------------
# Install Jenkins
# -------------------------
wget -O /etc/yum.repos.d/jenkins.repo \
 https://pkg.jenkins.io/redhat-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum install jenkins -y

systemctl enable jenkins
systemctl start jenkins

# -------------------------
# Install Terraform
# -------------------------
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

yum install -y terraform

# Verify install
terraform -version