output "jenkins_server_ip" {
    value       = module.jenkins_server.ec2_instance_ip
    description = "Public IP of the Jenkins Controller Server"
}

output "prod_server_ip" {
    value       = module.prod_server.ec2_instance_ip
    description = "Public IP of the Production App Server"
}

output "prod_server_private_ip" {
    value       = module.prod_server.ec2_instance_private_ip
    description = "Private IP of the Production App Server (Use this in Jenkins!)"
}

output "monitoring_server_ip" {
    value       = module.monitoring_server.ec2_instance_ip
    description = "Public IP of the Monitoring Server (Prometheus/Grafana)"
}