provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform-bucket" {
  bucket = "ganapatibappamoriya-bucket"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "versioning-resource" {
  bucket = aws_s3_bucket.terraform-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "server-configuration" {
    bucket = aws_s3_bucket.terraform-bucket.id
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
}

resource "aws_s3_bucket_public_access_block" "block-public-access" {
  bucket = aws_s3_bucket.terraform-bucket.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "dynamodb-table" {
  name = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

terraform {
  backend "s3" {
  
    # lock
    dynamodb_table = "terraform-lock"
    
  }
}

output "s3_bucket_name" {
  value = aws_s3_bucket.terraform-bucket.bucket
  description = "Name of the s3 bucket"
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.dynamodb-table.name
  description = "Name of the DynamoDB Table"
}