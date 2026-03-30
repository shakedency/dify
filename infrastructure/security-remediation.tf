# AWS Security Remediation - Terraform Configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment   = var.environment
      Project      = var.project_name
      SecurityScan = "remediated"
      LastUpdated  = formatdate("YYYY-MM-DD", timestamp())
    }
  }
}
# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "aws-security-remediation"
}
variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7
}
# KMS Keys for encryption
resource "aws_kms_key" "s3_encryption" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true
  
  tags = {
    Name = "s3-encryption-key"
    Purpose = "S3 bucket encryption"
  }
}
resource "aws_kms_alias" "s3_encryption" {
  name          = "alias/s3-encryption"
  target_key_id = aws_kms_key.s3_encryption.key_id
}
resource "aws_kms_key" "dynamodb_encryption" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true
  
  tags = {
    Name = "dynamodb-encryption-key"
    Purpose = "DynamoDB encryption"
  }
}
resource "aws_kms_alias" "dynamodb_encryption" {
  name          = "alias/dynamodb-encryption"
  target_key_id = aws_kms_key.dynamodb_encryption.key_id
}
resource "aws_kms_key" "sqs_encryption" {
  description             = "KMS key for SQS encryption"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true
  
  tags = {
    Name = "sqs-encryption-key" 
    Purpose = "SQS queue encryption"
  }
}
resource "aws_kms_alias" "sqs_encryption" {
  name          = "alias/sqs-encryption"
  target_key_id = aws_kms_key.sqs_encryption.key_id
}
# S3 Bucket Security Hardening
resource "aws_s3_bucket" "secure_buckets" {
  for_each = toset([
    "logs-bucket",
    "assets-bucket", 
    "product-images",
    "order-attachments",
    "receipts"
  ])
  
  bucket = each.value
  
  tags = {
    Name = each.value
    Security = "hardened"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_buckets" {
  for_each = aws_s3_bucket.secure_buckets
  
  bucket = each.value.id
  
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_encryption.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}
resource "aws_s3_bucket_versioning" "secure_buckets" {
  for_each = aws_s3_bucket.secure_buckets
  
  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_public_access_block" "secure_buckets" {
  for_each = aws_s3_bucket.secure_buckets
  
  bucket = each.value.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_logging" "secure_buckets" {
  for_each = aws_s3_bucket.secure_buckets
  
  bucket = each.value.id
  
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "access-logs/${each.value.id}/"
}
resource "aws_s3_bucket" "access_logs" {
  bucket = "access-logs-${random_id.bucket_suffix.hex}"
}
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
# DynamoDB Security Hardening
resource "aws_dynamodb_table" "secure_tables" {
  for_each = {
    users = {
      hash_key = "user_id"
      attributes = [
        {
          name = "user_id"
          type = "S"
        }
      ]
    }
    orders = {
      hash_key = "order_id"
      attributes = [
        {
          name = "order_id"
          type = "S"
        }
      ]
    }
    customers = {
      hash_key = "customer_id" 
      attributes = [
        {
          name = "customer_id"
          type = "S"
        }
      ]
    }
  }
  
  name           = each.key
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = each.value.hash_key
  
  dynamic "attribute" {
    for_each = each.value.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }
  
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_encryption.arn
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  tags = {
    Name = each.key
    Security = "hardened"
    DataClassification = "sensitive"
  }
}
# SQS Security Hardening
resource "aws_sqs_queue" "secure_queues" {
  for_each = toset([
    "payment-queue",
    "user-service-queue", 
    "billing-queue"
  ])
  
  name                       = each.value
  kms_master_key_id         = aws_kms_key.sqs_encryption.id
  kms_data_key_reuse_period_seconds = 300
  
  # Reduce message retention for sensitive data
  message_retention_seconds = 86400  # 1 day instead of default 14 days
  
  tags = {
    Name = each.value
    Security = "hardened"
    DataClassification = "sensitive"
  }
}
resource "aws_sqs_queue" "dlq" {
  for_each = aws_sqs_queue.secure_queues
  
  name                       = "${each.value.name}-dlq"
  kms_master_key_id         = aws_kms_key.sqs_encryption.id
  kms_data_key_reuse_period_seconds = 300
  message_retention_seconds  = 1209600  # 14 days for DLQ
  
  tags = {
    Name = "${each.value.name}-dlq"
    Security = "hardened"
    Purpose = "dead-letter-queue"
  }
}
resource "aws_sqs_queue_redrive_policy" "secure_queues" {
  for_each = aws_sqs_queue.secure_queues
  
  queue_url = each.value.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = 3
  })
}
# SNS Security Hardening  
resource "aws_sns_topic" "secure_topics" {
  for_each = toset([
    "payment-events",
    "order-events",
    "notifications"
  ])
  
  name              = each.value
  kms_master_key_id = "alias/aws/sns"
  
  tags = {
    Name = each.value
    Security = "hardened"
  }
}
# CloudTrail for auditing
resource "aws_cloudtrail" "security_audit" {
  name           = "security-audit-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.bucket
  
  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    
    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.secure_buckets["logs-bucket"].arn}/*"]
    }
    
    data_resource {
      type   = "AWS::DynamoDB::Table"
      values = [for table in aws_dynamodb_table.secure_tables : "${table.arn}/*"]
    }
  }
  
  tags = {
    Name = "security-audit-trail"
    Purpose = "security-auditing"
  }
}
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "cloudtrail-logs-${random_id.bucket_suffix.hex}"
  force_destroy = true
  
  tags = {
    Name = "cloudtrail-logs"
    Purpose = "audit-logging"
  }
}
# IAM Role for enhanced security
resource "aws_iam_role" "security_audit_role" {
  name = "security-audit-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "security-audit-role"
    Purpose = "security-operations"
  }
}
resource "aws_iam_role_policy" "security_audit_policy" {
  name = "security-audit-policy"
  role = aws_iam_role.security_audit_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "dynamodb:DescribeTable", 
          "sqs:GetQueueAttributes",
          "sns:GetTopicAttributes",
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      }
    ]
  })
}
# Output important values
output "kms_key_ids" {
  description = "KMS key IDs for encryption"
  value = {
    s3_key       = aws_kms_key.s3_encryption.id
    dynamodb_key = aws_kms_key.dynamodb_encryption.id
    sqs_key      = aws_kms_key.sqs_encryption.id
  }
}
output "secure_bucket_names" {
  description = "Names of hardened S3 buckets"
  value       = keys(aws_s3_bucket.secure_buckets)
}
output "secure_table_names" {
  description = "Names of hardened DynamoDB tables"
  value       = keys(aws_dynamodb_table.secure_tables)
}
output "secure_queue_names" {
  description = "Names of hardened SQS queues"
  value       = keys(aws_sqs_queue.secure_queues)
}