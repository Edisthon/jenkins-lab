variable "aws_region" {
    default = "eu-west-1"
}

variable "ec2_name" {
    default = "Jenkins-Instance"
}

variable "instance_type" {
    default = "t3.micro"
}

variable "key_pair" {
    default = "Jenkins_keypair"
}

variable "sg_id" {
    type = string
}

variable "subnet_id" {
    description = "The Subnet ID to deploy the EC2 instance into"
    type        = string
}

variable "iam_instance_profile" {
    description = "IAM instance profile to attach to the EC2 instance"
    type        = string
    default     = null
}

variable "ami_image" {

    default = "ami-00b98fcf187a433fa"
  
}
