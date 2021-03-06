#!/bin/bash

# initialisasi var
OS=`uname -p`;
ether=`ifconfig | cut -c 1-8 | sort | uniq -u | grep venet0 | grep -v venet0:`
if [ "$ether" = "" ]; then
        ether=eth0
fi
#ether='ifconfig -a | sed 's/[ \t].*//;/^\(lo\|\)$/d' | grep -v venet0:';
MYIP=`curl -s ifconfig.me`;
MYIP2="s/xxxxxxxxx/$MYIP/g";

# go to root
cd

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service sshd restart

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.d/rc.local

# install wget and curl
yum -y install wget curl

# setting repo
wget http://script.fawzya.net/centos/app/epel-release-6-8.noarch.rpm
wget http://script.fawzya.net/centos/app/remi-release-6.rpm
rpm -Uvh epel-release-6-8.noarch.rpm
rpm -Uvh remi-release-6.rpm

if [ "$OS" == "x86_64" ]; then
  wget https://raw.githubusercontent.com/adammau2/script-vps/master/app/rpmforge.rpm
  rpm -Uvh rpmforge.rpm
else
  wget https://raw.githubusercontent.com/adammau2/script-vps/master/app/rpmforge.rpm
  rpm -Uvh rpmforge.rpm
fi

sed -i 's/enabled = 1/enabled = 0/g' /etc/yum.repos.d/rpmforge.repo
sed -i -e "/^\[remi\]/,/^\[.*\]/ s|^\(enabled[ \t]*=[ \t]*0\\)|enabled=1|" /etc/yum.repos.d/remi.repo
rm -f *.rpm


# remove unused
yum -y remove sendmail;
yum -y remove httpd;
yum -y remove cyrus-sasl;

# update
yum -y update

# install webserver
yum -y install nginx php-fpm php-cli
service nginx restart
service php-fpm restart
chkconfig nginx on
chkconfig php-fpm on

# install essential package
yum -y install iftop htop nmap bc nethogs openvpn vnstat ngrep mtr git zsh mrtg unrar rsyslog rkhunter mrtg net-snmp net-snmp-utils expect nano bind-utils
yum -y groupinstall 'Development Tools'
yum -y install cmake

# matiin exim
service exim stop
chkconfig exim off

# setting vnstat
vnstat -u -i $ether
echo "MAILTO=root" > /etc/cron.d/vnstat
echo "*/5 * * * * root /usr/sbin/vnstat.cron" >> /etc/cron.d/vnstat
sed -i "s/eth0/$ether/" /etc/sysconfig/vnstat
service vnstat restart
chkconfig vnstat on

# install screenfetch
cd
wget https://github.com/KittyKatt/screenFetch/raw/master/screenfetch-dev
mv screenfetch-dev /usr/bin/screenfetch
chmod +x /usr/bin/screenfetch
echo "clear" >> .bash_profile
echo "screenfetch" >> .bash_profile

# Install Webserver Port 81
yum install nginx php libapache2-mod-php php-fpm php-cli php-mysql php-mcrypt libxml-parser-perl -y
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/GegeEmbrie/autosshvpn/master/file/nginx.conf"
sed -i 's/www-data/nginx/g' /etc/nginx/nginx.conf
mkdir -p /home/vps/public_html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
rm /etc/nginx/conf.d/*
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/GegeEmbrie/autosshvpn/master/file/vps.conf"
sed -i 's/apache/nginx/g' /etc/php-fpm.d/www.conf
chmod -R +rx /home/vps
wget -O /home/vps/public_html/uptime.php "http://autoscript.kepalatupai.com/uptime.php1"
wget -O /home/vps/public_html/index.html "https://raw.githubusercontent.com/GegeEmbrie/autosshvpn/master/addons/index.html1"
service php-fpm restart
service nginx restart
chkconfig php-fpm on
chkconfig nginx on
cd

# OpenSSH Setting
sed -i '/#Port 22/a Port 22' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 143' /etc/ssh/sshd_config
sed -i 's/Port 22/Port 22/g' /etc/ssh/sshd_config
service sshd restart

# Install Dropbear
yum -y install dropbear
echo "OPTIONS=\"-p 109 -p 110 -p 443 -p 999\"" > /etc/sysconfig/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
service ssh restart
service dropbear restart
cd

chkconfig dropbear on

# install openvpn
wget -O /etc/openvpn/openvpn.tar "https://raw.githubusercontent.com/adammau2/script-vps/master/conf/openvpn-debian.tar"
cd /etc/openvpn/
tar xf openvpn.tar
wget -O /etc/openvpn/1194.conf "https://raw.githubusercontent.com/adammau2/script-vps/master/conf/1194-centos.conf"
if [ "$OS" == "x86_64" ]; then
  wget -O /etc/openvpn/1194.conf "https://raw.githubusercontent.com/adammau2/script-vps/master/conf/1194-centos64.conf"
fi
wget -O /etc/iptables.up.rules "https://raw.githubusercontent.com/adammau2/script-vps/master/conf/iptables.up.rules"
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.local
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.d/rc.local
MYIP=`curl icanhazip.com`;
MYIP2="s/xxxxxxxxx/$MYIP/g";
sed -i $MYIP2 /etc/iptables.up.rules;
sed -i 's/venet0/eth0/g' /etc/iptables.up.rules
iptables-restore < /etc/iptables.up.rules
sysctl -w net.ipv4.ip_forward=1
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
service openvpn restart
chkconfig openvpn on
cd

# configure openvpn client config
cd /etc/openvpn/
wget -O /etc/openvpn/1194-client.ovpn "https://raw.githubusercontent.com/adammau2/script-vps/master/openvpn.conf"
sed -i $MYIP2 /etc/openvpn/1194-client.ovpn;
PASS=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1`;
useradd -M -s /bin/false Adam
echo "Adam:$PASS" | chpasswd
echo "Adam" > pass.txt
echo "$PASS" >> pass.txt
tar cf client.tar 1194-client.ovpn pass.txt
cp client.tar /home/vps/public_html/
cp 1194-client.ovpn /home/vps/public_html/

# Install VNSTAT
yum install vnstat -y
cd /home/vps/public_html/
wget https://raw.githubusercontent.com/GegeEmbrie/autosshvpn/master/file/vnstat_php_frontend-1.5.1.tar.gz
tar xf vnstat_php_frontend-1.5.1.tar.gz
rm vnstat_php_frontend-1.5.1.tar.gz
mv vnstat_php_frontend-1.5.1 vnstat
cd vnstat
if [[ `ifconfig -a | grep "venet0"` ]]
then
cekvirt='OpenVZ'
elif [[ `ifconfig -a | grep "venet0:0"` ]]
then
cekvirt='OpenVZ'
elif [[ `ifconfig -a | grep "venet0:0-00"` ]]
then
cekvirt='OpenVZ'
elif [[ `ifconfig -a | grep "venet0-00"` ]]
then
cekvirt='OpenVZ'
elif [[ `ifconfig -a | grep "eth0"` ]]
then
cekvirt='KVM'
elif [[ `ifconfig -a | grep "eth0:0"` ]]
then
cekvirt='KVM'
elif [[ `ifconfig -a | grep "eth0:0-00"` ]]
then
cekvirt='KVM'
elif [[ `ifconfig -a | grep "eth0-00"` ]]
then
cekvirt='KVM'
fi
if [ $cekvirt = 'KVM' ]; then
	sed -i 's/eth0/eth0/g' config.php
	sed -i "s/\$iface_list = array('eth0', 'sixxs');/\$iface_list = array('eth0');/g" config.php
	sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
	sed -i 's/Internal/Internet/g' config.php
	sed -i '/SixXS IPv6/d' config.php
	cd
elif [ $cekvirt = 'OpenVZ' ]; then
	sed -i 's/eth0/venet0/g' config.php
	sed -i "s/\$iface_list = array('venet0', 'sixxs');/\$iface_list = array('venet0');/g" config.php
	sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
	sed -i 's/Internal/Internet/g' config.php
	sed -i '/SixXS IPv6/d' config.php
	cd
else
	cd
fi

# install mrtg
cd /etc/snmp/
wget -O /etc/snmp/snmpd.conf "http://script.hostingtermurah.net/repo/snmpd.conf"
wget -O /root/mrtg-mem.sh "http://script.hostingtermurah.net/repo/mrtg-mem.sh"
chmod +x /root/mrtg-mem.sh
service snmpd restart
chkconfig snmpd on
snmpwalk -v 1 -c public localhost | tail
mkdir -p /home/vps/public_html/mrtg
cfgmaker --zero-speed 100000000 --global 'WorkDir: /home/vps/public_html/mrtg' --output /etc/mrtg/mrtg.cfg public@localhost
curl "http://script.hostingtermurah.net/repo/mrtg.conf" >> /etc/mrtg.cfg
sed -i 's/WorkDir: \/var\/www\/mrtg/# WorkDir: \/var\/www\/mrtg/g' /etc/mrtg/mrtg.cfg
sed -i 's/# Options\[_\]: growright, bits/Options\[_\]: growright/g' /etc/mrtg/mrtg.cfg
indexmaker --output=/home/vps/public_html/mrtg/index.html /etc/mrtg/mrtg.cfg
echo "0-59/5 * * * * root env LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg" > /etc/cron.d/mrtg
LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg
LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg
LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg
cd

# Install Fail2Ban
yum -y install fail2ban;service fail2ban restart

# Install BadVPN
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/GegeEmbrie/autosshvpn/master/file/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/GegeEmbrie/autosshvpn/master/file/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.d/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# Install Squid
wget https://raw.githubusercontent.com/GegeEmbrie/autosshvpn/master/file/squid.sh && bash squid.sh

# install webmin
cd
wget "http://script.hostingtermurah.net/repo/webmin-1.801-1.noarch.rpm"
yum -y install perl perl-Net-SSLeay openssl perl-IO-Tty
rpm -i webmin-1.801-1.noarch.rpm;
rm webmin-1.801-1.noarch.rpm
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
service webmin restart
chkconfig webmin on

# Addons
wget https://raw.githubusercontent.com/GegeEmbrie/autosshvpn/master/addons/addons.sh && sh addons.sh
sed -i 's/1000/500/g' /usr/bin/akun

# download script
cd
wget -O /usr/bin/user-trial "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/user-trial"
wget -O /usr/bin/rubah-tanggal "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/rubah-tanggal"
wget -O /usr/bin/next "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/next"
wget -O /usr/bin/auto-reboot "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/auto-reboot"
wget -O /usr/bin/bench-network "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/bench-network"
wget -O /usr/bin/speedtest "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/speedtest"
wget -O /usr/bin/ps-mem "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/ps-mem"
wget -O /usr/bin/autokill "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/autokill"
wget -O /usr/bin/dropmon "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/dropmon"
wget -O /usr/bin/menu "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/menu"
wget -O /usr/bin/user-active-list "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/user-active-list"
wget -O /usr/bin/user-add "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/user-add"
wget -O /usr/bin/user-add-pptp "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/user-add-pptp"
wget -O /usr/bin/user-del "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/user-del"
wget -O /usr/bin/disable-user-expire "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/disable-user-expire"
wget -O /usr/bin/delete-user-expire "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/delete-user-expire"
wget -O /usr/bin/banned-user "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/banned-user"
wget -O /usr/bin/unbanned-user "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/unbanned-user"
wget -O /usr/bin/user-expire-list "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/user-expire-list"
wget -O /usr/bin/user-gen "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/user-gen"
wget -O /usr/bin/userlimit.sh "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/userlimit.sh"
#wget -O /usr/bin/userlimitssh.sh "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/userlimitssh.sh"
wget -O /usr/bin/user-list "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/user-list"
wget -O /usr/bin/user-login "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/user-login"
wget -O /usr/bin/user-pass "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/user-pass"
wget -O /usr/bin/user-renew "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/user-renew"
wget -O /usr/bin/clearcache.sh "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/clearcache.sh"
wget -O /usr/bin/bannermenu "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/bannermenu"
wget -O /usr/bin/menu-update-script-vps.sh "https://raw.githubusercontent.com/cobrasta25/zhangzi/master/menu-update-script-vps.sh"
cd
# cronjob
echo "*/30 * * * * root service dropbear restart" > /etc/cron.d/dropbear
echo "00 23 * * * root /usr/bin/disable-user-expire" > /etc/cron.d/disable-user-expire
echo "0 */12 * * * root /sbin/reboot" > /etc/cron.d/reboot
echo "00 01 * * * root echo 3 > /proc/sys/vm/drop_caches && swapoff -a && swapon -a" > /etc/cron.d/clearcacheram3swap
echo "*/3 * * * * root /usr/bin/clearcache.sh" > /etc/cron.d/clearcache1

cd
chmod +x /usr/bin/user-trial
chmod +x /usr/bin/rubah-tanggal
chmod +x /usr/bin/rubah-port
chmod +x /usr/bin/next
chmod +x /usr/bin/auto-reboot
chmod +x /usr/bin/bench-network
chmod +x /usr/bin/speedtest
chmod +x /usr/bin/ps-mem
#chmod +x /usr/bin/autokill
chmod +x /usr/bin/dropmon
chmod +x /usr/bin/menu
chmod +x /usr/bin/user-active-list
chmod +x /usr/bin/user-add
chmod +x /usr/bin/user-add-pptp
chmod +x /usr/bin/user-del
chmod +x /usr/bin/disable-user-expire
chmod +x /usr/bin/delete-user-expire
chmod +x /usr/bin/banned-user
chmod +x /usr/bin/unbanned-user
chmod +x /usr/bin/user-expire-list
chmod +x /usr/bin/user-gen
chmod +x /usr/bin/userlimit.sh
chmod +x /usr/bin/userlimitssh.sh
chmod +x /usr/bin/user-list
chmod +x /usr/bin/user-login
chmod +x /usr/bin/user-pass
chmod +x /usr/bin/user-renew
chmod +x /usr/bin/clearcache.sh
chmod +x /usr/bin/bannermenu
chmod +x /usr/bin/menu-update-script-vps.sh
cd


# Finishing
wget -O /etc/vpnfix.sh "https://raw.githubusercontent.com/GegeEmbrie/autosshvpn/master/file/vpnfix.sh"
chmod 777 /etc/vpnfix.sh
sed -i 's/exit 0//g' /etc/rc.d/rc.local
echo "" >> /etc/rc.d/rc.local
echo "bash /etc/vpnfix.sh" >> /etc/rc.d/rc.local
echo "$ screen badvpn-udpgw --listen-addr 127.0.0.1:7300 > /dev/null &" >> /etc/rc.d/rc.local
echo "nohup ./cron.sh &" >> /etc/rc.d/rc.local
echo "exit 0" >> /etc/rc.d/rc.local
wget https://raw.githubusercontent.com/GegeEmbrie/autosshvpn/master/addons/remove.sh && sh remove.sh
rm /root/debian.sh

# Log
clear
wget https://raw.githubusercontent.com/GegeEmbrie/autosshvpn/master/addons/details.sh && bash details.sh
rm details.sh
history -c
