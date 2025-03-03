resource "kubernetes_namespace" "app_ns" {
  metadata {
    name = var.app_configurations.namespace
  }
}

resource "kubernetes_manifest" "app_external_secret" {
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "app-secrets"
      "namespace" = var.app_configurations.namespace
    }
    "spec" = {
      "refreshInterval" = "24h"
      "secretStoreRef" = {
        "name" = "aws-secrets-manager"
        "kind" = "ClusterSecretStore"
      }
      "target" = {
        "name"           = "app-secrets"
        "creationPolicy" = "Owner"
      }
      "data" = [
        {
          "secretKey" = "db_password"
          "remoteRef" = {
            "key"      = "${var.environment}/app/secrets"
            "property" = "db_password"
          }
        },
        {
          "secretKey" = "secret_key"
          "remoteRef" = {
            "key"      = "${var.environment}/app/secrets"
            "property" = "secret_key"
          }
        }
      ]
    }
  }
}

resource "helm_release" "app_helm_release" {
  name             = "app"
  namespace        = var.app_configurations.namespace
  chart            = "../helm"
  create_namespace = false
  atomic           = true

  values = [templatefile("${path.module}/templates/app_helm_values.yaml.tpl", {
    env             = var.environment
    aws_region      = var.aws_region
    certificate-arn = module.acm.acm_certificate_arn
    public_domain   = var.public_domain
    replicaCount    = var.app_configurations.replicaCount
    cpu_requests    = var.app_configurations.cpu_requests
    memory_requests = var.app_configurations.memory_requests
    cpu_limits      = var.app_configurations.cpu_limits
    memory_limits   = var.app_configurations.memory_limits
    minReplicas     = var.app_configurations.minReplicas
    maxReplicas     = var.app_configurations.maxReplicas
    allowed_subnets = concat(module.vpc_main.public_subnets_cidr_blocks, module.vpc_main.private_subnets_cidr_blocks)
  })]
}
