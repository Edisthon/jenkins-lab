output "vpc_id" {
  value = aws_vpc.main.id
}

output "app_subnet_id" {
  value = aws_subnet.app_subnet.id
}

output "mgmt_subnet_id" {
  value = aws_subnet.mgmt_subnet.id
}

output "jenkins_sg_id" {
  value = aws_security_group.jenkins_sg.id
}

output "app_sg_id" {
  value = aws_security_group.app_sg.id
}

output "monitoring_sg_id" {
  value = aws_security_group.monitoring_sg.id
}