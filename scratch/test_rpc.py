import re
with open('scratch/page.html', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's search for "b94089d20aa5" or "skid" or "c0bd40c1"
print('skid in text:', 'c0bd40c1' in text)
# Look at all occurrences of c0bd40c1
for m in re.finditer(r'c0bd40c1', text):
    start = max(0, m.start() - 300)
    end = min(len(text), m.end() + 300)
    print('--- skid occurrence ---')
    print(text[start:end])
