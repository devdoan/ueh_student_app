import urllib.request
import re

# Fetch ChatNodeView or chatGenerationManager from the importmap
url = 'https://www.gstatic.com/bg3/boq-bard-web/full/client/assets/en/chatGenerationManager-BfvqGOX8.js'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req) as resp:
        code = resp.read().decode('utf-8', errors='ignore')
    print('chatGen length:', len(code))
    # search for rpc / share
    matches = re.findall(r'[a-zA-Z0-9_$]+\.batchexecute|[a-zA-Z0-9_$]+\(\"[a-zA-Z0-9]{5,7}\"', code)
    print('Matches:', matches[:10])
except Exception as e:
    print('Error:', e)
