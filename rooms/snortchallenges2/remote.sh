#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
attack_ip="10.9.5.12"
result_folder="/work/results/"

# PRIOR TO USING THIS SCRIPT, COPY SSH PUBLIC KEY IN THE REMOTE SERVER .ssh/authorized_keys

# Parse arguments from flags
passphrase=""
while getopts p: flag
do
    case "${flag}" in
        p) passphrase=${OPTARG};;
    esac
done

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - BRUTE FORCE"

target_ip="10.10.52.219"

echo "drop tcp any any -> any 22 (msg: FILTER SSH TRAFFIC TO PORT 22; flow:stateless; sid: 100001; rev:1;)" > $result_folder/local.rules
echo "drop tcp any 22 -> any any (msg: FILTER SSH TRAFFIC FROM PORT 22; flow:stateless; sid: 100002; rev:1;)" >> $result_folder/local.rules
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 $result_folder/local.rules ubuntu@$target_ip:/home/ubuntu/local.rules
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "sudo snort -c /home/ubuntu/local.rules -q -Q --daq afpacket -i eth0:eth1 -A full" &
sleep 10
PROCESSES=$(sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "ps -ef | grep snort | grep /home/ubuntu/local.rules" | grep -v grep | awk '{print $2}')
if [ -n "$PROCESSES" ]; then
    sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "sudo kill $PROCESSES" 2> /dev/null
fi
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip:Desktop/flag.txt $result_folder/flag1.txt
FLAG=$(cat $result_folder/flag1.txt)
echo "--> Flag is '$FLAG'"

echo "2 - REVERSE SHELL"

target_ip="10.10.60.26"
#sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "sudo snort -d -e -i eth0" > $result_folder/realtime.log 2> /dev/null 

echo "drop tcp any any -> any 4444 (msg: FILTER REVERSE SHELL; sid: 100001; rev:1;)" > $result_folder/local.rules
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 $result_folder/local.rules ubuntu@$target_ip:/home/ubuntu/local.rules
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "sudo snort -c /home/ubuntu/local.rules -q -Q --daq afpacket -i eth0:eth1 -A full" &
sleep 10
PROCESSES=$(sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "ps -ef | grep snort | grep /home/ubuntu/local.rules" | grep -v grep | awk '{print $2}')
if [ -n "$PROCESSES" ]; then
    sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "sudo kill $PROCESSES" 2> /dev/null
fi
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip:Desktop/flag.txt $result_folder/flag2.txt
FLAG=$(cat $result_folder/flag2.txt)
echo "--> Flag is '$FLAG'"
