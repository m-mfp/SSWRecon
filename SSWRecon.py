#!/usr/share/python
import os,json

url = input("url: ")
wordlist = input("wordlist for subdomain discovery: ")

print("\nPerforming FFUF for host discovery...")
os.system(f'ffuf -w {wordlist} -u http://FUZZ.{url} -H "User-Agent: Mozilla/5.0" -mc all -fs 0 -t 10 -p "0.1-2.0" -s -o result-1')
with open('result-1','r') as f:
        data = json.loads(f.read())
        directory = input("wordlist for directory listing: ")
        print("\nCatching results and perfoming directory discovery...")
        os.system(f'feroxbuster --url http://{url} --threads 10 --scan-limit 1 --rate-limit 4 --random-agent --wordlist {wordlist} --silent --output "result-2" 2>/dev/null')
        for i in data['results']:
                urls = i['url']
                os.system(f'feroxbuster --url {urls} --threads 10 --scan-limit 1 --rate-limit 4 --random-agent --wordlist {wordlist} --silent --output "result-2" 2>/dev/null')
                #os.system(f'feroxbuster --url {urls} --threads 10 --scan-limit 1 --rate-limit 4 --random-agent --redirects --insecure --wordlist {wordlist} --thorough --output "result-2"')
                os.system('And we are finally done... results recorded in "result-1" and "result-2"')
f.close()