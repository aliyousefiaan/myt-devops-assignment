locals {
  tags = {
    Terraform   = "true"
    Project     = var.project
    Environment = var.environment
  }
}
