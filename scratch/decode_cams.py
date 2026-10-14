import base64
import re

with open('scratch/page.html', 'r', encoding='utf-8') as f:
    text = f.read()

# Find base64 strings starting with CAMS
matches = re.findall(r'\"(CAMS[a-zA-Z0-9_\-=]+)\"', text)
print(f'Found {len(matches)} CAMS tokens')
for idx, m in enumerate(matches):
    print(f'Token {idx}: len {len(m)}')
    # Try urlsafe b64decode
    pad = len(m) % 4
    if pad:
        m_pad = m + ('=' * (4 - pad))
    else:
        m_pad = m
    try:
        decoded = base64.urlsafe_b64decode(m_pad)
        # Check printable strings in decoded
        printable = re.findall(rb'[\x20-\x7e\xc0-\xff]{4,}', decoded)
        print(f'Token {idx} printable count: {len(printable)}')
        for p in printable:
            try:
                s = p.decode('utf-8')
                if len(s) > 5:
                    print('   ', s)
            except:
                pass
    except Exception as e:
        print(f'Error decoding {idx}:', e)
