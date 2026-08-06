#!/usr/bin/env bash
# One-shot bootstrap for a fresh Ubuntu 24.04 (noble) amd64 server. Run as root.
# Idempotent: safe to re-run after recreating the server.
set -euo pipefail

STEP="startup"
trap 'echo "PROVISION FAILED during step: ${STEP}" >&2' ERR

step() { STEP="$1"; echo "==> ${STEP}"; }

[ "$(id -u)" -eq 0 ] || { echo "Run as root." >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive

step "base packages"
apt-get update -q
apt-get install -qy ca-certificates curl ufw

step "docker apt repo"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -q

step "verify docker repo has packages for noble"
# Ask apt directly instead of parsing output: dry-run succeeds iff installable.
if ! apt-get install --dry-run -qq docker-ce >/dev/null; then
  echo "docker-ce is not installable for codename 'noble'." >&2
  echo "Diagnostics (apt-cache policy docker-ce):" >&2
  apt-cache policy docker-ce >&2 || true
  echo "Not falling back to docker.io." >&2
  exit 1
fi
madison="$(LC_ALL=C apt-cache madison docker-ce)"
case "$madison" in
  *download.docker.com*) echo "docker-ce is installable from download.docker.com" ;;
  *) echo "docker-ce resolves, but not from download.docker.com:" >&2
     echo "$madison" >&2
     exit 1 ;;
esac

step "install docker"
apt-get install -qy docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

step "deploy user"
id deploy >/dev/null 2>&1 || adduser --disabled-password --gecos "" deploy
usermod -aG docker deploy

step "app directory"
install -d -o deploy -g deploy /opt/di-day-deployment-project

step "firewall"
ufw allow 22/tcp
ufw allow 80/tcp
ufw default deny incoming
ufw default allow outgoing
ufw --force enable   # --force: no prompt; existing SSH connections are not cut

step "sshd hardening"
cat > /etc/ssh/sshd_config.d/90-di-day.conf <<'EOF'
PasswordAuthentication no
PermitRootLogin prohibit-password
EOF
sshd -t                 # validate before reload — a bad config must not ship
systemctl reload ssh    # reload keeps the current session alive

step "summary"
echo "--------------------------------------------"
docker --version
docker compose version
ufw status verbose
id deploy
echo "Provisioning complete."
