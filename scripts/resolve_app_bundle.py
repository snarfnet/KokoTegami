#!/usr/bin/env python3
import os
import sys
import time

import jwt
import requests

APP_ID = os.environ["APP_ID"]
KEY_ID = os.environ.get("ASC_KEY_ID", "WDXGY9WX55")
ISSUER = os.environ.get("ASC_ISSUER_ID", "2be0734f-943a-4d61-9dc9-5d9045c46fec")
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")

p8 = open(P8_PATH, encoding="utf-8").read()


def token():
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        p8,
        algorithm="ES256",
        headers={"kid": KEY_ID},
    )


response = requests.get(
    f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}",
    headers={"Authorization": f"Bearer {token()}"},
    timeout=120,
)
response.raise_for_status()
attrs = response.json()["data"]["attributes"]
bundle_id = attrs.get("bundleId")
if not bundle_id:
    raise RuntimeError("App Store Connect did not return a bundleId.")
print(f"APP_BUNDLE_ID={bundle_id}")
print(f"Resolved Bundle ID: {bundle_id}", file=sys.stderr, flush=True)
