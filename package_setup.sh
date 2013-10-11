#! /usr/bin/env bash

## install necessary utility for setup
echo "nameservers 8.8.8.8" >> /etc/resolv.conf
apt-get install -y git

## basc network configuration to enhance the system
## download git server (user can change)
git clone https://github.com/parkjunhyo/system_netcfg_exchange
$(pwd)/netcfg_exchange_j/adjust_timeout_failsafe.sh
$(pwd)/netcfg_exchange_j/packet_forward_enable.sh
$(pwd)/netcfg_exchange_j/google_dns_setup.sh

## remove bridge module (dependancy remove)
if [[ `lsmod | grep bridge` ]]
then
 rmmod bridge
fi

## before OVS kernel module setup, save the current kernel status history
kernel_history=$(pwd)/kernel_history.log
lsmod > $kernel_history

## setup soft kernel module installation
apt-get install -y openvswitch-brcompat 
apt-get install -y openvswitch-common 
apt-get install -y openvswitch-controller 
apt-get install -y openvswitch-datapath-dkms 
apt-get install -y openvswitch-datapath-source
apt-get upgrade -y

## check the openvswitch version
ovsd_ver=$(pwd)/package_ovsd_version
ovsvsctl_command=$(which 'ovs-vsctl')
$ovsvsctl_command --version > $ovsd_ver
