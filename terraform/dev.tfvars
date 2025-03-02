project     = "myt-devops-assignment"
environment = "dev"

aws_region = "us-east-1"

vpc_main_cidr = "10.20.0.0/16"

public_domain = "myt-devops-assignment.myclnet.com"

eks_main_configurations = {
  cluster_version        = "1.31"
  alb_controller_version = "1.11.0"
  external_dns_version   = "1.15.2"
}

eks_main_managed_node_group_general_settings = {
  desired_size   = 2
  min_size       = 1
  max_size       = 3
  instance_types = ["t3.small"]
  capacity_type  = "ON_DEMAND"
}
