#! /usr/bin/env bash

## remove bridge module (dependancy remove)
if [[ `lsmod | grep bridge` ]]
then
 rmmod bridge
fi

## install necessary utility for setup
if [[ ! `cat /etc/resolv.conf | grep '8.8.8.8'` ]]
then
 echo "nameserver 8.8.8.8" >> /etc/resolv.conf
fi
apt-get install -y git expect

## basc network configuration to enhance the system
## download git server (user can change)
working_directory=$(pwd)

if [ ! -d $working_directory/system_netcfg_exchange ]
then
 git clone https://github.com/parkjunhyo/system_netcfg_exchange.git
 cd $working_directory/system_netcfg_exchange
 ./adjust_timeout_failsafe.sh
 ./packet_forward_enable.sh
 ./google_dns_setup.sh
 cd $working_directory
fi

if [ ! -d $working_directory/deppkg_j ]
then
 git clone https://github.com/parkjunhyo/deppkg_j.git
 cd $working_directory/deppkg_j
 ./system_deppkg.sh
 ./racoon_setup.exp
 cd $working_directory
fi
apt-get build-dep -y openvswitch
apt-get install -qqy --force-yes uuid-runtime ipsec-tools iperf traceroute


## download openvswitch source file from git
ovs_source=$working_directory/openvswitch
if [ ! -d $ovs_source ]
then
 cd $working_directory
 git clone git://openvswitch.org/openvswitch
fi

## before OVS kernel module setup, save the current kernel status history
kernel_history=$working_directory/kernel_history.log
lsmod > $kernel_history

## soft kernel module setup
if [[ ! `lsmod | grep -i 'openvswitch'` ]]
then
 cd $ovs_source
 fakeroot debian/rules binary
 cd $working_directory
 ls $(pwd)/*.deb | xargs dpkg -i
# module-assistant auto-install openvswitch-datapath
# sed -i 's/# BRCOMPAT=no/BRCOMPAT=yes/' /etc/default/openvswitch-switch
fi

## kernel boot up setting, change the /etc/modules files
if [[ ! `cat /etc/modules | grep -i 'gre'` ]]
then
 echo "gre" >> /etc/modules
fi
if [[ ! `cat /etc/modules | grep -i 'openvswitch'` ]]
then
 echo "openvswitch" >> /etc/modules
fi

## check the openvswitch version
ovsd_ver=$(pwd)/soft_ovsd_version
ovsvsctl_command=$(which 'ovs-vsctl')
$ovsvsctl_command --version > $ovsd_ver
