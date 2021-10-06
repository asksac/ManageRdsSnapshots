# Scheduled Creation and Deletion of Amazon RDS Database Snapshots

## Overview 

This project provides a sample implementation of a Lambda function which when invoked will 
create a new RDS database manual snapshot, as well as delete any old manual snapshots. The 
rules and snapshot ages for creation and deletion is configurable and specified through 
Lambda Environment Variables. Using an EventBridge rule, the Lambda function is invoked 
automatically based on a schedule expression (similar to cron). All infrastructure setup
in this project is handled using Terraform configuration scripts. 

## Diagram

TBD

## Installation

Follow these steps to get up and running with a fully working environment: 

### 1. Prerequisite software tools and AWS account setup

Before you can start working with Terraform code provided here, you must have a few 
software tools installed on your local workstation or build server. These are:

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli) 

You will also need an AWS account ([signup here](https://aws.amazon.com/free/free-tier/) 
for a free tier account if you don't already have one). 

### 2. Clone this repo

Open a Terminal, and run the following command from a directory where you want to download 
the Github repo code: 

`git clone git@github.com:asksac/ManageRdsSnapshots.git`

> :information_source: There are several ways of cloning a Github.com repo. For more details, 
refer to [this page](https://docs.github.com/en/free-pro-team@latest/github/creating-cloning-and-archiving-repositories/cloning-a-repository)

### 3. Customize variable values 

The Terraform module in this project defines several input variables that must be set 
based on your environment before you can apply the Terraform configuration. You may 
set input values using a `module` configuration block from your own Terraform project. 
Or, you may run this project as a root module directly, and set input values in 
a file named `terraform.tfvars` in the project's root directory. An example 
`terraform.tfvars` might look like this: 

```
aws_profile                  = "default"
aws_region                   = "us-east-1"
app_name                     = "ManageRdsSnapshots"
app_shortcode                = "MRS"
aws_env                      = "dev"
lambda_name                  = "ManageRdsSnapshots"
db_instance_id               = "ora-rds01"
snapshot_max_age_in_days     = 30
min_days_since_last_snapshot = 2
schedule_expression          = "cron(0 8 * * ? *)" 
```

  > For your testing, make sure to change above values based on your environment setup. 

These input values affect the operation of deployed Lambda function: 

* `db_instance_id` (required) - specify RDS database instance id whose snapshot to manage
* `snapshot_max_age_in_days` (defaults to 0) - snapshots that are older than specified value
   in days will be deleted
* `snapshot_max_age_in_months` (defaults to 0) - an alternate way to set maximum snapshot 
  age in months (if both `snapshot_max_age_in_days` and `snapshot_max_age_in_months` are 
  specified then `snapshot_max_age_in_days` takes precedence)
* `min_days_since_last_snapshot` (defaults to 0) - lambda will maintain a gap of specified
  days since last manual snapshot (if 0, new snapshot will be created every run)
* `schedule_expression` - sets a cron expression to invoke lambda automatically on schedule 


### 4. Apply Terraform configuration

You're now ready for installation, which is to deploy the Terraform configuration. Run the 
following commands in a Terminal from the project root directory:

```shell
terraform init
terraform apply
```

Second command above will first run _plan_ phase of Terraform, and output a list of 
resources that Terraform will create. After verifying, enter `yes` to proceed with resource 
creation. This step may take a few minutes to complete.  

## License

[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](http://badges.mit-license.org)

- **[MIT license](http://opensource.org/licenses/mit-license.php)**
- Copyright 2021 &copy; Sachin Hamirwasia
