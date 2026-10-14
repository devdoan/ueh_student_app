import urllib.request
import re
import html as html_lib

url = 'https://gemini.google.com/share/b94089d20aa5?social_preview=false&skid=c0bd40c1-df10-4562-8d3b-28f638061b14'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
with urllib.request.urlopen(req) as resp:
    page_html = resp.read().decode('utf-8', errors='ignore')

with open('scratch/page.html', 'w', encoding='utf-8') as f:
    f.write(page_html)

chunks = re.findall(r'AF_initDataChunkQueue\.push\((.*?)\);', page_html, re.DOTALL)
print(f'Chunks found: {len(chunks)}')
for i, c in enumerate(chunks):
    print(f'Chunk {i}: len {len(c)}')
    with open(f'scratch/chunk_{i}.txt', 'w', encoding='utf-8') as f:
        f.write(c)

# also search for data-payload
payloads = re.findall(r'data-payload="([^"]+)"', page_html)
print(f'Payloads found: {len(payloads)}')
for i, p in enumerate(payloads):
    print(f'Payload {i}: len {len(p)}')
    with open(f'scratch/payload_{i}.txt', 'w', encoding='utf-8') as f:
        f.write(html_lib.unescape(p))
