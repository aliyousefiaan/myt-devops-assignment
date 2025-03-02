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
            "key"      = "${var.project}/${var.environment}/app/secrets"
            "property" = "db_password"
          }
        },
        {
          "secretKey" = "secret_key"
          "remoteRef" = {
            "key"      = "${var.project}/${var.environment}/app/secrets"
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
}
