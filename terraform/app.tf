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

resource "kubernetes_config_map" "app_grafana_dashboard" {
  metadata {
    name      = "app-grafana-dashboard"
    namespace = var.app_configurations.namespace
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "app-grafana-dashboard.json" = <<EOF
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "id": null,
  "iteration": 1625669782842,
  "panels": [
    {
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {},
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 1,
      "options": {
        "legend": {
          "displayMode": "list",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single"
        }
      },
      "targets": [
        {
          "expr": "sum(rate(flask_app_requests_total[5m])) by (method, endpoint, http_status)",
          "format": "time_series",
          "intervalFactor": 2,
          "legendFormat": "{{ method }} - {{ endpoint }} ({{ http_status }})",
          "refId": "A"
        }
      ],
      "title": "Request Rate",
      "type": "timeseries"
    },
    {
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {},
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 24,
        "x": 0,
        "y": 8
      },
      "id": 2,
      "options": {
        "legend": {
          "displayMode": "list",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single"
        }
      },
      "targets": [
        {
          "expr": "histogram_quantile(0.95, sum(rate(flask_app_request_duration_seconds_bucket[5m])) by (le, method, endpoint))",
          "format": "time_series",
          "intervalFactor": 2,
          "legendFormat": "{{ method }} - {{ endpoint }}",
          "refId": "A"
        }
      ],
      "title": "95th Percentile Latency",
      "type": "timeseries"
    }
  ],
  "schemaVersion": 30,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "App Dashboard",
  "uid": null,
  "version": 1
}
EOF
  }
}
