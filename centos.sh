
#!/bin/bash
clear
echo "=============================="
echo "        Selamat Datang        "
echo "=============================="
echo "Ketik 'I' Untuk VPS Non-Lokal"
echo "Ketik 'L' Untuk VPS Lokal" 
echo "=============================="
read -p "Location : " -e loc
yum update -y

# go to root
cd

# remove unused
yum -y remove sendmail;
yum -y remove httpd;
yum -y remove cyrus-sasl

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.d/rc.local

# install wget and curl
yum -y install wget curl

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service sshd restart

# setting repo
wget http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
rpm -Uvh epel-release-6-8.noarch.rpm
rpm -Uvh remi-release-6.rpm
sed -i -e "/^\[remi\]/,/^\[.*\]/ s|^\(enabled[ \t]*=[ \t]*0\\)|enabled=1|" /etc/yum.repos.d/remi.repo
rm -f *.rpm

# --------- Mirror Repo --------------
# wget http://script.hostingtermurah.net/repo/autoscript/centos6/epel-release-6-8.noarch.rpm
# wget http://script.hostingtermurah.net/repo/autoscript/centos6/remi-release-6.rpm
# rpm -Uvh epel-release-6-8.noarch.rpm
# rpm -Uvh remi-release-6.rpm
# if [ "$OS" == "x86_64" ]; then
  # wget http://script.hostingtermurah.net/repo/autoscript/centos6/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
  # rpm -Uvh rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
# else
  # wget http://script.hostingtermurah.net/repo/autoscript/centos6/rpmforge-release-0.5.3-1.el6.rf.i686.rpm
  # rpm -Uvh rpmforge-release-0.5.3-1.el6.rf.i686.rpm
# fi
# sed -i -e "/^\[remi\]/,/^\[.*\]/ s|^\(enabled[ \t]*=[ \t]*0\\)|enabled=1|" /etc/yum.repos.d/remi.repo
# rm -f *.rpm

# update
yum update -y

# Install Essential Package
yum -y install wondershaper rrdtool screen iftop htop nmap bc nethogs openvpn vnstat ngrep mtr git zsh mrtg unrar rsyslog rkhunter mrtg net-snmp net-snmp-utils expect nano bind-utils
yum -y groupinstall 'Development Tools'
yum -y install cmake
yum -y --enablerepo=rpmforge install axel sslh ptunnel unrar

# Install Webmin
yum update && yum groupinstall "Development Tools"
wget http://prdownloads.sourceforge.net/webadmin/webmin-1.770-1.noarch.rpm
yum -y install perl perl-Net-SSLeay openssl perl-IO-Tty
rpm -U webmin-1.770-1.noarch.rpm && chkconfig webmin on
chkconfig webmin on
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
service webmin restart

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

# install openvpn
wget -O /etc/openvpn/openvpn.tar "https://raw.github.com/yurisshOS/debian7/master/openvpn-debian.tar"
cd /etc/openvpn/
tar xf openvpn.tar
wget -O /etc/openvpn/1194.conf "https://raw.github.com/yurisshOS/centos6/master/vps.conf"
if [ "$OS" == "x86_64" ]; then
  wget -O /etc/openvpn/1194.conf "https://raw.github.com/yurisshOS/centos6/master/1194-centos64.conf"
fi
wget -O /etc/iptables.up.rules "https://raw.github.com/yurisshOS/centos6/master/iptables.up.rules"
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.local
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.d/rc.local
sed -i $MYIP2 /etc/iptables.up.rules;
iptables-restore < /etc/iptables.up.rules
sysctl -w net.ipv4.ip_forward=1
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
service openvpn restart
chkconfig openvpn on
cd

# configure openvpn client config
cd /etc/openvpn/
wget -O /etc/openvpn/1194-client.ovpn "https://raw.github.com/yurisshOS/centos6/master/1194-client.conf"
sed -i $MYIP2 /etc/openvpn/1194-client.ovpn;
PASS=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1`;
useradd -M -s /bin/false YurisshOS
echo "YurisshOS:$PASS" | chpasswd
echo "username" > pass.txt
echo "password" >> pass.txt
tar cf client.tar 1194-client.ovpn pass.txt
cp client.tar /home/vps/public_html/
cd

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
