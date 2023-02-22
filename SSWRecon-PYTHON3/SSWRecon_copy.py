#!/usr/share/python
import os,json

url = input("url: ")
wordlist = input("wordlist: ")

print("\nPerforming FFUF for host discovery...")
os.system(f'ffuf -w {wordlist} -u http://FUZZ.{url} -H "User-Agent: Mozilla/5.0" -mc all -fs 0 -t 10 -p "0.1-2.0" -s -o result-1')
with open('result-1','r') as f:
        data = json.loads(f.read())
        print("Catching results and perfoming directory discovery...")
        for i in data['results']:
                print(i['url'])
f.close()
