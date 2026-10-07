"""Every FEED_INTERVAL seconds reads the schema.org rating (JSON-LD) of the
pages in FEED_URLS and sends it to the core app."""
import json
import os
import re
import time

import requests

URLS = os.environ.get("FEED_URLS", "http://core:8000/").split(",")
TOKEN = open(os.environ["FEED_TOKEN_FILE"]).read().strip()
LDJSON = re.compile(r'<script type="application/ld\+json">(.*?)</script>', re.S)

while True:
    for url in URLS:
        try:
            html = requests.get(url, timeout=10).text
            for block in LDJSON.findall(html):
                rating = json.loads(block).get("aggregateRating", {}).get("ratingValue")
                if rating is not None:
                    requests.post("http://core:8000/api/ratings", timeout=10,
                                  json={"url": url, "rating": rating},
                                  headers={"Authorization": "Bearer " + TOKEN})
                    print(url, rating)
        except Exception as e:
            print("error with", url, e)
    time.sleep(int(os.environ.get("FEED_INTERVAL", "300")))
