#!/usr/bin/env bash
# Deploy one image tag; roll back to the previous tag if health never goes green.
# Usage (on the server, as deploy): /opt/di-day-deployment-project/scripts/deploy.sh sha-42eea3c
set -euo pipefail
# Run everything from server/: its compose.yaml is the deploy one (the repo
# root holds the local-dev compose file), and .env/.env.prev live here too.
cd "$(dirname "$0")/../server"

TAG="${1:-}"
if ! [[ "$TAG" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$ ]] || [ "$#" -ne 1 ]; then
  echo "usage: $0 <image-tag>    e.g. $0 sha-42eea3c" >&2
  exit 2
fi

log() { echo "[deploy] $*"; }
current_tag() { [ -f .env ] && sed -n 's/^IMAGE_TAG=//p' .env || true; }

healthy() {  # poll up to 60s; bail early once docker declares the container unhealthy
  for _ in $(seq 1 30); do
    state="$(docker inspect -f '{{.State.Health.Status}}' "$(docker compose ps -q web)" 2>/dev/null || echo starting)"
    [ "$state" = healthy ] && return 0
    [ "$state" = unhealthy ] && return 1
    sleep 2
  done
  return 1
}

PREV="$(current_tag)"
log "deploying tag: $TAG (currently live: ${PREV:-nothing})"

# Save the rollback target before switching, so even a failed pull can roll
# back. Never point the rollback at the tag being deployed.
if [ -n "$PREV" ] && [ "$PREV" != "$TAG" ]; then
  echo "IMAGE_TAG=$PREV" > .env.prev
fi
echo "IMAGE_TAG=$TAG" > .env

log "pulling image and starting container"
if docker compose pull -q && docker compose up -d \
   && log "waiting for health (max 60s)" && healthy; then
  log "SUCCESS: $TAG is live (rollback target: ${PREV:-none})"
  exit 0
fi

log "deploy of $TAG FAILED (pull error or container never became healthy)"
if [ ! -f .env.prev ]; then
  log "NO ROLLBACK POSSIBLE: no .env.prev exists — nothing was deployed before."
  exit 1
fi
cp .env.prev .env
ROLLBACK_TAG="$(current_tag)"
docker compose pull -q
docker compose up -d
echo "=================================================================="
echo "[deploy] ROLLBACK OCCURRED: $TAG failed its health check."
echo "[deploy] Restored previous tag: $ROLLBACK_TAG — that is what is live now."
echo "=================================================================="
exit 1
