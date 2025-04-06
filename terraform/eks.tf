# EKS - main
module "eks_main" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  cluster_name    = "main-${var.environment}"
  cluster_version = var.eks_main_configurations.cluster_version

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
        env = {
          NETWORK_POLICY_ENFORCING_MODE = "standard"
        }
      })
    }
    aws-ebs-csi-driver = {}
  }

  vpc_id                   = module.vpc_main.vpc_id
  subnet_ids               = module.vpc_main.private_subnets
  control_plane_subnet_ids = module.vpc_main.intra_subnets

  enable_irsa = true

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    general-workers = {
      labels = {
        nodegroup = "general-workers"
      }

      ami_type = "BOTTLEROCKET_x86_64"

      desired_size = var.eks_main_managed_node_group_general_settings.desired_size
      min_size     = var.eks_main_managed_node_group_general_settings.min_size
      max_size     = var.eks_main_managed_node_group_general_settings.max_size

      instance_types = var.eks_main_managed_node_group_general_settings.instance_types
      capacity_type  = var.eks_main_managed_node_group_general_settings.capacity_type

      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }

      node_security_group_additional_rules = {
        ingress_self_all = {
          description = "Node to node all ports/protocols"
          protocol    = "-1"
          from_port   = 0
          to_port     = 0
          type        = "ingress"
          self        = true
        }
      }
    }
  }

  tags = local.tags
}

data "aws_eks_cluster" "main" {
  name = module.eks_main.cluster_name
  depends_on = [
    module.eks_main.eks_managed_node_groups,
  ]
}

resource "null_resource" "eks_main_kube_config" {
  depends_on = [module.eks_main]
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks_main.cluster_name} --kubeconfig ~/.kube/${var.project}-eks-main-${var.environment} --region ${var.aws_region}"
  }
}

# EKS - main - aws-load-balancer-controller
module "irsa_eks_main_aws_load_balancer_controller" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.52.0"

  role_name = "eks-main-aws-load-balancer-controller-${var.environment}"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks_main.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}

resource "helm_release" "eks_main_aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = var.eks_main_configurations.alb_controller_version
  namespace        = "kube-system"
  create_namespace = false
  atomic           = true


  values = [
    yamlencode({
      clusterName = module.eks_main.cluster_name
      region      = var.aws_region
      vpcId       = module.vpc_main.vpc_id

      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = module.irsa_eks_main_aws_load_balancer_controller.iam_role_arn
        }
      }
    })
  ]

  depends_on = [
    module.eks_main, module.irsa_eks_main_aws_load_balancer_controller
  ]
}

# EKS - main - metrics-server
resource "helm_release" "eks_main_metrics_server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server"
  chart            = "metrics-server"
  version          = var.eks_main_configurations.metrics_server_version
  namespace        = "kube-system"
  create_namespace = false
  atomic           = true

  depends_on = [
    module.eks_main
  ]
}

# EKS - main - external-dns
module "irsa_eks_main_external_dns" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.52.0"

  role_name = "eks-main-external-dns-${var.environment}"

  attach_external_dns_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks_main.oidc_provider_arn
      namespace_service_accounts = ["external-dns:external-dns"]
    }
  }

  tags = local.tags
}

resource "helm_release" "eks_main_external-dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = var.eks_main_configurations.external_dns_version
  namespace        = "external-dns"
  create_namespace = true
  atomic           = true

  values = [
    yamlencode({
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = module.irsa_eks_main_external_dns.iam_role_arn
        }
      }
      aws = {
        region = var.aws_region
      }
    })
  ]

  depends_on = [
    module.eks_main, module.irsa_eks_main_external_dns
  ]
}

# EKS - main - external-secrets
module "irsa_eks_main_external_secrets" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.52.0"

  role_name = "eks-main-external-secrets-${var.environment}"

  attach_external_secrets_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks_main.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }

  tags = local.tags
}

resource "helm_release" "eks_main_external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.eks_main_configurations.external_secrets_version
  namespace        = "external-secrets"
  create_namespace = true
  atomic           = true

  values = [
    yamlencode({
      serviceAccount = {
        create = true
        annotations = {
          "eks.amazonaws.com/role-arn" = module.irsa_eks_main_external_secrets.iam_role_arn
        }
      }
    })
  ]

  depends_on = [
    module.eks_main,
    module.irsa_eks_main_external_secrets
  ]
}

resource "kubernetes_manifest" "cluster_secret_store" {
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "ClusterSecretStore"
    "metadata" = {
      "name" = "aws-secrets-manager"
    }
    "spec" = {
      "provider" = {
        "aws" = {
          "service" = "SecretsManager"
          "region"  = var.aws_region
          "auth" = {
            "jwt" = {
              "serviceAccountRef" = {
                "name"      = "external-secrets"
                "namespace" = "external-secrets"
              }
            }
          }
        }
      }
    }
  }
  depends_on = [
    helm_release.eks_main_external_secrets
  ]
}

# EKS - main - kube-prometheus
resource "helm_release" "kube_prometheus" {
  name             = "kube-prometheus"
  namespace        = "monitoring"
  chart            = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  version          = var.eks_main_configurations.kube_prometheus.version
  create_namespace = true
  atomic           = true

  values = [
    yamlencode({
      alertmanager = {
        enabled = false
      }
      kubeStateMetrics = {
        enabled = false
      }
      nodeExporter = {
        enabled = false
      }
      defaultRules = {
        create = false
      }
      kubernetesServiceMonitors = {
        enabled = false
      }
      grafana = {
        enabled                  = true
        defaultDashboardsEnabled = false
        persistence = {
          enabled          = true
          type             = "pvc"
          accessModes      = ["ReadWriteOnce"]
          size             = var.eks_main_configurations.kube_prometheus.grafana_storage_size
          storageClassName = "gp2"
        }
        resources = {
          requests = {
            cpu    = var.eks_main_configurations.kube_prometheus.grafana_resources.requests.cpu
            memory = var.eks_main_configurations.kube_prometheus.grafana_resources.requests.memory
          }
          limits = {
            cpu    = var.eks_main_configurations.kube_prometheus.grafana_resources.limits.cpu
            memory = var.eks_main_configurations.kube_prometheus.grafana_resources.limits.memory
          }
        }
      }
      prometheus = {
        enabled = true
        prometheusSpec = {
          resources = {
            requests = {
              cpu    = var.eks_main_configurations.kube_prometheus.prometheus_resources.requests.cpu
              memory = var.eks_main_configurations.kube_prometheus.prometheus_resources.requests.memory
            }
            limits = {
              cpu    = var.eks_main_configurations.kube_prometheus.prometheus_resources.limits.cpu
              memory = var.eks_main_configurations.kube_prometheus.prometheus_resources.limits.memory
            }
          }
          ruleSelectorNilUsesHelmValues           = false
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
          probeSelectorNilUsesHelmValues          = false
          retention                               = var.eks_main_configurations.kube_prometheus.prometheus_retention
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.eks_main_configurations.kube_prometheus.prometheus_storage_size
                  }
                }
                storageClassName = "gp2"
              }
            }
          }
        }
      }
    })
  ]
  depends_on = [
    module.eks_main
  ]
}
