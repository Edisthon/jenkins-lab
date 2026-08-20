resource "random_id" "s3_prefix" {

    byte_length = 4
  
}


resource "aws_s3_bucket" "state_bucket" {

    bucket = "${var.s3_bucket}-${random_id.s3_prefix.hex}"
  
}


resource "aws_s3_bucket_versioning" "enabled" {

    bucket = aws_s3_bucket.state_bucket.id
    versioning_configuration {
      status = "Enabled"
    }
  
}


resource "aws_s3_bucket_public_access_block" "denied" {

    bucket = aws_s3_bucket.state_bucket.id

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true


  
}

resource "aws_s3_bucket_server_side_encryption_configuration" "name" {

    bucket = aws_s3_bucket.state_bucket.id
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  
}


resource "aws_dynamodb_table" "lock_table" {

    name = var.dynamodb_name
    hash_key = "LockID"
    billing_mode = "PAY_PER_REQUEST"

    attribute {
      name = "LockID"
      type = "S"
    }

    depends_on = [ aws_s3_bucket.state_bucket ]
}