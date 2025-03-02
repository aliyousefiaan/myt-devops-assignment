# myt-devops-assignment

## Quick Start

### Pre-requirements
- AWS access & secret key (name: myt-devops-assignment-terraform | Minimum AWS permissions necessary for a Terraform run)
- Private bucket to store terraform state (name: myt-devops-assignment-iac-terraform-state)

### Requirements packages
- terraform
- awscli
- kubectl
- helm

### Set the AWS credential
```bash
export AWS_ACCESS_KEY_ID="<YOUR_AWS_ACCESS_KEY_ID>"
export AWS_SECRET_ACCESS_KEY="<YOUR_AWS_SECRET_ACCESS_KEY>"
```

### Use Terraform to build infrastructure on AWS
```bash
cd terraform
terraform init
terraform workspace new dev / terraform workspace select dev
terraform apply --var-file=dev.tfvars
```
