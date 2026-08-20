data "aws_vpc" "default" {

    default = true
  
}
resource "aws_security_group" "jenkins_sg" {
  
  vpc_id = data.aws_vpc.default.id
  name = var.sg_name
  region = var.aws_region
}


resource "aws_vpc_security_group_ingress_rule" "name" {
    security_group_id = aws_security_group.jenkins_sg.id
    to_port = 22
    from_port = 22
    ip_protocol = "tcp"
    cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "jenkins_web" {
    security_group_id = aws_security_group.jenkins_sg.id
    to_port = 8080
    from_port = 8080
    ip_protocol = "tcp"
    cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "app_web" {
    security_group_id = aws_security_group.jenkins_sg.id
    to_port = 80
    from_port = 80
    ip_protocol = "tcp"
    cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "name" {

    security_group_id = aws_security_group.jenkins_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
  
}

data "http" "public_ip" {

    url = "https://api.ipify.org"
  
}