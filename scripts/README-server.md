# Server runbook

Fresh Ubuntu 24.04 (Hetzner CX, amd64). Repo is public — no server-side credentials needed.

## 1. Provision (as root, once — safe to re-run)

```sh
ssh root@<IP> "curl -fsSL https://raw.githubusercontent.com/VmpKalin/di-day-deployment-project/main/scripts/provision.sh | bash"
```

## 2. Get the code (as deploy — same commands for first fetch and every update)

```sh
ssh deploy@<IP>
cd /opt/di-day-deployment-project
git init -q -b main
git remote add origin https://github.com/VmpKalin/di-day-deployment-project.git 2>/dev/null || true
git fetch -q origin main && git reset --hard -q origin/main
```

Plain `git clone` would refuse: the directory already exists (and later holds
`.env` state). `init + fetch + reset` does the same job and is re-runnable;
`reset --hard` never touches the untracked `server/.env*` files.

## 3. Deploy a tag (as deploy, on the server)

```sh
/opt/di-day-deployment-project/scripts/deploy.sh sha-42eea3c
```

Health-gated: on failure it restores the previous tag and exits non-zero.

## 4. Roll back manually

```sh
cd /opt/di-day-deployment-project
scripts/deploy.sh "$(sed -n 's/^IMAGE_TAG=//p' server/.env.prev)"
```

Verify any time: `curl http://<IP>/healthz` → `ok`.
