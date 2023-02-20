#!/bin/bash
echo "Enter url: "
read url
while [ "$url" = "" ]
do
    echo "Example: random-url.com" 
    echo "Try again: "
    read url
done

echo ""
echo "Enter wordlist for SUBDOMAIN discovery or just press enter for default wordlist: "
echo "Default: /usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt"
read wordlist1
echo "Default set: ${wordlist1:=/usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt}"

echo ""
echo "Enter wordlist for DIRECTORY discovery or just press enter for default wordlist: "
echo "Default: /usr/share/seclists/Discovery/Web-Content/raft-large-directories-lowercase.txt"
read wordlist2
echo "Default set: ${wordlist2:=/usr/share/seclists/Discovery/Web-Content/raft-large-directories-lowercase.txt}"

echo ""
echo "Performing FFUF for subdomain discovery..."

ffuf -w $wordlist1 -u http://FUZZ.$url -H "User-Agent: Mozilla/5.0 (X11;Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" -mc all -fs 0 -t 10 -p "0.1-2.0" -s -o result-1 2>/dev/null 1>/dev/null

sed -i 's/"url"/\n/g' result-1
cat result-1 | cut -d '"' -f2 | grep "http" | grep -v "FUZZ" > .tmp1
echo "http://$url" >> .tmp1

echo ""
echo "Performing FEROXBUSTER for directory discovery..."

for i in $(cat .tmp1);
do
feroxbuster --url $i --thread 10 --scan-limit 1 --rate-limit 4 --random-agent --wordlist $wordlist2 --thorough --silent --insecure --redirects --output "result-2" 2>/dev/null 1>/dev/null;
echo -ne ".";
done
echo ""
echo "Making final adjustments..."

cat result-2 | awk 'NF>0' > .tmp2

touch SSWRecon-results.txt
echo "SUBDOMAINS" > SSWRecon-results.txt
cat .tmp1 >> SSWRecon-results.txt
echo "" >> SSWRecon-results.txt
echo "DIRECTORY LISTING" >> SSWRecon-results.txt
cat .tmp2 | grep "directory listing" | awk -F "listing: " '{print $2}' | cut -d "(" -f 1 >> SSWRecon-results.txt
echo "" >> SSWRecon-results.txt
echo "DIRECTORIES FOUND" >> SSWRecon-results.txt
cat result-2 | grep -v "MSG" >> SSWRecon-results.txt

echo ""
echo "...and we are done! Here is what we found:"
echo ""
echo "SUBDOMAINS:"
cat .tmp1
echo ""
echo "POSSIBLE DIRECTORY LISTING:"
cat .tmp2 | grep "directory listing" | awk -F "listing: " '{print $2}' | cut -d "(" -f 1
echo ""

rm -rf .tmp* result-*

echo "All results stored in SSWRecon-results"
