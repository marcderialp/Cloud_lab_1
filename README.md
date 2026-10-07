# Lab 1 - Docker, Compose and Swarm

Full documentation (design, deployment, data and backups): **docs/report.pdf**

## Secrets (once)

```bash
mkdir -p secrets
for s in db_password moodle_db_password grafana_admin_password feed_token; do
  openssl rand -hex 16 > secrets/$s
done
echo "$(openssl rand -hex 8)Aa1!" > secrets/moodle_admin_password   # moodle password policy
docker run --rm --entrypoint htpasswd httpd:2.4-alpine -Bbn lab1 <password> > secrets/registry_htpasswd
```

## Local

```bash
docker compose up -d --build
```

http://app.localhost:8080, http://lms.localhost:8080, http://grafana.localhost:8080,
http://mail.localhost:8080

## Production (swarm)

```bash
cp .env.example .env && set -a && . ./.env && set +a
docker compose -f production.yml build
docker compose -f production.yml push
docker stack deploy --with-registry-auth -c production.yml lab1
```

The NFS server runs apart on the storage node: `docker compose -f basic/nfs/nfs.yml up -d --build`.
