output "bucket_name" {

    value = aws_s3_bucket.state_bucket.bucket
  
}

output "dynamodb_name" {

    value = aws_dynamodb_table.lock_table.name
  
}