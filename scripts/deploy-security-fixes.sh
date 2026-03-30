#!/bin/bash

# AWS Security Remediation Deployment Script
# This script applies the security fixes identified in the CVE scan

set -e

echo "🔒 AWS Security Remediation Deployment"
echo "======================================"

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform not installed. Aborting." >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI not installed. Aborting." >&2; exit 1; }

# Validate AWS credentials
echo "🔑 Checking AWS credentials..."
aws sts get-caller-identity > /dev/null || { echo "❌ AWS credentials not configured. Aborting." >&2; exit 1; }
echo "✅ AWS credentials validated"

# Initialize Terraform
echo "🏗️  Initializing Terraform..."
terraform init

# Validate Terraform configuration
echo "🔍 Validating Terraform configuration..."
terraform validate
if [ $? -eq 0 ]; then
    echo "✅ Terraform configuration is valid"
else
    echo "❌ Terraform configuration validation failed"
    exit 1
fi

# Plan the deployment
echo "📋 Creating deployment plan..."
terraform plan -out=security-remediation.tfplan
echo "✅ Deployment plan created"

# Prompt for confirmation
echo ""
echo "⚠️  IMPORTANT: This deployment will:"
echo "   • Create KMS keys for encryption"
echo "   • Enable S3 bucket encryption and versioning"
echo "   • Configure DynamoDB encryption and PITR"
echo "   • Secure SQS queues with encryption"
echo "   • Set up CloudTrail for auditing"
echo ""
read -p "Do you want to proceed with the deployment? (yes/no): " confirm

if [[ $confirm != "yes" ]]; then
    echo "❌ Deployment cancelled by user"
    exit 0
fi

# Apply the changes
echo "🚀 Applying security remediation..."
terraform apply security-remediation.tfplan

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Security remediation deployment completed successfully!"
    echo ""
    echo "📊 Summary of changes:"
    echo "   • Created encrypted KMS keys for all services"
    echo "   • Hardened 5 critical S3 buckets with encryption"
    echo "   • Secured 3 DynamoDB tables with encryption and PITR"
    echo "   • Protected 3 SQS queues with encryption and DLQ"
    echo "   • Enabled CloudTrail auditing"
    echo ""
    echo "🔍 Next steps:"
    echo "   1. Review CloudTrail logs for any security events"
    echo "   2. Update application code to handle encrypted resources"
    echo "   3. Test all services to ensure functionality"
    echo "   4. Schedule follow-up security scan in 30 days"
else
    echo "❌ Deployment failed. Please check the error messages above."
    exit 1
fi

# Clean up
rm -f security-remediation.tfplan
echo "🧹 Cleanup completed"