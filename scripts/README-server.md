# Server runbook

Fresh Ubuntu 24.04 (Hetzner CX, amd64). Run everything from the repo root on your machine.

Placeholders — replace with your own values:

- `<IP>` — the server's public IPv4
- `./hetzner_di_day` — **your** personal root key for the server (any name)
- `./di_day_deploy_ci` — the dedicated CI deploy key, generated in step 1

## 1. Generate the CI deploy key (once)

```sh
ssh-keygen -t ed25519 -f ./di_day_deploy_ci -N "" -C "di-day-deploy-ci"
```

No passphrase (`-N ""`): CI has no human to type one. Keep this key separate from
your personal key so it can be revoked on its own.

## 2. Provision the server (as root — safe to re-run)

```sh
scp -i ./hetzner_di_day scripts/provision.sh root@<IP>:/root/
ssh -i ./hetzner_di_day root@<IP> "bash /root/provision.sh"
```

## 3. Install the deploy key for the `deploy` user

```sh
ssh -i ./hetzner_di_day root@<IP> "mkdir -p /home/deploy/.ssh && chmod 700 /home/deploy/.ssh && chown deploy:deploy /home/deploy/.ssh"
scp -i ./hetzner_di_day ./di_day_deploy_ci.pub root@<IP>:/tmp/ci.pub
ssh -i ./hetzner_di_day root@<IP> "cat /tmp/ci.pub >> /home/deploy/.ssh/authorized_keys && chmod 600 /home/deploy/.ssh/authorized_keys && chown deploy:deploy /home/deploy/.ssh/authorized_keys && rm /tmp/ci.pub"
```

Verify — proves SSH access and docker group membership in one shot:

```sh
ssh -i ./di_day_deploy_ci deploy@<IP> "docker ps"
```

GitHub repo secrets for CI: `DEPLOY_SSH_KEY` (the whole `./di_day_deploy_ci`
file, including header/footer lines), `DEPLOY_HOST` (`<IP>`), `DEPLOY_USER` (`deploy`).

## 4. Get the code onto the server (as deploy — same commands for updates)

```sh
ssh -i ./di_day_deploy_ci deploy@<IP>
cd /opt/di-day-deployment-project
git init -q -b main
git remote add origin https://github.com/VmpKalin/di-day-deployment-project.git 2>/dev/null || true
git fetch -q origin main && git reset --hard -q origin/main
```

(Plain `git clone` would refuse: the directory already exists and later holds
`.env` state. `reset --hard` never touches the untracked `server/.env*` files.)

## 5. Deploy a tag (as deploy, on the server)

Every push to `main` publishes `ghcr.io/vmpkalin/di-test-project:sha-<short-sha>`
plus `latest`. The value comes from the commit: `git log --oneline -1 origin/main`
→ prefix the short sha with `sha-`. It is also printed at the end of the
build-and-push job log ("Pushed: ...").

```sh
scripts/deploy.sh sha-410854a
curl -s http://localhost/healthz        # -> ok
```

Deploy a second, different tag to populate the rollback state, then inspect it:

```sh
scripts/deploy.sh latest
cat server/.env server/.env.prev
```

Health-gated: if the new container never turns healthy, deploy.sh restores the
tag from `server/.env.prev` and exits non-zero.

## 6. Roll back manually

```sh
cd /opt/di-day-deployment-project
scripts/deploy.sh "$(sed -n 's/^IMAGE_TAG=//p' server/.env.prev)"
```

Verify from anywhere: `curl http://<IP>/healthz` → `ok`.
