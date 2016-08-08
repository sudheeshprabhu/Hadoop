#!/bin/bash
#Script written by Sudheesh 
#This script will do Hadoop pre-requisites

#Check if OS is RHEL based, if not exit

if [ ! -f /etc/redhat-release ]
then
echo " Script will work only on RHEL/CentOS distros"
fi

#Stop and disable IPTables

echo "Stoping and disabling IPtables"

/etc/init.d/iptables stop
chkconfig iptables off
echo

#Stop and disable IPTable6

echo "Stoping and disabling IPtables6"
/etc/init.d/ip6tables stop
chkconfig ip6tables off
echo

#Update network file and restart

sed -i.bak 's|^IPV6INIT.*|IPV6INIT=no|g' /etc/sysconfig/network
sed -i 's|^NETWORKING_IPV6.*|NETWORKING_IPV6=no|g' /etc/sysconfig/network
sed -i 's|^NETWORKING[ ]*=.*|NETWORKING=yes|g' /etc/sysconfig/network
sed -i "s/^HOSTNAME[ ]*=.*/HOSTNAME=`hostname`/g" /etc/sysconfig/network
/etc/init.d/network restart

#Disable SELINUX

sed -i.bak 's/^SELINUX[ ]*=.*/SELINUX=disabled/g' /etc/selinux/config

#SET VM Swappiness to 0

grep "vm.swappiness[ ]*=" /etc/sysctl.conf
if [ $? -eq 0 ]
then
sed -i.bak 's/vm.swappiness[ ]*=.*/vm.swappiness=0/g' /etc/sysctl.conf
else
echo "vm.swappiness=0" >>/etc/sysctl.conf
fi

#Disable HuePage

if [ -f /sys/kernel/mm/transparent_hugepage/enabled ] && [ -f /sys/kernel/mm/transparent_hugepage/defrag ]
then
echo "echo never >  /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local
echo "echo never >  /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.local

fi

if [ -f /sys/kernel/mm/redhat_transparent_hugepage/enabled ] && [ -f /sys/kernel/mm/redhat_transparent_hugepage/defrag ]
then
echo "echo never >  /sys/kernel/mm/redhat_transparent_hugepage/enabled" >> /etc/rc.local
echo "echo never >  /sys/kernel/mm/redhat_transparent_hugepage/defrag" >> /etc/rc.local

fi

#Check NTP service is running

if [ -f /etc/init.d/ntpd ]
then
/etc/init.d/ntpd status
	if [ $? -eq 0 ]
		then
		echo " NTP service is running"
		chkconfig ntp on
	else
		/etc/init.d/ntpd start
		chkconfig ntp on
	fi
else
yum install ntp
/etc/init.d/ntpd start
fi



echo
echo "**************************"
echo "!!! Verification !!!"
echo "**************************"
/etc/init.d/iptables status
/etc/init.d/ip6tables status
chkconfig --list |grep -E 'iptables|ip6tables'
echo "=========================="
echo
echo "Verify network file"
echo "=========================="
cat /etc/sysconfig/network
echo
echo
echo "=========================="
echo "Ensure SELINUX is disabled"
echo "=========================="
grep "SELINUX=" /etc/selinux/config
echo
echo "=========================="
echo "Verify vm.swappiness is 0"
echo "=========================="
grep "vm.swappiness=" /etc/sysctl.conf
echo
echo "=========================="
echo " Verify rc local file"
echo "=========================="
cat /etc/rc.local

echo "=========================="
echo
echo " Verify NTPD service"
echo "=========================="

/etc/init.d/ntpd status
chkconfig --list |grep "ntpd "

echo "=========================="

echo " Do you want to proceed with System reboot[y/n] "
read key
if [ $key == 'y' ]
then

reboot

else
exit 1
fi

