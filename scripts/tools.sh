#! /bin/bash

curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod 755 msfinstall 
./msfinstall


# Install network analyzers
apt install -y kali-linux-default
apt install -y wireshark
apt install -y burpsuite
apt install -y nmap
apt install -y zaproxy
apt install -y sqlmap

# Browsers
apt install -y firefox-esr

# Install puppeteer for single page application analysis
apt install -y npm
npm install playwright
npx playwright install

# Install fuzzer
apt install -y ffuf
apt install -y gobuster
apt install -y hydra
apt install -y wfuzz 
apt install -y john
apt install -y hashcat

# File analyzers
apt install -y file
apt install -y jq
apt install -y libimage-exiftool-perl
apt install -y binwalk

wget https://github.com/syvaidya/openstego/releases/download/openstego-0.8.6/openstego-0.8.6.zip
unzip openstego-0.8.6.zip -d /usr/local/bin
mv /usr/local/bin/openstego-0.8.6 /usr/local/bin/openstego
chmod +x /usr/local/bin/openstego/openstego.sh
apt install -y steghide

apt install -y sherlock
apt install -y oathtool
apt install -y keepassxc-full
apt install -y parallel
apt install -y openjdk-23-jdk
apt install -y p7zip-full

apt install -y sshpass

pip install --break-system-packages frida-tools

