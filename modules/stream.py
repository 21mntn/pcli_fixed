#!/usr/bin/env python3
"""Resolve a playable HLS url for a pornhub viewkey.

Two traps live here:

* The desktop page hands out CDN tokens (?h=..&e=..&f=1) that authorise the
  m3u8 but not its segments, so playback dies a second after it starts. The
  mobile page hands out tokens that work end to end.
* The CDN ties those tokens to the user agent that fetched the page, so the
  player has to send the same one — print_ua() hands it to the caller.

Prints a verified master playlist url on stdout, nothing on failure.
"""

import json
import re
import sys

import requests

UA = ("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
      "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1")
COOKIES = {"platform": "mobile", "accessAgeDisclaimerPH": "1", "age_verified": "1"}
PAGE = "https://www.pornhub.com/view_video.php?viewkey=%s"


def session():
    s = requests.Session()
    s.headers.update({"User-Agent": UA, "Referer": "https://www.pornhub.com/"})
    s.cookies.update(COOKIES)
    return s


def media_definitions(sess, viewkey):
    r = sess.get(PAGE % viewkey, timeout=20)
    r.raise_for_status()
    m = re.search(r'mediaDefinitions"\s*:\s*(\[.*?\}\])', r.text, re.S)
    if not m:
        return []
    try:
        return json.loads(m.group(1))
    except ValueError:
        return []


def candidates(defs, max_height):
    """Playable masters, best-fitting quality first."""
    found = []
    for d in defs:
        url = d.get("videoUrl") or ""
        if "master.m3u8" not in url:
            continue
        try:
            height = int(d.get("quality") or d.get("height") or 0)
        except (TypeError, ValueError):
            height = 0
        found.append((height, url))

    under = sorted((f for f in found if not max_height or f[0] <= max_height),
                   key=lambda f: -f[0])
    over = sorted((f for f in found if max_height and f[0] > max_height),
                  key=lambda f: f[0])
    return [url for _, url in under + over]


def join(parent, entry):
    """Resolve a playlist entry against the playlist it came from."""
    if entry.startswith("http"):
        return entry
    base, _, query = parent.partition("?")
    url = base.rsplit("/", 1)[0] + "/" + entry
    if "?" not in entry and query:
        url += "?" + query
    return url


def serves_media(sess, url, depth=0):
    """Follow the playlist down to a real segment and check it downloads."""
    if depth > 2:
        return False
    try:
        r = sess.get(url, timeout=20)
        if r.status_code != 200:
            return False
        entries = [l.strip() for l in r.text.splitlines()
                   if l.strip() and not l.startswith("#")]
        if not entries:
            return False
        target = join(url, entries[0])
        if ".m3u8" in target:
            return serves_media(sess, target, depth + 1)
        seg = sess.get(target, timeout=25, stream=True)
        try:
            return seg.status_code == 200 and len(seg.raw.read(2048)) > 0
        finally:
            seg.close()
    except requests.RequestException:
        return False


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--user-agent":
        print(UA)
        return
    if len(sys.argv) < 2:
        sys.exit(2)

    viewkey = sys.argv[1]
    max_height = int(sys.argv[2]) if len(sys.argv) > 2 else 0

    sess = session()
    try:
        urls = candidates(media_definitions(sess, viewkey), max_height)
    except requests.RequestException as exc:
        print("error: %s" % exc, file=sys.stderr)
        sys.exit(1)

    for url in urls:
        if serves_media(sess, url):
            print(url)
            return
    sys.exit(1)


if __name__ == "__main__":
    main()
