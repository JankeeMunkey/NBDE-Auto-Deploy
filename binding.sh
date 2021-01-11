#!/bin/bash

#Delete first install files
function cleanup()
{
rm -f /root/anaconda*
rm -f /root/original*
}
cleanup

#Update packages and install all needed dependencies
function update()
{
	echo "package update in progress..."
	yum update -y 
	echo "update complete"
	sleep 2
	echo "Binding packages install in progress..."
	yum install clevis clevis-luks clevis-dracut -y 
	echo "Binding packages installed"
	sleep 2
	echo "3rd party packages install in progress..."
	yum install gcc bzip2 glibc.i686 kernel-devel-$(uname -r) kernel-headers-$(uname -r) -y
	echo "Additional 3rd party tools installed"

}

update

#Function for Clevis-Tang binding
function binder()
{
	#Wipe luks slots to avoid conflict. Leaving 1st slot alone as this is usually reserved for non Clevis-Tang method.
	luksmeta wipe -d /dev/sda3 -s 1 -f
	luksmeta wipe -d /dev/sda3 -s 2 -f
	luksmeta wipe -d /dev/sda3 -s 3 -f
	luksmeta wipe -d /dev/sda3 -s 4 -f
	luksmeta wipe -d /dev/sda3 -s 5	-f
	luksmeta wipe -d /dev/sda3 -s 6 -f
	luksmeta wipe -d /dev/sda3 -s 7 -f
	luksmeta wipe -d /dev/sda4 -s 1 -f
	luksmeta wipe -d /dev/sda4 -s 2 -f
	luksmeta wipe -d /dev/sda4 -s 3 -f
	luksmeta wipe -d /dev/sda4 -s 4 -f
	luksmeta wipe -d /dev/sda4 -s 5 -f
	luksmeta wipe -d /dev/sda4 -s 6 -f
	luksmeta wipe -d /dev/sda4 -s 7 -f
	luksmeta wipe -d /dev/sda5 -s 1 -f
	luksmeta wipe -d /dev/sda5 -s 2 -f
	luksmeta wipe -d /dev/sda5 -s 3 -f
	luksmeta wipe -d /dev/sda5 -s 4 -f
	luksmeta wipe -d /dev/sda5 -s 5 -f
	luksmeta wipe -d /dev/sda5 -s 6 -f
	luksmeta wipe -d /dev/sda5 -s 7 -f

	#Perform binding
	read -sp "Input LUKS password	: " LUKS
	echo $LUKS > /tmp/LUKS
	echo "Binding Clevis to Tang now..."
	clevis bind luks -f -k /tmp/LUKS -d /dev/sda3 tang '{"url":"","thp":""}'
	clevis bind luks -f -k /tmp/LUKS -d /dev/sda4 tang '{"url":"","thp":""}'
	clevis bind luks -f -k /tmp/LUKS -d /dev/sda5 tang '{"url":"","thp":""}'
	echo "Clevis binding to Nashville complete"
	clevis bind luks -f -k /tmp/LUKS -d /dev/sda3 tang '{"url":"","thp":""}'
	clevis bind luks -f -k /tmp/LUKS -d /dev/sda4 tang '{"url":"","thp":""}'
	clevis bind luks -f -k /tmp/LUKS -d /dev/sda5 tang '{"url":"","thp":""}'
	echo "Clevis binding to Atlanta complete."
	
}
binder

function draco()
{
	read -r -p "Select your network type [static/dhcp] : " NETWORK
	case $NETWORK in
		static)
			echo "Static Selected"
			sleep 2
			read -p "Input your IP Address : " IP
			read -p "Input your netmask    : " MASK
			read -p "Input your gateway    : " GATEWAY
		        read -p "Input your DNS1       : " NAME1
		        read -p "Input your DNS2       : " NAME2
			dracut -f --regenerate-all --kernel-cmdline "ip=$IP netmask=$MASK gateway=$GATEWAY nameserver=$NAME1 nameserver=$NAME2"
			echo "Initramfs rebuilt with static ip parameters";;
		dhcp)
			echo "dhcp selected"
			sleep 2
			dracut -f --regenerate-all
			echo "Initramfs rebuilt with dhcp parameters";;
		*)
			echo "Wrong entry, try again"
			draco
			;;
	esac
}
draco

function revup()
{
	#append netdev flag to root partition
	echo "Marking partitions as network devices..."
	sed -ie 's:\(.*\)\(\s/\s\s*\)\(\w*\s*\)\(\w*\s*\)\(.*\):\1\2\3_netdev,\4\5:' /etc/fstab
	sed -ie 's:\(.*\)\(\s/opt/imsdb\s\s*\)\(\w*\s*\)\(\w*\s*\)\(.*\):\1\2\3_netdev,\4\5:' /etc/fstab
	sed -ie 's:\(.*\)\(\sswap\s*\)\(\w*\s*\)\(\w*\s*\)\(.*\):\1\2\3,_netdev\4\5:' /etc/fstab
	sed -i 's/$/ _netdev/' /etc/crypttab
	echo "Partition marking complete."
	sleep 2
	systemctl enable clevis-luks-askpass.path
}

revup

function grubedit()
{
	#Marking a kernel as default that is known to be on the system at binding time as a kernel without binding will not boot.
	echo "Marking default kernel..."
	grub2-set-default 1
	grub2-mkconfig -o /boot/grub2/grub.cfg
	echo "Default kernel set."
}
grubedit
rm -f /tmp/LUKS
history -c

echo "Binding script process complete."
sleep 4

exit
