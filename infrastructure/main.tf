locals {
  region = "us-east-2"
}

provider "aws" {
  region = local.region
}

module "blog" {
  source             = "app.terraform.io/mr8ball/blog/aws"
  cf_certificate_arn = var.acm_certificate_arn
  domain_name        = var.domain_name
}

