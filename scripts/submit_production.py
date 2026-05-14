#!/usr/bin/env python3
import os
import time

import jwt
import requests

APP_ID = os.environ.get("APP_ID", "6767550479")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ["BUILD_NUMBER"]
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


def api(method, path, **kwargs):
    last = None
    for _ in range(6):
        last = requests.request(
            method,
            f"https://api.appstoreconnect.apple.com/v1{path}",
            headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"},
            timeout=120,
            **kwargs,
        )
        if last.status_code not in (401, 429, 500, 502, 503, 504):
            return last
        time.sleep(15)
    return last


def body(response):
    try:
        return response.json()
    except Exception:
        return {}


def list_all(path):
    rows = []
    while path:
        response = api("GET", path)
        if response.status_code != 200:
            raise RuntimeError(f"List failed {response.status_code}: {response.text[:500]}")
        payload = response.json()
        rows.extend(payload.get("data", []))
        next_url = payload.get("links", {}).get("next")
        path = next_url.split("/v1", 1)[1] if next_url else None
    return rows


def find_version():
    versions = list_all(f"/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=200")
    for version in versions:
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == APP_VERSION:
            return version["id"], attrs.get("appStoreState")
    response = api(
        "POST",
        "/appStoreVersions",
        json={
            "data": {
                "type": "appStoreVersions",
                "attributes": {"platform": "IOS", "versionString": APP_VERSION},
                "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
            }
        },
    )
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Create version failed {response.status_code}: {response.text[:500]}")
    created = response.json()["data"]
    return created["id"], created["attributes"].get("appStoreState")


def wait_for_build():
    print(f"Waiting for build {BUILD_NUMBER} to become VALID...")
    for attempt in range(80):
        response = api(
            "GET",
            f"/builds?filter[app]={APP_ID}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1",
        )
        builds = body(response).get("data", [])
        if builds:
            build_id = builds[0]["id"]
            print(f"Build ready: {build_id}")
            return build_id
        print(f"Waiting... {attempt + 1}/80")
        time.sleep(30)
    raise RuntimeError("Build did not become VALID within 40 minutes.")


def set_review_notes(version_id):
    notes = (
        "This build resolves Guideline 1.2 for user-generated content.\n"
        "- Terms of Use are shown before anonymous login and state zero tolerance for objectionable content and abusive users.\n"
        "- Letter posting has objectionable-content filtering.\n"
        "- Each letter detail screen includes Report and Block controls.\n"
        "- Reporting or blocking immediately removes the letter from the user's feed and creates a developer moderation report.\n"
        "- Moderation reports are reviewed within 24 hours; offending content is removed and abusive users are ejected.\n"
        "Please see the attached App Review screen recording in App Review Information."
    )
    response = api("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    if response.status_code != 200:
        print(f"Review detail lookup skipped: {response.status_code}")
        return
    detail = body(response).get("data")
    if not detail:
        return
    response = api(
        "PATCH",
        f"/appStoreReviewDetails/{detail['id']}",
        json={
            "data": {
                "type": "appStoreReviewDetails",
                "id": detail["id"],
                "attributes": {
                    "contactFirstName": "App",
                    "contactLastName": "Support",
                    "contactPhone": "+819000000000",
                    "contactEmail": "support@example.com",
                    "notes": notes,
                },
            }
        },
    )
    print(f"Review notes updated: {response.status_code}")


def assign_build(version_id, build_id):
    response = api(
        "PATCH",
        f"/builds/{build_id}",
        json={"data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}},
    )
    print(f"Export compliance updated: {response.status_code}")

    response = api(
        "PATCH",
        f"/appStoreVersions/{version_id}/relationships/build",
        json={"data": {"type": "builds", "id": build_id}},
    )
    if response.status_code not in (200, 204):
        raise RuntimeError(f"Build assign failed {response.status_code}: {response.text[:500]}")
    print("Build assigned")


def cancel_blocking_submissions():
    for state in ("UNRESOLVED_ISSUES", "READY_FOR_REVIEW"):
        response = api("GET", f"/apps/{APP_ID}/reviewSubmissions?filter[state]={state}&limit=200")
        if response.status_code != 200:
            continue
        for submission in body(response).get("data", []):
            sid = submission["id"]
            cancel = api(
                "PATCH",
                f"/reviewSubmissions/{sid}",
                json={"data": {"type": "reviewSubmissions", "id": sid, "attributes": {"canceled": True}}},
            )
            print(f"Canceled submission {sid}: {cancel.status_code}")


def submit(version_id):
    response = api(
        "POST",
        "/reviewSubmissions",
        json={
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": "IOS"},
                "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
            }
        },
    )
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:500]}")
    submission_id = response.json()["data"]["id"]

    for attempt in range(10):
        response = api(
            "POST",
            "/reviewSubmissionItems",
            json={
                "data": {
                    "type": "reviewSubmissionItems",
                    "relationships": {
                        "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                        "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
                    },
                }
            },
        )
        print(f"Add review item {attempt + 1}: {response.status_code}")
        if response.status_code in (200, 201):
            break
        time.sleep(15)
    else:
        raise RuntimeError(f"Review item create failed: {response.text[:500]}")

    response = api(
        "PATCH",
        f"/reviewSubmissions/{submission_id}",
        json={"data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}},
    )
    if response.status_code != 200:
        raise RuntimeError(f"Review submit failed {response.status_code}: {response.text[:500]}")
    print(f"Submitted for review: {submission_id} / {response.json()['data']['attributes']['state']}")


def main():
    version_id, state = find_version()
    print(f"Version {version_id}: {state}")
    if state in ("WAITING_FOR_REVIEW", "IN_REVIEW", "READY_FOR_SALE"):
        print("Already submitted or on sale.")
        return
    build_id = wait_for_build()
    cancel_blocking_submissions()
    time.sleep(20)
    assign_build(version_id, build_id)
    set_review_notes(version_id)
    submit(version_id)


if __name__ == "__main__":
    main()
