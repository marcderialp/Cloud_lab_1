# Lab 1 - Docker, Compose and Swarm

Containerised infrastructure of a company: a reviews application with its database, cache,
mail and backups, a monitoring platform and Moodle (Atenea). Full documentation (design,
deployment, data, backups, tests): **docs/report.pdf**.

| Environment | File | Where it runs |
|---|---|---|
| Local | `compose.yml` | one machine, HTTP, no shared disk |
| Production | `production.yml` | Docker Swarm of 7 nodes, HTTPS (self-signed), NFS, replicated services |

All images are public in one Docker Hub repository, `omarcornejo/lab1grouph`, one tag per
service (`core-1.0`, `moodle-1.0`, ...): nothing has to be built to deploy.

## Local

```bash
docker compose pull && docker compose up -d
```

| URL | |
|---|---|
| http://app.localhost:8080 | reviews application |
| http://lms.localhost:8080 | Moodle (the first start takes about 3 minutes) |
| http://grafana.localhost:8080 | Grafana |
| http://mail.localhost:8080 | mails sent by the application |

`docker compose down -v` stops it and removes the data.

## Production

Seven nodes (front1, front2, app1, app2, stats, atenea, backup). In this project they run on
this computer as Docker-in-Docker containers (about 8 GB of RAM, ports 80, 443 and 8080 free):

```bash
scripts/sim-swarm.sh up      # nodes + swarm + labels + docker stack deploy
scripts/sim-swarm.sh down
```

| URL | |
|---|---|
| https://app.localhost, https://lms.localhost, https://grafana.localhost | self-signed certificate: accept the browser warning |
| http://mail.localhost:8080 | mails sent by the application |

On seven real machines the steps are the same: `docker swarm init/join`,
`scripts/label-nodes.sh`, `export NFS_SERVER=<private IP of the atenea node>` and
`docker stack deploy -c production.yml lab1`.

## Users and passwords

Every secret has the value `groupH` (files in `secrets/`, committed on purpose so that
nothing has to be created by hand). Moodle's policy rejects it, so its administrator uses
`groupH-2026`.

| | User | Password |
|---|---|---|
| Grafana | `admin` | `groupH` |
| Moodle | `admin` | `groupH-2026` |

The users of the databases and the rest of the secrets are listed in the report.

## Layout

```
compose.yml, production.yml    the two environments
app/        core, static, db (Patroni), haproxy, redis, sentinel, smtp, auto, backup
atenea/     Moodle and MariaDB images
basic/      nginx frontend, NFS server
stats/      Grafana, Prometheus, exporters
scripts/    sim-swarm.sh, label-nodes.sh, publish.sh, restore.sh
secrets/    passwords (Docker secrets)
docs/       report
```

## Operations

```bash
docker exec $(docker ps -qf name=pg-1) patronictl -c /etc/patroni.yml list   # database leader
scripts/restore.sh <backup folder> app|grafana|moodle|moodledata             # restore a backup
docker login && scripts/publish.sh                                           # rebuild and publish images
```
