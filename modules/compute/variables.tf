variable "aws_region" {

    default = "us-east-1"
  
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

