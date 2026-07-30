#!/usr/bin/env python3
"""Tails nginx's access log (bind-mounted read-only) and posts a Discord
notification the first time a NEW (host, IP) pair successfully
authenticates against Basic Auth, debounced so a normal browsing session
doesn't spam one message per click.

Requires the 'vhost' log_format added to nginx.conf, which prefixes every
line with $host -- nginx's default 'combined' format has no per-line
domain field, so ThreatForge and SOC-Skill (which share one host and one
access.log) couldn't otherwise be told apart reliably.
"""
import os
import re
import subprocess
import time
from datetime import datetime, timezone

import requests

LOG_PATH = os.getenv("NGINX_LOG_PATH", "/var/log/nginx/access.log")
DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL", "")
DEBOUNCE_SECONDS = int(os.getenv("DEBOUNCE_SECONDS", "1800"))  # 30 min: one alert per "session", not per click

# Matches the 'vhost' log_format: $host $remote_addr - $remote_user [$time_local] "$request" $status ...
LINE_RE = re.compile(
    r'^(?P<host>\S+) (?P<ip>\S+) - (?P<user>\S+) \[(?P<time>[^\]]+)\] '
    r'"(?P<method>[A-Z]+) (?P<path>\S+) \S+" (?P<status>\d+)'
)

# Paths that don't represent a real page load/action -- ignored even if they
# happen to be the first 200 after a quiet period, so the notified path is
# always something meaningful.
_IGNORED_PATH_PREFIXES = ("/static/",)
_IGNORED_PATHS = {"/favicon.ico"}

_last_seen: dict[tuple[str, str], float] = {}


def _notify(host: str, ip: str, user: str, path: str) -> None:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    message = f"\U0001F513 **Login: {host}**\n{now} · user `{user}` from `{ip}` · `{path}`"
    if not DISCORD_WEBHOOK_URL:
        print(f"[login-notifier] DISCORD_WEBHOOK_URL not set, would have posted: {message}", flush=True)
        return
    try:
        resp = requests.post(
            DISCORD_WEBHOOK_URL,
            json={"content": message, "username": "Login Notifier"},
            timeout=10,
        )
        resp.raise_for_status()
        print(f"[login-notifier] posted: {host} {ip} {user} {path}", flush=True)
    except Exception as e:
        print(f"[login-notifier] Discord post failed: {e}", flush=True)


def _handle_line(line: str) -> None:
    m = LINE_RE.match(line)
    if not m:
        return
    host, ip, user, status, path = m["host"], m["ip"], m["user"], m["status"], m["path"]
    if status != "200" or user == "-":
        return
    if path in _IGNORED_PATHS or any(path.startswith(p) for p in _IGNORED_PATH_PREFIXES):
        return

    key = (host, ip)
    now = time.time()
    last = _last_seen.get(key, 0.0)
    _last_seen[key] = now
    if now - last < DEBOUNCE_SECONDS:
        return  # same host+IP, still within the debounce window -- not a "new" login
    _notify(host, ip, user, path)


def main() -> None:
    print(f"[login-notifier] watching {LOG_PATH}, debounce={DEBOUNCE_SECONDS}s", flush=True)
    # `tail -F` (not -f): follows by filename, so it survives logrotate
    # replacing the file out from under it, not just the original inode.
    proc = subprocess.Popen(
        # stdbuf -oL forces tail's stdout to line-buffer -- without it, tail
        # fully-buffers its output when piped (not a TTY), so on a
        # low-traffic log new lines can sit in the pipe indefinitely instead
        # of reaching Python right away.
        ["stdbuf", "-oL", "tail", "-F", "-n", "0", LOG_PATH],
        stdout=subprocess.PIPE,
        text=True,
        bufsize=1,
    )
    for line in proc.stdout:
        _handle_line(line.rstrip("\n"))


if __name__ == "__main__":
    main()
