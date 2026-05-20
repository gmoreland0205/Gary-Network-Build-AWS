output "jenkins_pri_ip" {
  value = aws_instance.jenkins.private_ip
  description = "Private IP address of the Jenkins Server"
}