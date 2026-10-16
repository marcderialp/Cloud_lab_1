#!/bin/sh
set -e
pw() { cat "/run/secrets/$1"; }
psql -v ON_ERROR_STOP=1 "$1" \
    -v app="$(pw app_db_password)" -v grafana="$(pw grafana_db_password)" \
    -v bak="$(pw backup_db_password)" -v exp="$(pw exporter_db_password)" <<'SQL'
CREATE ROLE app LOGIN PASSWORD :'app';
CREATE ROLE grafana LOGIN PASSWORD :'grafana';
CREATE ROLE backup LOGIN PASSWORD :'bak';
GRANT pg_read_all_data TO backup;
CREATE ROLE exporter LOGIN PASSWORD :'exp';
GRANT pg_monitor TO exporter;
CREATE DATABASE app OWNER app;
CREATE DATABASE grafana OWNER grafana;
REVOKE CONNECT ON DATABASE app FROM PUBLIC;
REVOKE CONNECT ON DATABASE grafana FROM PUBLIC;
GRANT CONNECT ON DATABASE app TO backup;
GRANT CONNECT ON DATABASE grafana TO backup;
SQL
psql -v ON_ERROR_STOP=1 -h 127.0.0.1 -U app -d app <<'SQL'
CREATE TABLE comments (
    id SERIAL PRIMARY KEY, author TEXT NOT NULL, body TEXT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    created TIMESTAMPTZ DEFAULT now());
CREATE TABLE external_ratings (
    id SERIAL PRIMARY KEY, url TEXT NOT NULL, rating REAL NOT NULL,
    captured TIMESTAMPTZ DEFAULT now());
SQL
