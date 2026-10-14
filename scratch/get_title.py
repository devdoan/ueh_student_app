import urllib.request
import re

url = 'https://gemini.google.com/share/b94089d20aa5'
req = urllib.request.Request(url, headers={'User-Agent': 'WhatsApp/2.21.12.21 A'})
with urllib.request.urlopen(req) as resp:
    raw = resp.read()
    text = raw.decode('utf-8', errors='ignore')

m = re.search(r'<title>([^<]*)</title>', text)
if m:
    with open('scratch/title.txt', 'w', encoding='utf-8') as f:
        f.write(m.group(1))
    print('Title written to scratch/title.txt')

# Search for any json or text blocks in text
with open('scratch/whatsapp_text.html', 'w', encoding='utf-8') as f:
    f.write(text)
