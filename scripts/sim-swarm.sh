#!/bin/bash
set -e
if [ "$1" = down ]; then
  docker exec front1 docker stack rm lab1 >/dev/null 2>&1
  for i in $(seq 1 60); do [ -z "$(docker exec front1 docker ps -q 2>/dev/null | tail -n +1 | head -n1)" ] && break; sleep 3; done
  for n in front1 front2 app1 app2 stats atenea backup; do docker rm -f $n >/dev/null 2>&1; docker volume rm sim-$n >/dev/null 2>&1; done
  docker network rm lab1net >/dev/null 2>&1; echo removed; exit 0
fi
NODES="front1 front2 app1 app2 stats atenea backup"
NFS_SERVER=0.0.0.0 docker compose -f production.yml pull --ignore-pull-failures 2>&1 | tail -2
docker pull -q docker:27-dind >/dev/null
R=omarcornejo/lab1grouph; V=1.0
G="gcr.io/cadvisor/cadvisor:v0.49.1 prom/node-exporter:v1.8.2"
APP="$R:core-$V $R:static-$V $R:smtp-$V $R:auto-$V $R:haproxy-$V $R:postgres-$V $R:redis-$V $R:sentinel-$V quay.io/coreos/etcd:v3.5.15 $G"
declare -A IM=(
 [front1]="$R:frontend-$V certbot/certbot:v2.11.0 $G"
 [front2]="$R:frontend-$V $G"
 [app1]="$APP" [app2]="$APP"
 [stats]="$R:grafana-$V $R:prometheus-$V $R:postgres-$V $R:sentinel-$V $R:blackbox-$V $R:mysqld-exporter-$V quay.io/coreos/etcd:v3.5.15 oliver006/redis_exporter:v1.62.0 prometheuscommunity/postgres-exporter:v0.15.0 $G"
 [atenea]="$R:moodle-$V $R:moodle-db-$V $R:nfs-$V $G"
 [backup]="$R:backup-$V $R:prometheus-$V $G")
for n in $NODES; do docker rm -f $n >/dev/null 2>&1 || true; docker volume rm sim-$n >/dev/null 2>&1 || true; done
docker network rm lab1net >/dev/null 2>&1 || true
docker network create --subnet 172.30.0.0/24 lab1net >/dev/null
i=11; for n in $NODES; do
  PORTS=""; [ $n = front1 ] && PORTS="-p 80:80 -p 443:443 -p 8080:8080"
  docker run -d --privileged --name $n --hostname $n --network lab1net --ip 172.30.0.$i $PORTS \
     -e DOCKER_TLS_CERTDIR= -v sim-$n:/var/lib/docker docker:27-dind >/dev/null; i=$((i+1)); done
for n in $NODES; do timeout 120 sh -c "until docker exec $n docker info >/dev/null 2>&1; do sleep 2; done"; done
docker exec front1 docker swarm init --advertise-addr 172.30.0.11 >/dev/null
MT=$(docker exec front1 docker swarm join-token -q manager); WT=$(docker exec front1 docker swarm join-token -q worker)
for n in app1 stats; do docker exec $n docker swarm join --token $MT 172.30.0.11:2377 >/dev/null; done
for n in front2 app2 atenea backup; do docker exec $n docker swarm join --token $WT 172.30.0.11:2377 >/dev/null; done
for n in $NODES; do (docker save ${IM[$n]} | docker exec -i $n docker load >/dev/null 2>&1) & done; wait
docker exec front1 mkdir -p /lab1
docker cp production.yml front1:/lab1/ && docker cp secrets front1:/lab1/secrets && docker cp scripts front1:/lab1/scripts
docker exec front1 sh -c 'cd /lab1 && sh scripts/label-nodes.sh'
docker exec front1 sh -c 'cd /lab1 && NFS_SERVER=172.30.0.16 docker stack deploy -c production.yml lab1'
echo "deployed. Open https://app.localhost  https://lms.localhost  https://grafana.localhost (self-signed: accept the warning) and http://mail.localhost:8080"
