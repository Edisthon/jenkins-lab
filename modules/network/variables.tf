variable "aws_region" {
  description = "The AWS region to deploy into"
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the custom VPC"
  default     = "10.0.0.0/16"
}

variable "app_subnet_cidr" {
  description = "CIDR block for the Application Subnet"
  default     = "10.0.1.0/24"
}

variable "mgmt_subnet_cidr" {
  description = "CIDR block for the Management Subnet"
  default     = "10.0.2.0/24"
}