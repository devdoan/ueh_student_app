import urllib.request
import re

# In page.html, find the main JS script url
with open('scratch/page.html', 'r', encoding='utf-8') as f:
    html = f.read()

m = re.search(r'https://gemini\.gstatic\.com/_/mss/boq-gemini-web-uiserver/_/js/k=[^"]+', html)
if m:
    js_url = m.group(0)
    print('JS URL:', js_url)
    req = urllib.request.Request(js_url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as resp:
        js_code = resp.read().decode('utf-8', errors='ignore')
    print('JS length:', len(js_code))
    
    # search for "/share" in JS
    share_matches = re.findall(r'[^;"\']{0,50}/share[^;"\']{0,50}', js_code)
    print('Share occurrences:', len(share_matches))
    for s in share_matches[:10]:
        print('   ', s)
