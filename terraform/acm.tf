module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  domain_name = var.public_domain
  zone_id     = data.aws_route53_zone.public_domain.zone_id

  subject_alternative_names = ["*.${var.public_domain}"]

  validation_method = "DNS"

  tags = local.tags
}
