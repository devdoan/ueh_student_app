import urllib.request
import urllib.parse
import re
import json

with open('scratch/page.html', 'r', encoding='utf-8') as f:
    html = f.read()

# Extract WIZ_global_data
m = re.search(r'window\.WIZ_global_data = (\{.*?\});', html)
if m:
    wiz = json.loads(m.group(1))
    print('WIZ keys:', list(wiz.keys()))
    at = wiz.get('SNlM0e', '')
    fdr = wiz.get('FdrFJe', '')
    print('SNlM0e (at):', at)
    print('FdrFJe:', fdr)

# Let's search for "b94089d20aa5" in the whole html
lines = html.splitlines()
for idx, line in enumerate(lines):
    if 'b94089d20aa5' in line:
        print(f'Line {idx}: {line[:300]}...')
