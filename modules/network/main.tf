# Get Public IP of whoever is running Terraform
data "http" "public_ip" {
  url = "https://api.ipify.org"
}

# 1. Custom VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Project6-VPC"
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Project6-IGW"
  }
}

# 3. Route Table (Public)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Project6-Public-RT"
  }
}

# 4. Subnets
resource "aws_subnet" "app_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.app_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "App-Subnet"
  }
}

resource "aws_subnet" "mgmt_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.mgmt_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "Management-Subnet"
  }
}

# 5. Route Table Associations
resource "aws_route_table_association" "app_rta" {
  subnet_id      = aws_subnet.app_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "mgmt_rta" {
  subnet_id      = aws_subnet.mgmt_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ==========================================
# SECURITY GROUPS
# ==========================================

# Jenkins Security Group
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins Server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.public_ip.response_body}/32"]
  }

  ingress {
    description = "Jenkins UI and Webhooks"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Security Group
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Security group for the Flask App Server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP to Flask App"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.public_ip.response_body}/32"]
  }

  ingress {
    description     = "SSH from Jenkins Server"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_sg.id]
  }

  ingress {
    description = "Node Exporter for Monitoring"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    # To be extremely secure, this should only be accessed by the Monitoring SG, but we haven't created it yet in the file order.
    # We will use VPC CIDR to allow internal VPC scraping.
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Monitoring Security Group
resource "aws_security_group" "monitoring_sg" {
  name        = "monitoring-sg"
  description = "Security group for Prometheus and Grafana"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Prometheus UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana UI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jaeger UI"
    from_port   = 16686
    to_port     = 16686
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "OTLP gRPC"
    from_port   = 4317
    to_port     = 4317
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "OTLP HTTP"
    from_port   = 4318
    to_port     = 4318
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.public_ip.response_body}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Logging Security Group
resource "aws_security_group" "logging_sg" {
  name        = "logging-sg"
  description = "Security group for Elasticsearch and Kibana"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Elasticsearch"
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kibana UI"
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.public_ip.response_body}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}