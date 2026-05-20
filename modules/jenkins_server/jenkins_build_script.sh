#!/bin/bash
set -eux

# Log everything to user-data log
exec > /var/log/user-data.log 2>&1

echo "Setup started at $(date)"

# -------------------------
# System update + tools
# -------------------------
dnf update -y

# -------------------------
# Java (required for Jenkins)
# -------------------------
echo "Installing Java 21 at $(date)"
dnf install -y java-21-amazon-corretto

java -version

# -------------------------
# Jenkins installation
# -------------------------
echo "Installing Jenkins at $(date)"

wget -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/redhat-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

dnf install -y jenkins

systemctl enable jenkins
systemctl start jenkins

# -------------------------
# Terraform installation
# -------------------------
echo "Installing Terraform at $(date)"

dnf install -y dnf-plugins-core

dnf config-manager --add-repo \
  https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

dnf install -y terraform

terraform -version

echo "Setup completed at $(date)"