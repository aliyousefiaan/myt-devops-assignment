data "aws_route53_zone" "public_domain" {
  name = var.public_domain
}
