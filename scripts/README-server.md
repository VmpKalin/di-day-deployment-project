# Server runbook

Fresh Ubuntu 24.04 (Hetzner CX, amd64). From your machine, in the repo root:

```sh
scp scripts/provision.sh root@<IP>:/root/
ssh root@<IP> "bash /root/provision.sh"
```

Safe to re-run if the server is recreated. On success it prints docker/compose
versions, ufw status, and the `deploy` user's groups.
