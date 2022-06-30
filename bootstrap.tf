terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# provider "digitalocean" {
#   token = var.digitalocean_token
# }

provider "aws" {
  region = var.aws_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
  # account_id = var.cloudflare_account_id
}

locals {
    cloudflare_fqdn = format("%s.%s",var.cloudflare_cname_record,var.cloudflare_domain)
    cloudflare_ssh_fqdn = format("%s.%s",var.cloudflare_ssh_cname_record,var.cloudflare_domain)
    user_from_mail = split("@", var.user_email)[0]
}

# variable "digitalocean_token" {}
# variable "digitalocean_droplet_image" {}
# variable "digitalocean_droplet_region" {}
# variable "digitalocean_droplet_size" {}
# variable "digitalocean_key_name" {}
# variable "digitalocean_priv_key_path" {}
# variable "cloudflare_domain" {}
variable "cloudflare_account_id" {}
variable "cloudflare_tunnel_secret" {}
variable "cloudflare_cname_record" {}
variable "cloudflare_ssh_cname_record" {}
variable "cloudflare_api_token" {}
variable "cloudflare_analytics_api_token" {}
variable "user_email" {}

variable "aws_region" {
  type        = string
  description = "The AWS region to put the bucket into"
  default     = "us-east-1"
}

variable "cloudflare_domain" {
  type        = string
  default     = "example.com"
  description = "The domain name to use for the static site"
}
