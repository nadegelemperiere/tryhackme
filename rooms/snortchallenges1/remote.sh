#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.78.172"
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

echo "2 - WRITING IDS RULES HTTP"
echo "alert tcp any 80 <> any 80  (msg: "DETECT ALL TCP PACKETS FROM PORT 80 TO PORT 80"; sid: 100001; rev:1;)" > $result_folder/local.rules
echo "alert tcp any 80 -> any !80  (msg: "DETECT ALL TCP PACKETS FROM PORT 80 AND NOT TO PORT 80"; sid: 100002; rev:1;)" >> $result_folder/local.rules
echo "alert tcp any !80 -> any 80  (msg: "DETECT ALL TCP PACKETS NOT FROM PORT 80 AND TO PORT 80"; sid: 100003; rev:1;)" >> $result_folder/local.rules
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 $result_folder/local.rules ubuntu@$target_ip:/home/ubuntu/Desktop/Exercise-Files/TASK-2\ \(HTTP\)/local.rules
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "rm alert;snort -c /home/ubuntu/Desktop/Exercise-Files/TASK-2\ \(HTTP\)/local.rules -X -l . -A full -r /home/ubuntu/Desktop/Exercise-Files/TASK-2\ \(HTTP\)/mx-3.pcap" 2> /dev/null
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip:alert $result_folder/2.txt

NUMBER=$(cat $result_folder/2.txt | grep "DETECT ALL TCP PACKETS" |  wc -l)
echo "--> Number of detected packets is : $NUMBER"

FIRST_LINE=$(cat $result_folder/2.txt | grep -n "DETECT ALL TCP PACKETS" | head -n 63 | tail -1 | sed 's/:.*//')
DESTINATION=$(cat $result_folder/2.txt | head -n $(($FIRST_LINE+2)) | tail -1 | sed -n 's/.*-> \(.*\)/\1/p')
echo "--> Packet 63 destination is $DESTINATION"

FIRST_LINE=$(cat $result_folder/2.txt | grep -n "DETECT ALL TCP PACKETS" | head -n 64 | tail -1 | sed 's/:.*//')
ACK=$(cat $result_folder/2.txt | head -n $(($FIRST_LINE+4)) | tail -1 | sed -n 's/.*Ack: \(.*\)  Win.*/\1/p')
echo "--> Packet 64 ack number is '$ACK'"

FIRST_LINE=$(cat $result_folder/2.txt | grep -n "DETECT ALL TCP PACKETS" | head -n 62 | tail -1 | sed 's/:.*//')
SEQ=$(cat $result_folder/2.txt | head -n $(($FIRST_LINE+4)) | tail -1 | sed -n 's/.*Seq: \(.*\)  Ack.*/\1/p')
echo "--> Packet 62 seq number is '$SEQ'"

FIRST_LINE=$(cat $result_folder/2.txt | grep -n "DETECT ALL TCP PACKETS" | head -n 65 | tail -1 | sed 's/:.*//')
TTL=$(cat $result_folder/2.txt | head -n $(($FIRST_LINE+3)) | tail -1 | sed -n 's/.*TTL:\(.*\) TOS.*/\1/p')
echo "--> Packet 65 TTL is '$TTL'"
SOURCE=$(cat $result_folder/2.txt | head -n $(($FIRST_LINE+2)) | tail -1 | sed -n 's/.*325558 \(.*\):3372.*/\1/p')
echo "--> Packet 65 source is '$SOURCE'"
PORT=$(cat $result_folder/2.txt | head -n $(($FIRST_LINE+2)) | tail -1 | sed -n 's/.*145.254.160.237:\(.*\) ->.*/\1/p')
echo "--> Packet 65 port is '$PORT'"


echo "3 - WRITING IDS RULES FTP"
echo "alert tcp any any <> any 21  (msg: "DETECT ALL TCP PORT 21 TRAFFIC"; sid: 100001; rev:1;)" > $result_folder/local.rules
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 $result_folder/local.rules ubuntu@$target_ip:/home/ubuntu/Desktop/Exercise-Files/TASK-3\ \(FTP\)/local.rules
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "rm alert;snort -c /home/ubuntu/Desktop/Exercise-Files/TASK-3\ \(FTP\)/local.rules -l . -K ASCII -A full -r /home/ubuntu/Desktop/Exercise-Files/TASK-3\ \(FTP\)/ftp-png-gif.pcap" 2> /dev/null
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip:alert $result_folder/3.1.txt
sshpass -P assphrase -p $passphrase scp -r -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip:192.168.75.1 $result_folder/

NUMBER=$(cat $result_folder/3.1.txt | grep "DETECT ALL TCP PORT" | wc -l)
echo "--> Number of detected packets is : $NUMBER"

SECOND_LINE=$(cat $result_folder/192.168.75.1/TCP\:18157-21 | grep -n "Service" | sed 's/:.*//')
FIRST_LINE=$(($SECOND_LINE - 1))
SECOND_PART=$(cat $result_folder/192.168.75.1/TCP\:18157-21 | head -n $SECOND_LINE | tail -1 | sed -n 's/.*0A           \(.*\)../\1/p' | tr -d '\n')
FIRST_PART="$(cat $result_folder/192.168.75.1/TCP\:18157-21 | head -n $FIRST_LINE | tail -1 | sed -n 's/.*220\(.*\)/\1/p' | tr -d ' ' | tr -d '\n' | tr -d '\r\n')"
echo "--> Service is : $FIRST_PART $SECOND_PART"

echo "alert tcp any any <> any 21  (msg: "DETECT ALL FAILED FTP LOGIN"; content:\"cannot log in\";sid: 100001; rev:1;)" > $result_folder/local.rules
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 $result_folder/local.rules ubuntu@$target_ip:/home/ubuntu/Desktop/Exercise-Files/TASK-3\ \(FTP\)/local.rules
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "rm alert;snort -c /home/ubuntu/Desktop/Exercise-Files/TASK-3\ \(FTP\)/local.rules -l . -K ASCII -A full -r /home/ubuntu/Desktop/Exercise-Files/TASK-3\ \(FTP\)/ftp-png-gif.pcap" 2> /dev/null
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip:alert $result_folder/3.2.txt

NUMBER=$(cat $result_folder/3.2.txt | grep "DETECT ALL FAILED FTP LOGIN" | wc -l)
echo "--> Number of failed login is : $NUMBER"


echo "alert tcp any any <> any 21  (msg: "DETECT ALL SUCCESSFUL FTP LOGIN"; content:\"logged in\";sid: 100001; rev:1;)" > $result_folder/local.rules
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 $result_folder/local.rules ubuntu@$target_ip:/home/ubuntu/Desktop/Exercise-Files/TASK-3\ \(FTP\)/local.rules
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "rm alert;snort -c /home/ubuntu/Desktop/Exercise-Files/TASK-3\ \(FTP\)/local.rules -l . -K ASCII -A full -r /home/ubuntu/Desktop/Exercise-Files/TASK-3\ \(FTP\)/ftp-png-gif.pcap" 2> /dev/null
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip:alert $result_folder/3.3.txt

NUMBER=$(cat $result_folder/3.3.txt | grep "DETECT ALL SUCCESSFUL FTP LOGIN" | wc -l)
echo "--> Number of successful login is : $NUMBER"

echo "alert tcp any any <> any 21  (msg: "DETECT FTP LOGIN ATTEMPT WITHOUT PASSWORD YET"; content:\"331 Password\";sid: 100001; rev:1;)" > $result_folder/local.rules
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 $result_folder/local.rules ubuntu@$target_ip:/home/ubuntu/Desktop/Exercise-Files/TASK-3\ \(FTP\)/local.rules
shpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "rm alert;snort -c /home/ubuntu/Desktop/Exercise-Files/TASK-3\ \(FTP\)/local.rules -l . -K ASCII -A full -r /home/ubuntu/Desktop/Exercise-Files/TASK-3\ \(FTP\)/ftp-png-gif.pcap" 2> /dev/null
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip:alert $result_folder/3.4.txt

NUMBER=$(cat $result_folder/3.4.txt | grep "DETECT FTP LOGIN ATTEMPT WITHOUT PASSWORD YET" | wc -l)
echo "--> Number of valid usernames is : $NUMBER"

echo "alert tcp any any <> any 21  (msg: "DETECT FTP LOGIN ATTEMPT WITH ADMINISTRATOR"; content:\"331 Password required for admin\";sid: 100001; rev:1;)" > $result_folder/local.rules
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 $result_folder/local.rules ubuntu@$target_ip:/home/ubuntu/Desktop/Exercise-Files/TASK-3\ \(FTP\)/local.rules
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "rm alert;snort -c /home/ubuntu/Desktop/Exercise-Files/TASK-3\ \(FTP\)/local.rules -l . -K ASCII -A full -r /home/ubuntu/Desktop/Exercise-Files/TASK-3\ \(FTP\)/ftp-png-gif.pcap" 2> /dev/null
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip:alert $result_folder/3.5.txt

NUMBER=$(cat $result_folder/3.5.txt | grep "DETECT FTP LOGIN ATTEMPT WITH ADMINISTRATOR" | wc -l)
echo "--> Number of administrator login attempt is : $NUMBER"


echo "4 - WRITING IDS RULES PNG"
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "snort -X -A console -r /home/ubuntu/Desktop/Exercise-Files/TASK-4\ \(PNG\)/ftp-png-gif.pcap" > $result_folder/4.log 2> /dev/null

echo "alert tcp any any <> any any  (msg: "DETECT ALL PNG IMAGES"; content:\"PNG\"; sid: 100001; rev:1;)" > $result_folder/local.rules
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 $result_folder/local.rules ubuntu@$target_ip:/home/ubuntu/Desktop/Exercise-Files/TASK-4\ \(PNG\)/local.rules
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "rm alert;snort -c /home/ubuntu/Desktop/Exercise-Files/TASK-4\ \(PNG\)/local.rules -l . -K ASCII -A full -r /home/ubuntu/Desktop/Exercise-Files/TASK-4\ \(PNG\)/ftp-png-gif.pcap" 2> /dev/null
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip:alert $result_folder/4.1.txt

NUMBER=$(cat $result_folder/4.1.txt | grep "DETECT ALL PNG IMAGES" | wc -l)
echo "--> Number of detected png images is : $NUMBER"

echo "alert tcp any any <> any any  (msg: "DETECT ALL GIF IMAGES"; content:\"GIF\"; sid: 100001; rev:1;)" > $result_folder/local.rules
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 $result_folder/local.rules ubuntu@$target_ip:/home/ubuntu/Desktop/Exercise-Files/TASK-4\ \(PNG\)/local.rules
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "rm alert;snort -c /home/ubuntu/Desktop/Exercise-Files/TASK-4\ \(PNG\)/local.rules -l . -K ASCII -A full -r /home/ubuntu/Desktop/Exercise-Files/TASK-4\ \(PNG\)/ftp-png-gif.pcap" 2> /dev/null
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip:alert $result_folder/4.2.txt

NUMBER=$(cat $result_folder/4.2.txt | grep "DETECT ALL GIF IMAGES" | wc -l)
echo "--> Number of detected gif images is : $NUMBER"

echo "5 - WRITING IDS RULES TORRENT METAFILE"

sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "snort -X -A console -r /home/ubuntu/Desktop/Exercise-Files/TASK-5\ \(TorrentMetafile\)/torrent.pcap" > $result_folder/5.log 2> /dev/null

echo "alert tcp any any <> any any  (msg: "DETECT TORRENT"; content:\"application/x-bittorrent\"; sid: 100001; rev:1;)" > $result_folder/local.rules
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 $result_folder/local.rules ubuntu@$target_ip:/home/ubuntu/Desktop/Exercise-Files/TASK-5\ \(TorrentMetafile\)/local.rules
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "rm alert;snort -c /home/ubuntu/Desktop/Exercise-Files/TASK-5\ \(TorrentMetafile\)/local.rules -l . -K ASCII -A full -r /home/ubuntu/Desktop/Exercise-Files/TASK-5\ \(TorrentMetafile\)/torrent.pcap" 2> /dev/null
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip:alert $result_folder/5.1.txt

NUMBER=$(cat $result_folder/5.1.txt | grep "DETECT TORRENT" | wc -l)
echo "--> Number of detected torrent packets is : $NUMBER"

echo "6 - TROUBLESHOOTING RULE SYNTAX ERROR"


echo "7 - USING EXTERNAL RULES (MS17-010)"

sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "snort -X -A console -r /home/ubuntu/Desktop/Exercise-Files/TASK-7\ \(MS17-10\)/ms-17-010.pcap" > $result_folder/7.log 2> /dev/null

echo "alert tcp any any <> any any  (msg: "DETECT IPC"; content:\"IPC\$\"; sid: 100001; rev:1;)" > $result_folder/local.rules
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 $result_folder/local.rules ubuntu@$target_ip:/home/ubuntu/Desktop/Exercise-Files/TASK-7\ \(MS17-10\)/local-1.rules
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "rm alert;snort -c /home/ubuntu/Desktop/Exercise-Files/TASK-7\ \(MS17-10\)/local-1.rules -l . -K ASCII -A full -r /home/ubuntu/Desktop/Exercise-Files/TASK-7\ \(MS17-10\)/ms-17-010.pcap" 2> /dev/null
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip:alert $result_folder/7.txt

NUMBER=$(cat $result_folder/7.txt | grep "DETECT IPC" | wc -l)
echo "--> Number of detected packets is : $NUMBER"

echo "8 - USING EXTERNAL RULES (log4j)"

sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "snort -X -A console -r /home/ubuntu/Desktop/Exercise-Files/TASK-8\ \(Log4j\)/log4j.pcap" > $result_folder/8.log 2> /dev/null

sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "snort -X -A console -r /home/ubuntu/Desktop/Exercise-Files/TASK-8\ \(Log4j\)/log4j.pcap" > $result_folder/8.log 2> /dev/null
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "rm alert;snort -c /home/ubuntu/Desktop/Exercise-Files/TASK-8\ \(Log4j\)/local.rules -l . -K ASCII -A full -r /home/ubuntu/Desktop/Exercise-Files/TASK-8\ \(Log4j\)/log4j.pcap" 2> $result_folder/8.1.log
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip:alert $result_folder/8.1.txt

NUMBER=$(cat $result_folder/8.1.txt | grep "Exploit" | wc -l)
echo "--> Number of detected packets with ready to use ruleset is : $NUMBER"

UNIQUE=$(cat $result_folder/8.1.txt | grep Exploit | sort | uniq | wc -l)
echo "--> Number of rules triggered is : $UNIQUE"

echo "alert tcp any any <> any any  (msg: "DETECT LOG4J";dsize:770<>855; sid: 100001; rev:1;)" > $result_folder/local.rules
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 $result_folder/local.rules ubuntu@$target_ip:/home/ubuntu/Desktop/Exercise-Files/TASK-8\ \(Log4j\)/local-1.rules
sshpass -P assphrase -p $passphrase ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip "rm alert;snort -c /home/ubuntu/Desktop/Exercise-Files/TASK-8\ \(Log4j\)/local-1.rules -l . -K ASCII -A full -r /home/ubuntu/Desktop/Exercise-Files/TASK-8\ \(Log4j\)/log4j.pcap" 2> /dev/null
sshpass -P assphrase -p $passphrase scp -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ubuntu@$target_ip:alert $result_folder/8.2.txt

NUMBER=$(cat $result_folder/8.2.txt | grep "DETECT LOG4J" | wc -l)
echo "--> Number of detected packets is : $NUMBER"