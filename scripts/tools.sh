#! /bin/bash


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
wget https://github.com/syvaidya/openstego/releases/download/openstego-0.8.6/openstego-0.8.6.zip
unzip openstego-0.8.6.zip -d /usr/local/bin
mv /usr/local/bin/openstego-0.8.6 /usr/local/bin/openstego
chmod +x /usr/local/bin/openstego/openstego.sh


apt install -y sherlock
apt install -y oathtool
apt install -y keepassxc-full
apt install -y parallel


