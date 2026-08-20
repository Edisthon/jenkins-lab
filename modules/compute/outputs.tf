output "ec2_instance_name" {

    value = aws_instance.jenkins_instance.tags

  
}

output "ec2_instance_ip" {

    value = aws_instance.jenkins_instance.public_ip
  
}

