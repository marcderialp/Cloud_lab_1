#!/bin/sh
# Builds every image of production.yml and pushes it to Docker Hub. All the images go to
# ONE repository, one tag per service: omarcornejo/lab1grouph:<service>-<version>
#   docker login
#   scripts/publish.sh                 # IMAGE_REPO defaults to omarcornejo/lab1grouph, TAG to 1.0
set -e
cd "$(dirname "$0")/.."
export IMAGE_REPO="${IMAGE_REPO:-omarcornejo/lab1grouph}" TAG="${TAG:-1.0}"
export NFS_SERVER="${NFS_SERVER:-0.0.0.0}"   # only needed to parse production.yml
docker compose -f production.yml build
docker compose -f production.yml push --ignore-push-failures
echo "published $IMAGE_REPO:<service>-$TAG"
