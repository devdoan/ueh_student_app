import urllib.request
import re

url = 'https://gemini.google.com/share/b94089d20aa5'
crawlers = [
    'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
    'Twitterbot/1.0',
    'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
    'WhatsApp/2.21.12.21 A'
]

for ua in crawlers:
    req = urllib.request.Request(url, headers={'User-Agent': ua})
    try:
        with urllib.request.urlopen(req) as resp:
            text = resp.read().decode('utf-8', errors='ignore')
            print(f'UA: {ua[:15]} - len: {len(text)}')
            og_desc = re.findall(r'<meta[^>]*property=[\"\']og:description[\"\'][^>]*content=[\"\']([^\"\']*)[\"\']', text)
            print('  og:description:', og_desc)
            desc = re.findall(r'<meta[^>]*name=[\"\']description[\"\'][^>]*content=[\"\']([^\"\']*)[\"\']', text)
            print('  description:', desc)
            title = re.findall(r'<title>([^<]*)</title>', text)
            print('  title:', title)
    except Exception as e:
        print('Error:', e)
