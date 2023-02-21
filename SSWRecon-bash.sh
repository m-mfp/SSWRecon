#!/bin/bash
# Requesting url and making sure there is an input
echo "Enter url"
echo "Example: https://businesscorp.com.br"
read fuzzurl
while [ "$fuzzurl" = "" ]
do
    echo "Need input, try again" 
    echo "Example: https://businesscorp.com.br"
    read fuzzurl
done

# Making url for ffuf
post=$(echo $fuzzurl | cut -d "/" -f 3)
pre=$(echo $fuzzurl | cut -d ":" -f 1)
url=$pre://FUZZ.$post

# Getting wordlist for ffuf
echo ""
echo "Enter wordlist for SUBDOMAIN discovery or just press enter for default wordlist: "
echo "Default: /usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt"
read wordlist1

# Getting wordlist for feroxbuster
echo ""
echo "Enter wordlist for DIRECTORY discovery or just press enter for default wordlist: "
echo "Default: /usr/share/seclists/Discovery/Web-Content/raft-large-directories-lowercase.txt"
read wordlist2

# Performing ffuf
echo ""
echo "------------------- Performing FFUF for subdomain discovery with ${wordlist2:=/usr/share/seclists/Discovery/Web-Content/raft-large-directories-lowercase.txt} -------------------"
ffuf -w $wordlist1 -u $url -H "User-Agent: Mozilla/5.0 (X11;Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" -t 4 -timeout 5 -p "1.0-2.0" -rate 2 -s -of csv -o .tmp-ffuf

# Performing feroxbuster with filtered results from ffuf
echo ""
echo "------------------- Performing FEROXBUSTER for directory discovery with ${wordlist1:=/usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt} -------------------"
echo "This may take a loooong time..."
echo ""

touch .tmp-ferox
for u in $(tail -n +2 .tmp-ffuf | cut -d "," -f 2);
do
feroxbuster --url $u --wordlist $wordlist2 --threads 10 --scan-limit 1 --rate-limit 4 --random-agent --collect-extensions --collect-backups --collect-words --redirects --insecure --quiet 2>/dev/null --output ".tmp-ferox";
done

# Filtered results from feroxbuster
cat .tmp-ferox | awk -F "c " '{print $2}' | awk 'NF>0' > .tmp3

echo ""
echo "Making final adjustments..."

touch SSWRecon-results.txt
echo "--------------------------------- DIRECTORY LISTING ---------------------------------" >> SSWRecon-results.txt
cat .tmp-ferox | grep directory | cut -d " " -f 12 >> SSWRecon-results.txt
echo "" >> SSWRecon-results.txt
echo "--------------------------------- DIRECTORIES FOUND ---------------------------------" >> SSWRecon-results.txt
for h in $(tail -n +2 .tmp-ffuf | cut -d "," -f 2);do grep $h .tmp3 >> SSWRecon-results.txt;echo " " >> SSWRecon-results.txt;done

rm -rf .tmp*

echo "We are finally done!"
echo "All results stored in SSWRecon-results"