# login-notifier

Posts a Discord notification the first time someone successfully
authenticates (Basic Auth) against ThreatForge or SOC-Skill, by tailing
nginx's access log on the shared EC2 instance. Debounced to one alert per
~30 minutes per (domain, IP) pair — not one alert per click.

## One-time setup (per Discord server)

Requires a Discord bot (not just a webhook) already created and authorized
into the target server with the `Manage Channels` permission — see the
main repo's deployment notes for the Developer Portal steps. Once the
bot's token is available:

```bash
export DISCORD_BOT_TOKEN=...   # never commit this
python3 provision_channel.py   # idempotent -- safe to re-run
```

This creates a `#login-alerts` channel (if it doesn't already exist) and a
webhook for it, printing the webhook URL on stdout. That URL is the only
thing the ongoing service needs — the bot token itself is not used again
after this step.

## Deploy

```bash
mkdir -p /opt/docker/login-notifier
cat > /opt/docker/login-notifier/.env <<EOF
DISCORD_WEBHOOK_URL=<url printed by provision_channel.py>
EOF
chmod 600 /opt/docker/login-notifier/.env

docker build -t login-notifier .
docker compose up -d
```

Requires nginx's `access_log` to use a log format that prefixes each line
with `$host` (see `nginx.conf`'s `log_format vhost` directive) — the
default `combined` format has no per-line domain field, and ThreatForge
and SOC-Skill share one host and one access log.
