with open('scratch/page.html', 'r', encoding='utf-8') as f:
    text = f.read()

pos = text.find('b94089d20aa5')
start = max(0, pos - 5000)
end = min(len(text), pos + 10000)
with open('scratch/around_share.txt', 'w', encoding='utf-8') as f:
    f.write(text[start:end])

print('Written around_share.txt')
