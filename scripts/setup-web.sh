#!/usr/bin/env bash
# Run ON the EC2 instance (not aiserver). Installs nginx + Certbot, deploys
# the reverse-proxy config, sets up HTTP Basic Auth, and issues the TLS cert.
#
# Usage: setup-web.sh <basic-auth-username> <certbot-contact-email>
# Password is prompted for interactively (not passed as an arg — shows up
# in shell history / process list otherwise).
set -euo pipefail

DOMAIN="threatforge.nando0x0a.com"
AUTH_USER="${1:?Usage: setup-web.sh <basic-auth-username> <certbot-contact-email>}"
CERTBOT_EMAIL="${2:?Usage: setup-web.sh <basic-auth-username> <certbot-contact-email>}"

echo "[1/5] Installing nginx, certbot, apache2-utils (for htpasswd)..."
sudo apt-get update -y
sudo apt-get install -y nginx certbot python3-certbot-nginx apache2-utils

echo "[2/5] Deploying nginx site config..."
sudo cp "$(dirname "$0")/../nginx/threatforge.conf" /etc/nginx/sites-available/threatforge.conf
sudo ln -sf /etc/nginx/sites-available/threatforge.conf /etc/nginx/sites-enabled/threatforge.conf
sudo rm -f /etc/nginx/sites-enabled/default

echo "[3/5] Setting up HTTP Basic Auth for user '$AUTH_USER'..."
sudo htpasswd -c /etc/nginx/.htpasswd "$AUTH_USER"

echo "[4/5] Testing and reloading nginx..."
sudo nginx -t
sudo systemctl reload nginx
sudo systemctl enable nginx

echo "[5/5] Requesting TLS certificate from Let's Encrypt..."
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$CERTBOT_EMAIL" --redirect

echo ""
echo "Done. https://$DOMAIN should now be live, gated by Basic Auth."
echo "Certbot auto-renewal is installed as a systemd timer — check with:"
echo "  systemctl list-timers | grep certbot"
