/**
 * # Terraform Module - ManageRdsSnapshots
 *
 * This Terraform module builds and deploys a Lambda function using Python source located at  
 * `src/lambda/ManageRdsSnapshots` directory, and creates an EventBridge rule to trigger
 * Lambda execution based on a schedule
 * 
 * ### Usage: 
 * 
 * ```hcl
 * module "ManageRdsSnapshots" {
 *   source                       = "./ManageRdsSnapshots"
 * 
 *   aws_profile                  = "default"
 *   aws_region                   = "us-east-1"
 *   app_name                     = "ManageRdsSnapshots"
 *   app_shortcode                = "MRS"
 *   aws_env                      = "dev"
 *   lambda_name                  = "ManageRdsSnapshots"
 *   db_instance_id               = "ora-rds01"
 *   snapshot_max_age_in_days     = 30
 *   min_days_since_last_snapshot = 2
 *   schedule_expression          = "cron(0 8 * * ? *)" # runs everyday at 8am UTC
 * }
 * ```
 *
 */

terraform {
  required_version        = ">= 0.12.24"
  required_providers {
    aws                   = ">= 3.11.0"
    archive               = "~> 2.0.0"
  }
}

provider "aws" {
  profile                 = var.aws_profile
  region                  = var.aws_region
}

data "aws_caller_identity" "this" {}

locals {
  account_id              = data.aws_caller_identity.this.account_id

  # Common tags to be assigned to all resources
  common_tags             = {
    Application           = var.app_name
    Environment           = var.aws_env
  }
}
