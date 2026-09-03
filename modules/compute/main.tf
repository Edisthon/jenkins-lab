resource "random_id" "instance_suff" {

    byte_length = 4
  
}


resource "aws_instance" "jenkins_instance" {

    instance_type               = var.instance_type
    ami                         = var.ami_image
    associate_public_ip_address = true
    key_name                    = var.key_pair
    subnet_id                   = var.subnet_id
    vpc_security_group_ids      = [ var.sg_id ]
    iam_instance_profile        = var.iam_instance_profile
    tags = {
      name = var.ec2_name
    }


    lifecycle {
      create_before_destroy = true
    }
  
}