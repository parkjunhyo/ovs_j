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
apt-get install -y git

## basc network configuration to enhance the system
## download git server (user can change)
git_repo_name="system_netcfg_exchange"
git clone http://github.com/parkjunhyo/$git_repo_name
$(pwd)/$git_repo_name/adjust_timeout_failsafe.sh
$(pwd)/$git_repo_name/packet_forward_enable.sh
$(pwd)/$git_repo_name/google_dns_setup.sh

## download openvswitch source file from git
ovs_source=$(pwd)/openvswitch
if [[ ! -d $ovs_source ]]
then
 git clone git://openvswitch.org/openvswitch
fi

## before OVS kernel module setup, save the current kernel status history
kernel_history=$(pwd)/kernel_history.log
lsmod > $kernel_history

## setup soft kernel module installation
apt-get install -y build-essential fakeroot
apt-get install -y debhelper autoconf automake automake1.10 libssl-dev python-all python-qt4 python-twisted-conch
apt-get install -y dkms
apt-get install -y iperf traceroute
apt-get upgrade -y

## soft kernel module setup
working_directory=$(pwd)
if [[ ! `lsmod | grep -i 'openvswitch'` ]]
then
 cd $ovs_source
 fakeroot debian/rules binary
 cd $working_directory
 dpkg -i $(ls openvswitch-datapath-dkms*)
 dpkg -i $(ls openvswitch-common*)
 dpkg -i $(ls openvswitch-switch*)
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