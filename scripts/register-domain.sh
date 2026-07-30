#!/usr/bin/env bash
# One-time domain registration via the AWS CLI.
#
# Terraform's aws_route53domains_registered_domain resource only ADOPTS an
# already-registered domain — there is no Terraform resource that performs
# the initial registration, since it's a one-time, non-idempotent,
# real-money transaction with ICANN email verification attached.
#
# Run this once by hand, then `terraform apply` to bring the domain under
# Terraform management (dns.tf + domain.tf).
#
# COSTS MONEY IMMEDIATELY (~$13-14/yr for a .com, current Route 53 pricing).
# Not meant to run unattended — review the values below before running.
set -euo pipefail

DOMAIN_NAME="nando0x0a.com"
DURATION_YEARS=1

# Keep these in sync with terraform.tfvars -> domain_contact
FIRST_NAME="First"
LAST_NAME="Last"
ADDRESS_LINE_1="123 Main St"
CITY="City"
STATE="ST"
COUNTRY_CODE="US"
ZIP_CODE="00000"
PHONE_NUMBER="+1.5555555555"
EMAIL="you@example.com"

CONTACT_JSON=$(cat <<JSON
{
  "FirstName": "$FIRST_NAME",
  "LastName": "$LAST_NAME",
  "ContactType": "PERSON",
  "AddressLine1": "$ADDRESS_LINE_1",
  "City": "$CITY",
  "State": "$STATE",
  "CountryCode": "$COUNTRY_CODE",
  "ZipCode": "$ZIP_CODE",
  "PhoneNumber": "$PHONE_NUMBER",
  "Email": "$EMAIL"
}
JSON
)

echo "About to register $DOMAIN_NAME for $DURATION_YEARS year(s)."
echo "This charges your AWS account immediately and is not easily refundable."
read -rp "Type the domain name to confirm: " CONFIRM
[ "$CONFIRM" = "$DOMAIN_NAME" ] || { echo "Confirmation mismatch, aborting."; exit 1; }

aws route53domains register-domain \
  --region us-east-1 \
  --domain-name "$DOMAIN_NAME" \
  --duration-in-years "$DURATION_YEARS" \
  --auto-renew \
  --admin-contact "$CONTACT_JSON" \
  --registrant-contact "$CONTACT_JSON" \
  --tech-contact "$CONTACT_JSON" \
  --privacy-protect-admin-contact \
  --privacy-protect-registrant-contact \
  --privacy-protect-tech-contact

echo "Registration submitted (usually takes minutes, occasionally longer)."
echo "Check status with: aws route53domains list-operations --region us-east-1"
echo "ICANN will also email the registrant address above for verification — confirm it promptly."
