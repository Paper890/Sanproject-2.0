#!/bin/bash

# Fetch date from server
dateFromServer=$(curl -s --head https://google.com/ | grep ^Date: | sed 's/Date: //g')
biji=$(date -d "$dateFromServer" +"%Y-%m-%d")

# Variables
REPO1="<your_repo_url>"
REPO="<your_repo_url>"
CDNF="<your_cdnf_url>"

# Download banner
wget -O /etc/banner ${REPO1}config/banner >/dev/null 2>&1
chmod +x /etc/banner
clear

# Colors
red='\e[1;31m'
green='\e[0;32m'
yell='\e[1;33m'
tyblue='\e[1;36m'
NC='\e[0m'

# Functions
purple() { echo -e "\\033[35;1m${*}\\033[0m"; }
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
red() { echo -e "\\033[31;1m${*}\\033[0m"; }

# Check if running as root
if [ "${EUID}" -ne 0 ]; then
    echo "You need to run this script as root"
    exit 1
fi

# Check if system is OpenVZ
if [ "$(systemd-detect-virt)" == "openvz" ]; then
    echo "OpenVZ is not supported"
    exit 1
fi

# Set local IP
localip=$(hostname -I | cut -d' ' -f1)
hst=$(hostname)
dart=$(grep -w "$(hostname)" /etc/hosts | awk '{print $2}')
if [[ "$hst" != "$dart" ]]; then
    echo "$localip $(hostname)" >> /etc/hosts
fi

# Create directories
mkdir -p /etc/xray
mkdir -p /etc/ssnvpn
mkdir -p /etc/ssnvpn/theme
mkdir -p /var/lib/ssnvpn-pro >/dev/null 2>&1
echo "IP=" > /var/lib/ssnvpn-pro/ipvps.conf

# System setup
echo -e "[ ${tyblue}NOTES${NC} ] Before we go.. "
sleep 1
echo -e "[ ${tyblue}NOTES${NC} ] I need check your headers first.."
sleep 2
echo -e "[ ${green}INFO${NC} ] Checking headers"
sleep 1

# Check and install headers
totet=$(uname -r)
REQUIRED_PKG="linux-headers-$totet"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed")

if [ "" = "$PKG_OK" ]; then
    echo -e "[ ${yell}WARNING${NC} ] Try to install $REQUIRED_PKG..."
    apt-get update && apt-get --yes install $REQUIRED_PKG
else
    echo -e "[ ${green}INFO${NC} ] $REQUIRED_PKG is already installed"
fi

# Timezone and IPv6 settings
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1

# Install necessary packages
echo -e "[ ${green}INFO${NC} ] Preparing the install file"
apt install git curl -y >/dev/null 2>&1

# Install gotop
gotop_latest=$(curl -s https://api.github.com/repos/xxxserxxx/gotop/releases/latest | grep tag_name | sed -E 's/.*"v(.*)".*/\1/')
gotop_link="https://github.com/xxxserxxx/gotop/releases/download/v${gotop_latest}/gotop_v${gotop_latest}_linux_amd64.deb"
curl -sL "$gotop_link" -o /tmp/gotop.deb
dpkg -i /tmp/gotop.deb >/dev/null 2>&1

# Install BBR Plus
wget -qO /tmp/bbr.sh "${REPO}server/bbr.sh"
chmod +x /tmp/bbr.sh && bash /tmp/bbr.sh

# Install dependencies
wget -q https://raw.githubusercontent.com/Paper890/sandi/main/dependencies.sh
chmod +x dependencies.sh
./dependencies.sh
rm dependencies.sh

# Domain setup
echo -e "${red}    ♦️${NC} ${green} CUSTOM SETUP DOMAIN VPS     ${NC}"
echo -e "${red}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m${NC}"
echo "1. Use Domain From Script / Gunakan Domain Dari Script"
echo "2. Choose Your Own Domain / Pilih Domain Sendiri"
echo -e "${red}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m${NC}"
read -rp "Choose Your Domain Installation : " dom

if test $dom -eq 1; then
    apt install jq curl -y
    wget -q -O /root/cf "${CDNF}/cf"
    chmod +x /root/cf
    bash /root/cf | tee /root/install.log
elif test $dom -eq 2; then
    read -rp "Enter Your Domain : " domen
    echo $domen | tee /root/domain /root/scdomain /etc/xray/domain /etc/xray/scdomain
    echo "IP=$domen" > /var/lib/ssnvpn-pro/ipvps.conf
else
    echo "Not Found Argument"
    exit 1
fi

echo -e "${green}Done!${NC}"
sleep 2

# Install services
wget https://raw.githubusercontent.com/Paper890/sandi/main/ssh/ssh-vpn.sh && chmod +x ssh-vpn.sh && ./ssh-vpn.sh
wget https://raw.githubusercontent.com/Paper890/sandi/main/xray/ins-xray.sh && chmod +x ins-xray.sh && ./ins-xray.sh
wget https://raw.githubusercontent.com/Paper890/sandi/main/backup/set-br.sh && chmod +x set-br.sh && ./set-br.sh
wget https://raw.githubusercontent.com/Paper890/sandi/main/websocket/insshws.sh && chmod +x insshws.sh && ./insshws.sh
wget https://raw.githubusercontent.com/Paper890/sandi/main/websocket/nontls.sh && chmod +x nontls.sh && ./nontls.sh
wget https://raw.githubusercontent.com/Paper890/sandi/main/update/update.sh && chmod +x update.sh && ./update.sh

# Set profile
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
cat > /root/.profile << 'END'
# ~/.profile: executed by Bourne-compatible login shells.

if [ "$BASH" ]; then
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi
fi

mesg n || true
clear
menu
END
chmod 644 /root/.profile

# Clear unnecessary files
rm /root/cf.sh >/dev/null 2>&1
rm /root/setup.sh >/dev/null 2>&1
rm /root/insshws.sh 
rm /root/nontls.sh

# Log installation details
serverV=$(curl -sS https://raw.githubusercontent.com/Paper890/sandi/main/version)
echo $serverV > /opt/.ver
curl -sS ifconfig.me > /etc/myipvps

# Display installation details
cat << EOF
=====================-[ AutoScript Detail ]-====================
------------------------------------------------------------

>>> Service & Port
- OpenSSH                 : 22
- SSH Websocket           : 80
- SSH SSL Websocket       : 443
- SSH NON-SSL Websocket   : 80, 8880
- SLOWDNS                 : 5300 [OFF]
- Stunnel4                : 447, 777
- Dropbear                : 109, 143
- Badvpn                  : 7100-7900
- Nginx                   : 81
- XRAY  Vmess TLS         : 443
- XRAY  Vmess None TLS    : 80
- XRAY  Vless TLS         : 443
- XRAY  Vless None TLS    : 80
- Trojan GRPC             : 443
- Trojan WS               : 443
- Sodosok WS/GRPC         : 443

>>> Server Information & Other Features
- Timezone                : Asia/Jakarta (GMT +7)
- Fail2Ban                : [ON]
- Dflate                  : [ON]
- IPtables                : [ON]
- IPv6                    : [OFF]
- Autobackup Data
- AutoKill Multi Login User
- Auto Delete Expired Account
- Fully automatic script
- VPS settings
- Admin Control
- Restore Data
- Full Orders For Various Services
===============-[ MOD By SAN ]-===============

EOF

# Clear history
history -c

# Calculate installation time
secs_to_human() {
    echo "Installation time: $(( $1 / 3600 )) hours $(( ($1 / 60) % 60 )) minutes $(( $1 % 60 )) seconds"
}
secs_to_human "$(($(date +%s) - ${start}))" | tee -a log-install.txt

# Prompt for reboot
echo -ne "[ ${yell}WARNING${NC} ] Do you want to reboot now? (y/n)? "
read answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    reboot
else
    exit 0
fi
