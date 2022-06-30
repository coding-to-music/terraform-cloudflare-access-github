# terraform {
#     required_providers {
#         cloudflare = {
#             source = "cloudflare/cloudflare"
#         }
#         # github = {
#         #     source  = "integrations/github"
#         #   version = "~> 4.0"
#         # }
#     }
# }


# provider "cloudflare" {
# # api_token  = var.cloudflare_api_token  ## Commented out as we are using an environment var
# }

# provider "aws" {
#   region = var.aws_region
# }

# provider "cloudflare" {}

resource "aws_s3_bucket" "site" {
  bucket = var.cloudflare_domain
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_acl" "site" {
  bucket = aws_s3_bucket.site.id

  acl = "public-read"
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.site.arn,
          "${aws_s3_bucket.site.arn}/*",
        ]
      },
    ]
  })
}

resource "aws_s3_bucket" "www" {
  bucket = "www.${var.cloudflare_domain}"
}

resource "aws_s3_bucket_acl" "www" {
  bucket = aws_s3_bucket.www.id

  acl = "private"
}

resource "aws_s3_bucket_website_configuration" "www" {
  bucket = aws_s3_bucket.site.id

  redirect_all_requests_to {
    host_name = var.cloudflare_domain
  }
}

data "cloudflare_zones" "domain" {
  filter {
    name = var.cloudflare_domain
  }
}

resource "cloudflare_record" "site_cname" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = var.cloudflare_domain
  value   = aws_s3_bucket.site.website_endpoint
  type    = "CNAME"

  ttl     = 1
  proxied = true
}

resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "www"
  value   = var.cloudflare_domain
  type    = "CNAME"

  ttl     = 1
  proxied = true
}

resource "cloudflare_access_application" "cf_app" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name             = "Another Example App"
  domain           = var.cloudflare_domain
  session_duration = "24h"
}

resource "cloudflare_access_identity_provider" "github_oauth" {
  # account_id = <CLOUDFLARE_ACCOUNT_ID>
  name       = "GitHub OAuth"
  type       = "github"
  config {
    client_id     = var.github_client_id
    client_secret = var.github_client_secret
  }
}

resource "cloudflare_access_policy" "cf_policy" {
  application_id = cloudflare_access_application.cf_app.id
  zone_id        = data.cloudflare_zones.domain.zones[0].id
  name           = "Another Example Policy"
  precedence     = "1"
  decision       = "allow"

  include {
    email = [
      "test@example.com", 
      var.user_email
    ]
  }
}

data "cloudflare_zones" "configured_zone" {
  filter {
    name   = var.cloudflare_domain
    status = "active"
  }
}

resource "cloudflare_argo_tunnel" "prometheus_analytics" {
  account_id = var.cloudflare_account_id
  name       = "prometheus_analytics"
  secret     = base64encode(var.cloudflare_tunnel_secret)
}

resource "cloudflare_record" "prometheus_app" {
  zone_id = lookup(data.cloudflare_zones.configured_zone.zones[0], "id")
  name    = var.cloudflare_cname_record
  value   = "${cloudflare_argo_tunnel.prometheus_analytics.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "ssh_app" {
  zone_id = lookup(data.cloudflare_zones.configured_zone.zones[0], "id")
  name    = var.cloudflare_ssh_cname_record
  value   = "${cloudflare_argo_tunnel.prometheus_analytics.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_access_application" "prometheus_analytics" {
  zone_id          = lookup(data.cloudflare_zones.configured_zone.zones[0], "id")
  name             = format("%s - Grafana",local.cloudflare_fqdn)
  type             = "self_hosted"
  domain           = local.cloudflare_fqdn
  session_duration = "30m"
}

resource "cloudflare_access_application" "ssh_browser" {
  zone_id          = lookup(data.cloudflare_zones.configured_zone.zones[0], "id")
  name             = format("%s - SSH browser",local.cloudflare_ssh_fqdn)
  type             = "ssh"
  domain           = local.cloudflare_ssh_fqdn
  session_duration = "30m"
}

resource "cloudflare_access_policy" "prometheus_analytics_policy" {
  application_id = cloudflare_access_application.prometheus_analytics.id
  zone_id        = lookup(data.cloudflare_zones.configured_zone.zones[0], "id")
  name           = "Allow Configured Users"
  precedence     = "1"
  decision       = "allow"

  include {
    email = [var.user_email]
  }
}

resource "cloudflare_access_policy" "ssh_policy" {
  application_id = cloudflare_access_application.ssh_browser.id
  zone_id        = lookup(data.cloudflare_zones.configured_zone.zones[0], "id")
  name           = "Allow Configured Users"
  precedence     = "1"
  decision       = "allow"

  include {
    email = [var.user_email]
  }
}


resource "cloudflare_access_ca_certificate" "ssh_short_lived" {
  account_id     = var.cloudflare_account_id
  application_id = cloudflare_access_application.ssh_browser.id
}


# resource "cloudflare_page_rule" "redirect-to-learn" {
#   zone_id = data.cloudflare_zones.domain.zones[0].id
#   target  = "${var.cloudflare_domain}/learn"
#   actions {
#     forwarding_url {
#       status_code = 302
#       url         = "https://learn.hashicorp.com/terraform"
#     }
#   }
# }

# resource "cloudflare_page_rule" "redirect-to-hashicorp" {
#   zone_id = data.cloudflare_zones.domain.zones[0].id
#   target  = "${var.cloudflare_domain}/hello"
#   actions {
#     forwarding_url {
#       status_code = 302
#       url         = "https://hashicorp.com"
#     }
#   }
# }

