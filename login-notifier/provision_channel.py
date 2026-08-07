#!/usr/bin/env python3
"""One-time (idempotent) provisioning step: uses the Discord bot token to
create a #login-alerts channel (if it doesn't already exist) and a webhook
for it, then prints the webhook URL. Run this once after the bot has been
authorized into the server -- the bot token itself is NOT needed for
ongoing operation after this; notifier.py posts via the resulting webhook
URL only, matching ThreatForge's existing DiscordNotifier pattern.

Safe to re-run: both lookups check for an existing channel/webhook by name
before creating one, so running this twice reuses what's already there
instead of creating duplicates.

Usage:
    DISCORD_BOT_TOKEN=... python3 provision_channel.py [channel_name]
"""
import os
import sys

import requests

API = "https://discord.com/api/v10"
CHANNEL_TYPE_TEXT = 0
WEBHOOK_NAME = "Login Notifier"


def _headers(token: str) -> dict:
    return {"Authorization": f"Bot {token}"}


def _get_guild_id(token: str) -> str:
    """Auto-discovers the guild instead of asking for a Guild ID -- assumes
    the bot has been authorized into exactly one server."""
    resp = requests.get(f"{API}/users/@me/guilds", headers=_headers(token), timeout=10)
    resp.raise_for_status()
    guilds = resp.json()
    if len(guilds) != 1:
        names = ", ".join(f"{g['name']} ({g['id']})" for g in guilds) or "none"
        print(f"Expected the bot to be in exactly 1 server, found {len(guilds)}: {names}", file=sys.stderr)
        print("Pass the guild explicitly via DISCORD_GUILD_ID if this bot is meant to be in more than one.", file=sys.stderr)
        sys.exit(1)
    return guilds[0]["id"]


def _get_or_create_channel(token: str, guild_id: str, name: str) -> str:
    resp = requests.get(f"{API}/guilds/{guild_id}/channels", headers=_headers(token), timeout=10)
    resp.raise_for_status()
    for ch in resp.json():
        if ch["type"] == CHANNEL_TYPE_TEXT and ch["name"] == name:
            print(f"Channel #{name} already exists ({ch['id']})", file=sys.stderr)
            return ch["id"]
    resp = requests.post(
        f"{API}/guilds/{guild_id}/channels",
        headers=_headers(token),
        json={"name": name, "type": CHANNEL_TYPE_TEXT, "topic": "Automated alerts when someone successfully logs into a Cloud-project web app"},
        timeout=10,
    )
    resp.raise_for_status()
    channel_id = resp.json()["id"]
    print(f"Created channel #{name} ({channel_id})", file=sys.stderr)
    return channel_id


def _get_or_create_webhook(token: str, channel_id: str) -> str:
    resp = requests.get(f"{API}/channels/{channel_id}/webhooks", headers=_headers(token), timeout=10)
    resp.raise_for_status()
    for wh in resp.json():
        if wh.get("name") == WEBHOOK_NAME:
            print("Webhook already exists, reusing it", file=sys.stderr)
            return f"https://discord.com/api/webhooks/{wh['id']}/{wh['token']}"
    resp = requests.post(
        f"{API}/channels/{channel_id}/webhooks",
        headers=_headers(token),
        json={"name": WEBHOOK_NAME},
        timeout=10,
    )
    resp.raise_for_status()
    wh = resp.json()
    print("Created a new webhook", file=sys.stderr)
    return f"https://discord.com/api/webhooks/{wh['id']}/{wh['token']}"


def main() -> None:
    token = os.environ["DISCORD_BOT_TOKEN"]
    channel_name = sys.argv[1] if len(sys.argv) > 1 else "login-alerts"
    guild_id = os.environ.get("DISCORD_GUILD_ID") or _get_guild_id(token)
    channel_id = _get_or_create_channel(token, guild_id, channel_name)
    webhook_url = _get_or_create_webhook(token, channel_id)
    print(webhook_url)  # stdout only -- this is the value the caller captures


if __name__ == "__main__":
    main()
