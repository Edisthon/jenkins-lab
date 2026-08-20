terraform {
  backend "s3" {

    bucket = "state-bucket-02bce44b"
    dynamodb_table = "jenkins-Locktable"
    region = "us-east-1"
    key = "dev/terraform.tfstate"
    
  }


  required_providers {
    
    aws = {
       source = "hashicorp/aws"
       version = "~> 6.0"
    }
  }
}