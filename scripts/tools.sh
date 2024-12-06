#! /bin/bash


# Install network analyzers
apt install -y kali-linux-default
apt install -y wireshark
apt install -y burpsuite
apt install -y nmap

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

# File analyzers
apt install -y file
apt install -y jq
