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

## setup hard kernel module installation
apt-get install -y libssl-*
apt-get install -y sparse
apt-get install -y python-simplejson python-qt4 python-twisted-conch automake autoconf
apt-get install -y gcc uml-utilities libtool build-essential git pkg-config linux-headers-`uname -r`
apt-get install -y debhelper automake1.10 libssl-dev python-all python-twisted-conch
apt-get install -y iperf traceroute
apt-get upgrade -y

## hard kernel module setting
working_directory=$(pwd)
if [[ ! `lsmod | grep -i 'openvswitch'` ]]
then
 cd $ovs_source
 ./boot.sh
 ./configure --with-linux=/lib/modules/`uname -r`/build
 make
 make install
 make modules_install
 modprobe openvswitch
 cd $working_directory
 depmod -a
fi

## check openvswitch and gre dependancy with module
if [[ ! `lsmod | grep -i 'gre' | grep -i 'openvswitch'` ]]
then
 modprobe -r openvswitch
 modprobe -r gre
 mv /lib/modules/`uname -r`/kernel/net/openvswitch/openvswitch.ko /lib/modules/`uname -r`/kernel/net/openvswitch/openvswitch.ko.bak
 cp /lib/modules/`uname -r`/extra/openvswitch.ko /lib/modules/`uname -r`/kernel/net/openvswitch/openvswitch.ko
 modprobe gre
 modprobe openvswitch
 depmod -a
fi

## initialize the configuration database
if [[ ! -d /usr/local/etc/openvswitch ]]
then
 mkdir -p /usr/local/etc/openvswitch
fi
if [[ ! -f /usr/local/etc/openvswitch/conf.db ]]
then
 ovsdb-tool create /usr/local/etc/openvswitch/conf.db $ovs_source/vswitchd/vswitch.ovsschema
fi

## create and start openvswitch processing command
hard_ovsd_startup=/etc/init.d/kernel_openvswitchd
hard_ovsd_ver=$(pwd)/hard_ovsd_version
ovsdb_server_command=$(which 'ovsdb-server')
ovsvswitch_command=$(which 'ovs-vswitchd')
ovsvsctl_command=$(which 'ovs-vsctl')
if [[ ! -f $hard_ovsd_startup ]]
then
 echo "#! /usr/bin/env bash" > $hard_ovsd_startup
 echo " " >> $hard_ovsd_startup
 echo "if [[ \`ps aux | grep -i 'ovs-vswitchd' | awk '{if(\$0!~/grep/){print \$2}}'\` ]]" >> $hard_ovsd_startup
 echo "then">> $hard_ovsd_startup
 echo " set \`ps aux | grep -i 'ovs-vswitchd' | awk '{if(\$0!~/grep/){print \$2}}'\`" >> $hard_ovsd_startup
 echo " for processid in \$@" >> $hard_ovsd_startup
 echo " do" >> $hard_ovsd_startup
 echo "  kill -9 \$processid&" >> $hard_ovsd_startup
 echo " done" >> $hard_ovsd_startup
 echo " sleep 1" >> $hard_ovsd_startup
 echo "fi" >> $hard_ovsd_startup
 echo " " >> $hard_ovsd_startup
 echo "if [[ \`ps aux | grep -i 'ovsdb-server' | awk '{if(\$0!~/grep/){print \$2}}'\` ]]" >> $hard_ovsd_startup
 echo "then">> $hard_ovsd_startup
 echo " set \`ps aux | grep -i 'ovsdb-server' | awk '{if(\$0!~/grep/){print \$2}}'\`" >> $hard_ovsd_startup
 echo " for processid in \$@" >> $hard_ovsd_startup
 echo " do" >> $hard_ovsd_startup
 echo "  kill -9 \$processid&" >> $hard_ovsd_startup
 echo " done" >> $hard_ovsd_startup
 echo " sleep 1" >> $hard_ovsd_startup
 echo "fi" >> $hard_ovsd_startup
 echo " " >> $hard_ovsd_startup
 echo "$ovsdb_server_command --remote=punix:/usr/local/var/run/openvswitch/db.sock \\" >> $hard_ovsd_startup
 echo "                     --remote=db:Open_vSwitch,Open_vSwitch,manager_options \\" >> $hard_ovsd_startup
 echo "                     --private-key=db:Open_vSwitch,SSL,private_key \\" >> $hard_ovsd_startup
 echo "                     --certificate=db:Open_vSwitch,SSL,certificate \\" >> $hard_ovsd_startup
 echo "                     --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert \\" >> $hard_ovsd_startup
 echo "                     --pidfile --detach" >> $hard_ovsd_startup
 echo " " >> $hard_ovsd_startup
 echo "if [[ ! -f $hard_ovsd_ver ]]" >> $hard_ovsd_startup
 echo "then" >> $hard_ovsd_startup
 echo " $ovsvsctl_command --no-wait init" >> $hard_ovsd_startup
 echo "fi" >> $hard_ovsd_startup
 echo " " >> $hard_ovsd_startup
 echo "$ovsvswitch_command --pidfile --detach" >> $hard_ovsd_startup
 echo "$ovsvsctl_command --version > $hard_ovsd_ver" >> $hard_ovsd_startup
 chmod 744 $hard_ovsd_startup
 chown root.root $hard_ovsd_startup
fi
$hard_ovsd_startup

## kernel boot up setting, change the /etc/modules files
if [[ ! `cat /etc/modules | grep -i 'gre'` ]]
then
 echo "gre" >> /etc/modules
fi
if [[ ! `cat /etc/modules | grep -i 'openvswitch'` ]]
then
 echo "openvswitch" >> /etc/modules
fi
 
## openvswitch start on booting up, change the /etc/rc.local file
if [[ ! `cat /etc/rc.local | grep -i $hard_ovsd_startup` ]]
then
 temp_file=/tmp/$(date +%Y%m%d%H%M%S)
 touch $temp_file
 chmod 777 $temp_file
 chown root.root $temp_file
 cat /etc/rc.local | awk '{if($0!~/^exit[[:space:]]*[[:digit:]]*/){print $0}}' > $temp_file
 echo "$hard_ovsd_startup" >> $temp_file
 echo "exit 0" >> $temp_file
 cp $temp_file /etc/rc.local
 rm -rf $temp_file
fi

