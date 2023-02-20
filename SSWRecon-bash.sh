#!/bin/bash
echo "Enter url: "
read url
echo ""
echo "Enter wordlist for subdomain discovery: "
read wordlist1
echo ""
echo "Enter wordlist for directory discovery: "
read wordlist2
echo ""
echo "Performing FFUF for subdomain discovery..."

ffuf -w $wordlist1 -u http://FUZZ.$url -H "User-Agent: Mozilla/5.0" -mc all -fs 0 -t 10 -p "0.1-2.0" -s -o result-1

sed -i 's/"url"/\n/g' result-1
cat result-1 | cut -d '"' -f2 | grep "http" | grep -v "FUZZ" > .tmp1
echo "http://$url" >> .tmp1

echo "Performing FEROXBUSTER for directory discovery..."

for i in $(cat .tmp1);
do
feroxbuster --url $i --threads 10 --scan-limit 1 --rate-limit 4 --random-agent --wordlist $wordlist2 --silent --output "result-2";
done

echo "Making final adjustments..."

cat result-2 | awk 'NF>0' > .tmp2

touch SSWRecon-results.txt
echo "SUBDOMAINS" > SSWRecon-results.txt
cat .tmp1 >> SSWRecon-results.txt
echo "" >> SSWRecon-results.txt
echo "DIRECTORY LISTING" >> SSWRecon-results.txt
cat .tmp2 | grep "directory listing" | awk -F "heuristics " '{print $2}' | cut -d "(" -f 1 >> SSWRecon-results.txt
echo ""
echo "DIRECTORIES FOUND"
cat result-2 | grep -v "MSG" >> SSWRecon-results.txt

echo "...and we are done! Here is what we found:"
echo ""
echo "SUBDOMAINS:"
cat .tmp1
echo ""
echo "POSSIBLE DIRECTORY LISTING:"
cat .tmp2 | grep "directory listing" | awk -F "heuristics " '{print $2}' | cut -d "(" -f 1
echo ""

rm -rf .tmp* result-*

echo "All results stored in SSWRecon-results"