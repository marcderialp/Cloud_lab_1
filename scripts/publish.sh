#!/bin/sh
set -e
cd "$(dirname "$0")/.."
export IMAGE_REPO="${IMAGE_REPO:-omarcornejo/lab1grouph}" TAG="${TAG:-1.0}"
export NFS_SERVER="${NFS_SERVER:-0.0.0.0}"
docker compose -f production.yml build
docker compose -f production.yml push --ignore-push-failures
echo "published $IMAGE_REPO:<service>-$TAG"
