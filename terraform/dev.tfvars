project     = "myt-devops-assignment"
environment = "dev"

aws_region = "us-east-1"

vpc_main_cidr = "10.20.0.0/16"

public_domain = "myt-devops-assignment.myclnet.com"

eks_main_configurations = {
  cluster_version          = "1.31"
  alb_controller_version   = "1.11.0"
  external_dns_version     = "1.15.2"
  external_secrets_version = "0.14.3"
  metrics_server_version   = "3.12.2"
  kube_prometheus = {
    version                 = "69.6.0"
    grafana_storage_size    = "1Gi"
    prometheus_storage_size = "1Gi"
    grafana_resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "250m"
        memory = "256Mi"
      }
    }
    prometheus_resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
  }
}

eks_main_managed_node_group_general_settings = {
  desired_size   = 2
  min_size       = 1
  max_size       = 3
  instance_types = ["t3.small"]
  capacity_type  = "ON_DEMAND"
}

app_configurations = {
  namespace       = "app"
  replicaCount    = "2"
  cpu_requests    = "100m"
  memory_requests = "128Mi"
  cpu_limits      = "200m"
  memory_limits   = "256Mi"
  minReplicas     = "2"
  maxReplicas     = "5"
}
