# IMPORTANT: this resource ADOPTS an already-registered domain into Terraform
# management — it does not perform the initial registration. Route 53 Domains
# has no "buy a brand new domain" Terraform resource, since registration is a
# one-time, non-idempotent, real-money transaction with ICANN email
# verification attached. Register the domain first — see
# scripts/register-domain.sh — THEN run `terraform apply` to bring it under
# management here.
#
# `terraform destroy` on this resource does NOT delete the domain
# registration itself, only removes it from Terraform's state.
locals {
  contact_type = var.domain_contact.organization_name != "" ? "COMPANY" : "PERSON"
}

resource "aws_route53domains_registered_domain" "main" {
  domain_name = var.domain_name

  auto_renew    = true
  transfer_lock = true

  registrant_privacy = true
  admin_privacy      = true
  tech_privacy        = true

  registrant_contact {
    contact_type       = local.contact_type
    first_name         = var.domain_contact.first_name
    last_name          = var.domain_contact.last_name
    organization_name  = var.domain_contact.organization_name
    address_line_1      = var.domain_contact.address_line_1
    city                 = var.domain_contact.city
    state                = var.domain_contact.state
    country_code         = var.domain_contact.country_code
    zip_code              = var.domain_contact.zip_code
    phone_number          = var.domain_contact.phone_number
    email                 = var.domain_contact.email
  }

  admin_contact {
    contact_type       = local.contact_type
    first_name         = var.domain_contact.first_name
    last_name          = var.domain_contact.last_name
    organization_name  = var.domain_contact.organization_name
    address_line_1      = var.domain_contact.address_line_1
    city                 = var.domain_contact.city
    state                = var.domain_contact.state
    country_code         = var.domain_contact.country_code
    zip_code              = var.domain_contact.zip_code
    phone_number          = var.domain_contact.phone_number
    email                 = var.domain_contact.email
  }

  tech_contact {
    contact_type       = local.contact_type
    first_name         = var.domain_contact.first_name
    last_name          = var.domain_contact.last_name
    organization_name  = var.domain_contact.organization_name
    address_line_1      = var.domain_contact.address_line_1
    city                 = var.domain_contact.city
    state                = var.domain_contact.state
    country_code         = var.domain_contact.country_code
    zip_code              = var.domain_contact.zip_code
    phone_number          = var.domain_contact.phone_number
    email                 = var.domain_contact.email
  }

  name_server {
    name = aws_route53_zone.main.name_servers[0]
  }
  name_server {
    name = aws_route53_zone.main.name_servers[1]
  }
  name_server {
    name = aws_route53_zone.main.name_servers[2]
  }
  name_server {
    name = aws_route53_zone.main.name_servers[3]
  }

  lifecycle {
    prevent_destroy = true
  }
}
