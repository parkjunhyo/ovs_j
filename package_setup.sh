#! /usr/bin/env bash

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

## remove bridge module (dependancy remove)
if [[ `lsmod | grep bridge` ]]
then
 rmmod bridge
fi

## stop the QEMU and Livbirt
/etc/init.d/libvirt-bin stop
/etc/init.d/qemu-kvm stop

## before OVS kernel module setup, save the current kernel status history
kernel_history=$(pwd)/kernel_history.log
lsmod > $kernel_history

## setup soft kernel module installation
## find the openvswitch package (apt-get install openvswitch-* .... confirm package!)
apt-get install -y openvswitch-switch quantum-plugin-openvswitch openvswitch-ipsec openvswitch-datapath-source openvswitch-controller python-openvswitch openvswitch-datapath-dkms openvswitch-brcompat openvswitch-pki openvswitch-common
sed -i 's/# BRCOMPAT=no/BRCOMPAT=yes/' /etc/default/openvswitch-switch

## check the openvswitch version
ovsd_ver=$(pwd)/package_ovsd_version
ovsvsctl_command=$(which 'ovs-vsctl')
$ovsvsctl_command --version > $ovsd_ver
