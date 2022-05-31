provider "cloudflare" {}

terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

# variable "domain" {
#   default = var.site_domain
# }

# variable "zone_id" {
#   default = data.cloudflare_zones.domain.zones[0].id
# }

# resource "cloudflare_access_application" "cf_app" {
#   zone_id          = var.zone_id
#   name             = "My Example App"
#   domain           = var.domain
#   session_duration = "24h"
# }

resource "cloudflare_access_application" "cf_app" {
  zone_id          = data.cloudflare_zones.domain.zones[0].id
  name             = "My Example App"
  domain           = var.site_domain
  session_duration = "24h"
}

data "cloudflare_zones" "domain" {
  filter {
    name = var.site_domain
  }
}

# resource "cloudflare_record" "site_cname" {
#   zone_id = data.cloudflare_zones.domain.zones[0].id
#   name    = var.site_domain
#   value   = aws_s3_bucket.site.website_endpoint
#   type    = "CNAME"

#   ttl     = 1
#   proxied = true
# }

resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "www"
  value   = var.site_domain
  type    = "CNAME"

  ttl     = 1
  proxied = true
}

