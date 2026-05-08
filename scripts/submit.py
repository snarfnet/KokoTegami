#!/usr/bin/env python3
import jwt, time, requests, json, os, sys

KEY_ID = 'WDXGY9WX55'
ISSUER = '2be0734f-943a-4d61-9dc9-5d9045c46fec'
p8 = open(os.path.expanduser('~/.appstoreconnect/private_keys/AuthKey_WDXGY9WX55.p8')).read()
APP_ID = 'PLACEHOLDER'

def make_token():
    return jwt.encode({'iss': ISSUER, 'iat': int(time.time()), 'exp': int(time.time()) + 1200, 'aud': 'appstoreconnect-v1'}, p8, algorithm='ES256', headers={'kid': KEY_ID})

def api(method, path, payload=None):
    h = {'Authorization': f'Bearer {make_token()}', 'Content-Type': 'application/json'}
    kw = {}
    if payload:
        kw['json'] = payload
    return requests.request(method, f'https://api.appstoreconnect.apple.com/v1{path}', headers=h, **kw)

r = api('GET', f'/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=1')
versions = r.json().get('data', [])
if not versions:
    print('No version found')
    sys.exit(0)

VERSION_ID = versions[0]['id']
state = versions[0]['attributes']['appStoreState']
print(f'Version: {VERSION_ID} state={state}')

if state == 'READY_FOR_SALE':
    print('Already on sale')
    sys.exit(0)

build_num = sys.argv[1] if len(sys.argv) > 1 else None
if build_num:
    print(f'Waiting for build {build_num}...')
    for i in range(30):
        r = api('GET', f'/builds?filter[app]={APP_ID}&filter[version]={build_num}&filter[processingState]=VALID')
        builds = r.json().get('data', [])
        if builds:
            build_id = builds[0]['id']
            print(f'Build ready: {build_id}')
            r2 = api('PATCH', f'/appStoreVersions/{VERSION_ID}', {
                'data': {'type': 'appStoreVersions', 'id': VERSION_ID,
                         'relationships': {'build': {'data': {'type': 'builds', 'id': build_id}}}}
            })
            print(f'Attach build: {r2.status_code}')
            break
        time.sleep(30)
    else:
        print('Build not ready after 15 min')
        sys.exit(0)

print('Done')
