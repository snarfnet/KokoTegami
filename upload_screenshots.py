#!/usr/bin/env python3
"""Upload screenshots for KokoTegami to ASC"""
import jwt, time, requests, os, hashlib

key_id = "WDXGY9WX55"
issuer_id = "2be0734f-943a-4d61-9dc9-5d9045c46fec"
KEY_PATH = os.path.expanduser("~/Downloads/AuthKey_WDXGY9WX55.p8")
with open(KEY_PATH) as f:
    pk = f.read()

APP_ID = "6767550479"
DISPLAY_TYPE = "APP_IPHONE_67"
SS_DIR = os.path.join(os.path.dirname(__file__), "screenshots_new")
SS_FILES = [os.path.join(SS_DIR, f"kokotegami_{i}.png") for i in range(1, 6)]

def get_token():
    payload = {"iss": issuer_id, "iat": int(time.time()), "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, pk, algorithm="ES256", headers={"kid": key_id, "typ": "JWT"})

def h():
    return {"Authorization": "Bearer " + get_token(), "Content-Type": "application/json"}

# Get version
r = requests.get(f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS", headers=h())
ver_id = r.json()["data"][0]["id"]
print(f"Version: {ver_id}")

# Get localizations
r = requests.get(f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{ver_id}/appStoreVersionLocalizations", headers=h())
locs = {loc["attributes"]["locale"]: loc["id"] for loc in r.json().get("data", [])}
print(f"Locales: {list(locs.keys())}")

def upload_to_locale(locale, loc_id):
    print(f"\n=== {locale} ===")
    r = requests.get(f"https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets", headers=h())
    set_id = None
    for s in r.json().get("data", []):
        if s["attributes"]["screenshotDisplayType"] == DISPLAY_TYPE:
            set_id = s["id"]
            break

    if set_id:
        r = requests.get(f"https://api.appstoreconnect.apple.com/v1/appScreenshotSets/{set_id}/appScreenshots", headers=h())
        for ss in r.json().get("data", []):
            requests.delete(f"https://api.appstoreconnect.apple.com/v1/appScreenshots/{ss['id']}", headers=h())
        print("  Cleared old screenshots")
    else:
        r = requests.post("https://api.appstoreconnect.apple.com/v1/appScreenshotSets", headers=h(), json={
            "data": {"type": "appScreenshotSets",
                     "attributes": {"screenshotDisplayType": DISPLAY_TYPE},
                     "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc_id}}}}
        })
        set_id = r.json()["data"]["id"]
        print(f"  Created set: {set_id}")

    for filepath in SS_FILES:
        if not os.path.exists(filepath):
            print(f"  NOT FOUND: {filepath}")
            continue
        filename = os.path.basename(filepath)
        filesize = os.path.getsize(filepath)
        with open(filepath, "rb") as f:
            file_data = f.read()
        checksum = hashlib.md5(file_data).hexdigest()
        print(f"  Uploading: {filename}")

        r = requests.post("https://api.appstoreconnect.apple.com/v1/appScreenshots", headers=h(), json={
            "data": {"type": "appScreenshots",
                     "attributes": {"fileName": filename, "fileSize": filesize},
                     "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}
        })
        if r.status_code not in (200, 201):
            print(f"    Reserve failed: {r.status_code}")
            continue
        ss_data = r.json()["data"]
        ss_id = ss_data["id"]
        for op in ss_data["attributes"]["uploadOperations"]:
            h2 = {rh["name"]: rh["value"] for rh in op["requestHeaders"]}
            chunk = file_data[op["offset"]:op["offset"] + op["length"]]
            requests.put(op["url"], headers=h2, data=chunk)
        r3 = requests.patch(f"https://api.appstoreconnect.apple.com/v1/appScreenshots/{ss_id}", headers=h(), json={
            "data": {"type": "appScreenshots", "id": ss_id,
                     "attributes": {"sourceFileChecksum": checksum, "uploaded": True}}
        })
        print(f"    Commit: {r3.status_code}")

for locale, loc_id in locs.items():
    upload_to_locale(locale, loc_id)

print("\nDone!")
