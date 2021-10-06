variable "aws_profile" {
  type                    = string
  default                 = "default"
  description             = "Specify an aws profile name to be used for access credentials (run `aws configure help` for more information on creating a new profile)"
}

variable "aws_region" {
  type                    = string
  default                 = "us-east-1"
  description             = "Specify the AWS region to be used for resource creations"
}

variable "aws_env" {
  type                    = string
  default                 = "dev"
  description             = "Specify a value for the Environment tag"
}

variable "app_name" {
  type                    = string
  default                 = "ManageRdsSnapshots"
  description             = "Specify an application, used primarily for tagging"
}

variable "app_shortcode" {
  type                    = string
  default                 = "MRS"
  description             = "Specify a short-code or pneumonic for this application, used primarily for resource name prefix"
}

variable "lambda_name" {
  type                    = string 
  default                 = "ManageRdsSnapshots"
  description             = "Specify a name to be used for Lambda function"
}

variable "db_instance_id" {
  type                    = string 
  description             = "Specify RDS database instance ID whose snapshots Lambda will manage"
}

variable "snapshot_max_age_in_days" {
  type                    = number
  default                 = 0
  description             = "Specify maximum age in days of snapshots to retain; any snapshots older than specified age will be deleted"
}

variable "snapshot_max_age_in_months" {
  type                    = number
  default                 = 0
  description             = "Specify maximum age in months of snapshots to retain; any snapshots older than specified age will be deleted"
}

variable "min_days_since_last_snapshot" {
  type                    = number
  default                 = 0
  description             = "Specify minimum gap in days to maintain since last snapshot"
}

variable "schedule_expression" {
  type                    = string
  default                 = "cron(0 9 1 1 ? *)" # schedules at 8am UTC on Jan 1st every year
  description             = "Specify a valid CloudWatch Event or EventBridge schedule expression"
}

