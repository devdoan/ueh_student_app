import re

with open('scratch/whatsapp_text.html', 'r', encoding='utf-8') as f:
    text = f.read()

matches = [m.start() for m in re.finditer(r'Hướng dẫn tích hợp Firebase', text)]
with open('scratch/chat_snippets.txt', 'w', encoding='utf-8') as out:
    out.write(f'Matches: {len(matches)}\n')
    for i, pos in enumerate(matches):
        start = max(0, pos - 200)
        end = min(len(text), pos + 2500)
        out.write(f'\n=== MATCH {i} ===\n')
        out.write(text[start:end])
        out.write('\n')

print('Done writing chat_snippets.txt')
