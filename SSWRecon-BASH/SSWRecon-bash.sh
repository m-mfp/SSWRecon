#!/bin/bash
# Requesting url and making sure there is an input
echo "Enter url"
echo "Example: https://example.com"
read fuzzurl
while [ "$fuzzurl" = "" ]
do
    echo "Need input, try again" 
    echo "Example: https://example.com"
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
echo "---------- Performing FFUF for subdomain discovery with ${wordlist2:=/usr/share/seclists/Discovery/Web-Content/raft-large-directories-lowercase.txt} ----------"
ffuf -w $wordlist1 -u $url -H "User-Agent: Mozilla/5.0 (X11;Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" -t 6 -timeout 5 -p "1.0-2.0" -rate 4 -s -of csv -o .tmp-ffuf

# Looking for subdomains without DNS records
echo "---------- Looking for subdomains without DNS records ----------"
ffuf -u $fuzzurl -H "Host: FUZZ.$post" -w fakesub.txt -H "User-Agent: Mozilla/5.0 (X11;Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" -p "1.0-2.0" -s -of csv -o .tmp 1>/dev/null

ffuf -u $fuzzurl -H "Host: FUZZ.$post" -w wordlist -H "User-Agent: Mozilla/5.0 (X11;Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" -t 6 -timeout 5 -p "1.0-2.0" -rate 4 -mc all -s -of csv -fs $(cut -d "," -f 6 .tmp | tail -n +2) -or -o .tmp-ffuf2 2>/dev/null

# Filtering results from ffuf
if test -f .tmp-ffuf2; then
    cat .tmp-ffuf2 >> .tmp-ffuf
    tail -n +2 .tmp-ffuf | cut -d "," -f 2 >> .tmp-ffuf3
    sort -u .tmp-ffuf3 > .tmp-ffuf
    rm -rf .tmp-ffuf2 .tmp-ffuf3
else
    echo "Couldn't find subdomains without DNS records"
    tail -n +2 .tmp-ffuf | cut -d "," -f 2 > .tmp-ffuf3
    sort -u .tmp-ffuf3 > .tmp-ffuf
    rm -rf .tmp-ffuf3
fi

# Performing feroxbuster with filtered results from ffuf
echo ""
echo "---------- Performing FEROXBUSTER for directory discovery with ${wordlist1:=/usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt} ----------"
echo "This may take a loooong time..."
echo ""

touch .tmp-ferox
for u in $(cat .tmp-ffuf);
do
feroxbuster --url $u --wordlist $wordlist2 --threads 20 --scan-limit 2 --rate-limit 6 --random-agent --collect-extensions --collect-backups --collect-words --redirects --insecure 2>/dev/null --output ".tmp-ferox";
done

# Filtered results from feroxbuster
cat .tmp-ferox | awk -F "c " '{print $2}' | awk 'NF>0' > .tmp

echo ""
echo "Making final adjustments..."

echo "---------------------------- DIRECTORY LISTING ----------------------------" > SSWRecon-results.txt
cat .tmp-ferox | grep directory | cut -d " " -f 12 >> SSWRecon-results.txt
echo "" >> SSWRecon-results.txt
echo "---------------------------- DIRECTORIES FOUND ----------------------------" >> SSWRecon-results.txt
for h in $(cat .tmp-ffuf);do cut -d " " -f 1 .tmp | grep $h >> SSWRecon-results.txt ;echo " " >> SSWRecon-results.txt;done

rm -rf .tmp*

echo "We are finally done!"
echo "All results stored in SSWRecon-results"