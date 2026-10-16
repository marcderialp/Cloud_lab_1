import json
import os
import smtplib
import socket
from email.message import EmailMessage

import psycopg
import redis
from flask import Flask, Response, abort, jsonify, redirect, render_template, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest
from redis.sentinel import Sentinel

PER_PAGE = 5
NODE = os.environ.get("NODE") or socket.gethostname()


def secret(name):
    path = os.environ.get(name + "_FILE")
    return open(path).read().strip() if path else os.environ.get(name, "")


_H = os.environ.get("DB_HOST", "db")
_BASE = (f"dbname=app user={os.environ.get('DB_USER', 'app')} "
         f"password={secret('DB_PASSWORD')} connect_timeout=3")
_WRITE = f"host={_H} port=5432 {_BASE}"
_READ = f"host={_H},{_H} port=5433,5432 {_BASE}"

_SENTINELS = [(h, 26379) for h in os.environ.get("REDIS_SENTINELS", "").split(",") if h]
if _SENTINELS:
    cache = Sentinel(_SENTINELS, socket_timeout=1).master_for(
        os.environ.get("REDIS_MASTER", "mymaster"), socket_timeout=1, decode_responses=True)
else:
    cache = redis.Redis(host=os.environ.get("REDIS_HOST", "redis"), socket_timeout=1,
                        decode_responses=True)

REQUESTS = Counter("core_requests_total", "HTTP requests", ["endpoint"])
COMMENTS = Counter("core_comments_total", "Comments posted")
CACHE = Counter("core_cache_total", "Page cache lookups", ["result"])
app = Flask(__name__)


def db(read_only=False):
    return psycopg.connect(_READ if read_only else _WRITE, autocommit=True)


def cache_version():
    try:
        return int(cache.get("ver") or 0)
    except redis.RedisError:
        return 0


def cache_get(key):
    try:
        hit = cache.get(key)
        return json.loads(hit) if hit is not None else None
    except redis.RedisError:
        return None


def cache_set(key, value, ttl=30):
    try:
        cache.setex(key, ttl, json.dumps(value))
    except redis.RedisError:
        pass


@app.before_request
def count():
    if request.endpoint not in ("healthz", "metrics"):
        REQUESTS.labels(request.endpoint or "none").inc()


@app.after_request
def headers(resp):
    resp.headers["X-App-Node"] = NODE
    return resp


def summary(read_only=False):
    key = f"summary:{cache_version()}"
    if (hit := cache_get(key)) is not None:
        CACHE.labels("hit").inc()
        return hit
    CACHE.labels("miss").inc()
    with db(read_only) as conn:
        avg, total = conn.execute(
            "SELECT round(avg(rating), 2)::float, count(*) FROM comments").fetchone()
        dist = dict(conn.execute(
            "SELECT rating::text, count(*) FROM comments GROUP BY rating").fetchall())
    out = [avg, total, dist]
    cache_set(key, out)
    return out


def reviews(page):
    key = f"reviews:{cache_version()}:{page}"
    if (hit := cache_get(key)) is not None:
        return hit
    with db() as conn:
        rows = conn.execute(
            "SELECT author, body, rating, to_char(created, 'YYYY-MM-DD HH24:MI') "
            "FROM comments ORDER BY id DESC LIMIT %s OFFSET %s",
            (PER_PAGE, (page - 1) * PER_PAGE)).fetchall()
    cache_set(key, rows)
    return rows


@app.errorhandler(psycopg.OperationalError)
def database_unavailable(e):
    app.logger.warning("database unavailable: %s", str(e).strip().splitlines()[0] if str(e).strip() else e)
    return "database not ready", 503


@app.get("/healthz")
def healthz():
    return "ok"


@app.get("/readyz")
def readyz():
    try:
        with db() as conn:
            conn.execute("SELECT 1")
        return "ready"
    except psycopg.Error:
        return "database not ready", 503


@app.get("/")
def index():
    page = max(1, request.args.get("page", 1, type=int))
    avg, total, dist = summary()
    pages = max(1, -(-total // PER_PAGE))
    return render_template("index.html", comments=reviews(page), avg=avg, total=total,
                           dist=dist, page=page, pages=pages, node=NODE)


@app.post("/comment")
def comment():
    author = request.form.get("author", "").strip()[:60]
    body = request.form.get("body", "").strip()[:1000]
    rating = request.form.get("rating", type=int)
    if not author or not body or rating not in range(1, 6):
        abort(400)
    with db() as conn:
        conn.execute("INSERT INTO comments (author, body, rating) VALUES (%s, %s, %s)",
                     (author, body, rating))
    try:
        cache.incr("ver")
    except redis.RedisError as e:
        app.logger.warning("cache not invalidated: %s", e)
    COMMENTS.inc()
    try:
        msg = EmailMessage()
        msg["Subject"], msg["From"], msg["To"] = f"New review ({rating}/5)", "noreply@lab1", os.environ["NOTIFY_EMAIL"]
        msg.set_content(f"{author}: {body}")
        with smtplib.SMTP("smtp", 25, timeout=10) as s:
            s.send_message(msg)
    except Exception as e:
        app.logger.warning("mail not sent: %s", e)
    resp = redirect("/")
    resp.set_cookie("posted", "1", max_age=10)
    return resp


@app.post("/api/ratings")
def api_ratings():
    if request.headers.get("Authorization") != "Bearer " + secret("FEED_TOKEN"):
        abort(401)
    data = request.get_json(force=True)
    with db() as conn:
        conn.execute("INSERT INTO external_ratings (url, rating) VALUES (%s, %s)",
                     (data["url"], float(data["rating"])))
    return "", 201


@app.get("/api/stats")
def api_stats():
    with db(read_only=True) as conn:
        ext = conn.execute("SELECT DISTINCT ON (url) url, rating, captured::text "
                           "FROM external_ratings ORDER BY url, captured DESC").fetchall()
        hist = conn.execute(
            "SELECT url, rating, to_char(captured AT TIME ZONE 'UTC', 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') "
            "FROM (SELECT * FROM external_ratings ORDER BY captured DESC LIMIT 100) t "
            "ORDER BY captured").fetchall()
    avg, total, _ = summary(read_only=True)
    return jsonify(average=avg, comments=total,
                   external=[dict(url=u, rating=r, captured=c) for u, r, c in ext],
                   history=[dict(url=u, rating=r, captured=c) for u, r, c in hist])


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), content_type=CONTENT_TYPE_LATEST)
