# di-day-deployment-project

A small Vue + Vite page that shows its own build information (version, commit, branch, build time), used to practise a container deployment pipeline.

## Layout

| Path | Contents |
|---|---|
| `app/` | Vue application |
| `Dockerfile`, `nginx.conf` | Container image |
| `compose.yaml`, `Makefile` | Local build and run |
| `scripts/` | Server provisioning and deploy scripts, with a [server runbook](scripts/README-server.md) |
| `server/` | Compose file for the server |
| `.github/workflows/` | CI for pull requests; image publishing to GHCR and deployment on push to `main` |

## Run locally

```bash
make build
make run      # http://localhost:8080
make verify   # checks /healthz and that the commit SHA is in the bundle
make stop
```
