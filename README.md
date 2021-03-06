# terraform-cloudflare-access-github

Configure a domain and identity provider such as GitHub and attach it to a policy - building Access with Terraform.

# 🚀 Javascript full-stack 🚀

https://github.com/coding-to-music/terraform-cloudflare-access-github

From https://developers.cloudflare.com/cloudflare-one/api-terraform/access-with-terraform/

https://github.com/cloudflare/cloudflare-docs/blob/production/content/cloudflare-one/api-terraform/access-with-terraform.md

## Environment Values

```java

```

## Errors and messages

```java
tf apply -auto-approve
```

```java
tf apply -auto-approve
data.cloudflare_zones.domain: Reading...
data.cloudflare_zones.domain: Read complete after 1s [id=010561c6841c1d1ab17e671680567a3f]
aws_s3_bucket.www: Refreshing state... [id=www.mydomain.com]
aws_s3_bucket.site: Refreshing state... [id=mydomain.com]
aws_s3_bucket_acl.www: Refreshing state... [id=www.mydomain.com,private]
cloudflare_record.site_cname: Refreshing state... [id=28bf5e5065954870ddca105fb5fc0eb2]
aws_s3_bucket_website_configuration.site: Refreshing state... [id=mydomain.com]
aws_s3_bucket_website_configuration.www: Refreshing state... [id=mydomain.com]
aws_s3_bucket_policy.site: Refreshing state... [id=mydomain.com]
aws_s3_bucket_acl.site: Refreshing state... [id=mydomain.com,public-read]

 Error: Record does not exist. (81044)

  with cloudflare_record.site_cname,
  on main.tf line 90, in resource "cloudflare_record" "site_cname":
  90: resource "cloudflare_record" "site_cname" {
```

## Clear out the missing resource from terraform state, it does not exist

```
terraform state rm 'cloudflare_record.site_cname'
```

Output:

```
Removed cloudflare_record.site_cname
Successfully removed 1 resource instance(s).
```

## Try it again

```
tf apply -auto-approve
```

Output:

```
╷
│ Error: failed to create page rule: Page Rule validation failed: See messages for details. (1004)
│
│   with cloudflare_page_rule.redirect-to-learn,
│   on main.tf line 110, in resource "cloudflare_page_rule" "redirect-to-learn":
│  110: resource "cloudflare_page_rule" "redirect-to-learn" {
│
╵
╷
│ Error: failed to create page rule: Page Rule validation failed: See messages for details. (1004)
│
│   with cloudflare_page_rule.redirect-to-hashicorp,
│   on main.tf line 121, in resource "cloudflare_page_rule" "redirect-to-hashicorp":
│  121: resource "cloudflare_page_rule" "redirect-to-hashicorp" {
```

## GitHub

```java
git init
git add .
git remote remove origin
git commit -m "first commit"
git branch -M main
git remote add origin git@github.com:coding-to-music/terraform-cloudflare-access-github.git
git push -u origin main
```

# Terraform

| Requirements                                                                                                             |
| ------------------------------------------------------------------------------------------------------------------------ |
| [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) installed on your machine                |
| The [Cloudflare provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs) properly configured |

[Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) is a tool for building, changing, and versioning infrastructure, and provides components and documentation for building [Cloudflare resources](https://www.terraform.io/docs/providers/cloudflare/). Listed below are examples to help you get started with building Access with Terraform. For a more generalized guide on configuring Cloudflare and Terraform, visit our [Getting Started with Terraform and Cloudflare](https://blog.cloudflare.com/getting-started-with-terraform-and-cloudflare-part-1/) blog post.

## Create an application with Terraform

1.  Create an application.

    Here is an example configuration:

```tf
variable "domain" {
  default = "example.com"
}

variable "zone_id" {
  default = <CLOUDFLARE_ZONE_ID>
}

resource "cloudflare_access_application" "cf_app" {
  zone_id          = var.zone_id
  name             = "My Example App"
  domain           = var.domain
  session_duration = "24h"
}
```

2.  Next, we need to export our environment variables and secrets:

```bash
$ export CLOUDFLARE_EMAIL=<CLOUDFLARE_EMAIL>
$ export CLOUDFLARE_API_KEY=<CLOUDFLARE_API_KEY>
```

3.  Now we can run a `terraform plan` which will output any proposed changes. Make sure to review the plan carefully:

```txt
$ terraform plan

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # cloudflare_access_application.cf_app will be created
  + resource "cloudflare_access_application" "cf_app" {
      + aud              = (known after apply)
      + domain           = "example.com"
      + id               = (known after apply)
      + name             = "My Example App"
      + session_duration = "24h"
      + zone_id          = "1ce82492016e71df631bf4af9c02587f"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

4.  Apply these changes using the `apply` command, once they look accurate and you're comfortable moving forward:

```txt
$ terraform apply --auto-approve

cloudflare_access_application.cf_app: Creating...
cloudflare_access_application.cf_app: Creation complete after 2s [id=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

## Create a policy

After you've created an application, you can start creating policies and attaching them to applications:

```tf
resource "cloudflare_access_policy" "cf_policy" {
  application_id = cloudflare_access_application.cf_app.id
  zone_id        = var.zone_id
  name           = "Example Policy"
  precedence     = "1"
  decision       = "allow"

  include {
    email = ["test@example.com"]
  }
}
```

To do so:

1.  Run a `terraform plan`:

```txt
$ terraform plan

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

cloudflare_access_application.cf_app: Refreshing state... [id=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx]

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # cloudflare_access_policy.cf_policy will be created
  + resource "cloudflare_access_policy" "cf_policy" {
      + application_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      + decision       = "allow"
      + id             = (known after apply)
      + name           = "My Example Policy"
      + precedence     = 1
      + zone_id        = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

      + include {
          + email = [
              + "test@example.com",
            ]
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

2.  Next, apply these changes using the `apply` command, once they look accurate and you're comfortable moving forward:

```bash
$ terraform apply --auto-approve
```

### Configuring an identity provider

The example below shows how you can configure an identity provider and attach it to a policy:

```tf
resource "cloudflare_access_identity_provider" "github_oauth" {
  account_id = <CLOUDFLARE_ACCOUNT_ID>
  name       = "GitHub OAuth"
  type       = "github"
  config {
    client_id     = <GITHUB_CLIENT_ID>
    client_secret = <GITHUB_CLIENT_SECRET>
  }
}

resource "cloudflare_access_policy" "cf_policy" {
  application_id = cloudflare_access_application.cf_app.id
  zone_id        = var.zone_id
  name           = "My Example Policy"
  precedence     = "1"
  decision       = "allow"

  include {
    email = ["test@example.com"]
    github {
      name                 = "My GitHub Org"
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
    }
  }
}
```

These are the basics to get up and running with Access and Terraform. See our [API documentation](https://api.cloudflare.com/#access-organizations-properties) for other endpoints that can be managed via Terraform.
