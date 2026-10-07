"""Core app: a page where people leave reviews with a 1-5 rating.
Postgres for the data, redis to cache the average, mails through the smtp
service, /api/ratings for the auto feeder and /metrics for prometheus."""
import json
import os
import smtplib
import socket
from email.message import EmailMessage

import psycopg
import redis
from flask import Flask, Response, abort, jsonify, redirect, render_template, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest


def secret(name):
    # docker secrets: the value is in the file given by NAME_FILE
    path = os.environ.get(name + "_FILE")
    return open(path).read().strip() if path else os.environ.get(name, "")


DB = dict(host="db", dbname="app", user="app", password=secret("DB_PASSWORD"))
cache = redis.Redis(host="redis", socket_timeout=2)
REQUESTS = Counter("core_requests_total", "HTTP requests", ["endpoint"])
COMMENTS = Counter("core_comments_total", "Comments posted")
app = Flask(__name__)
ready = False


def db():
    return psycopg.connect(**DB, autocommit=True, connect_timeout=5)


@app.before_request
def init():
    global ready
    REQUESTS.labels(request.endpoint or "none").inc()
    if not ready and request.endpoint != "metrics":
        try:
            with db() as conn:
                conn.execute("""
                    CREATE TABLE IF NOT EXISTS comments (
                        id SERIAL PRIMARY KEY, author TEXT, body TEXT,
                        rating INT CHECK (rating BETWEEN 1 AND 5),
                        created TIMESTAMPTZ DEFAULT now());
                    CREATE TABLE IF NOT EXISTS external_ratings (
                        id SERIAL PRIMARY KEY, url TEXT, rating REAL,
                        captured TIMESTAMPTZ DEFAULT now());""")
            ready = True
        except psycopg.OperationalError:
            return "database not ready", 503


def average():
    try:
        if (hit := cache.get("avg")) is not None:
            return json.loads(hit)
    except redis.RedisError:
        pass
    with db() as conn:
        row = conn.execute("SELECT round(avg(rating), 2)::float, count(*) FROM comments").fetchone()
    try:
        cache.setex("avg", 30, json.dumps(row))
    except redis.RedisError:
        pass
    return row


@app.get("/")
def index():
    with db() as conn:
        comments = conn.execute(
            "SELECT author, body, rating FROM comments ORDER BY id DESC LIMIT 20").fetchall()
    avg, total = average()
    return render_template("index.html", comments=comments, avg=avg, total=total,
                           host=socket.gethostname())


@app.post("/comment")
def comment():
    author = request.form.get("author", "")[:60]
    body = request.form.get("body", "")[:1000]
    rating = request.form.get("rating", type=int)
    if not author or not body or rating not in range(1, 6):
        abort(400)
    with db() as conn:
        conn.execute("INSERT INTO comments (author, body, rating) VALUES (%s, %s, %s)",
                     (author, body, rating))
    cache.delete("avg")
    COMMENTS.inc()
    try:
        msg = EmailMessage()
        msg["Subject"], msg["From"], msg["To"] = f"New review ({rating}/5)", "noreply@lab1", os.environ["NOTIFY_EMAIL"]
        msg.set_content(f"{author}: {body}")
        with smtplib.SMTP("smtp", 25, timeout=10) as s:
            s.send_message(msg)
    except Exception as e:
        app.logger.warning("mail not sent: %s", e)
    return redirect("/")


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
    with db() as conn:
        ext = conn.execute("SELECT DISTINCT ON (url) url, rating, captured::text "
                           "FROM external_ratings ORDER BY url, captured DESC").fetchall()
    avg, total = average()
    return jsonify(average=avg, comments=total,
                   external=[dict(url=u, rating=r, captured=c) for u, r, c in ext])


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), content_type=CONTENT_TYPE_LATEST)
