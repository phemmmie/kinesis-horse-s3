terraform {
  required_version = ">=0.12.0"
}

provider "aws" {
  region = "us-west-2"
  assume_role {
#    role_arn = "arn:aws:iam::${var.account_id}:role/CicdRole"
  }
}


# Terraform Backend




data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


#
# Kinesis
#
resource "aws_kinesis_stream" "eu-source-stream" {
  name = "data-ingest-source-${var.app_name}"
  shard_count = 4
  retention_period = 8760
}

# Firehorse
#
resource "aws_kinesis_firehose_delivery_stream" "eu-mapped_horse" {
  name = "data-ingest-mapped-${var.app_name}"
  destination = "s3"
  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.eu-source-stream.arn
    role_arn = aws_iam_role.firehose_service.arn
  }

  s3_configuration {
    role_arn = aws_iam_role.firehose_service.arn
    bucket_arn = aws_s3_bucket.eu-mapped_bucket.arn
  }

 # depends_on = [ aws_iam_role_policy_attachment.firehose_from_kinesis ]
}



#
# S3 buckets
#
resource "aws_s3_bucket" "eu-mapped_bucket" {
  bucket = "data-ingest-eul${var.app_name}"
  acl    = "private"
  force_destroy = true
}