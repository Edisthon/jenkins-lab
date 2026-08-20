resource "random_id" "instance_suff" {

    byte_length = 4
  
}

data "aws_ami" "amazon_linux" {

    most_recent = true
    owners = [ "amazon" ]

    filter {
      name = "name"
      values = [ "al2023-ami-2023.*-x86_64" ]
    }
}


resource "aws_instance" "jenkins_instance" {

    instance_type = var.instance_type
    ami = data.aws_ami.amazon_linux.id
    associate_public_ip_address = true
    key_name = var.key_pair
    vpc_security_group_ids = [ var.sg_id ]
    tags = {
      name = var.ec2_name
    }


    lifecycle {
      create_before_destroy = true
    }
  
}