#########################################################################################################
#
#This file is for NBDE Servers.
#
#
#Verify this is the intended purpose before continuing.
#
#########################################################################################################

# Image is for install, not upgrade
install

# Keyboard layouts
keyboard 'us'

# System language
lang en_US

# System authorization information
auth  --useshadow  --enablemd5

# Use CDROM installation media
cdrom

# Use text mode install
text
firstboot --enable

# SELinux configuration
selinux --disabled

# Do not configure the X Window System
skipx

# Firewall configuration
firewall --disabled

# Network information
%include /tmp/network.ks

# System timezone
timezone America/Chicago

# Accept eula prompt
eula --agreed

# Configure root password
%include /tmp/root.ks

# System bootloader configuration
bootloader --location=mbr

# Clear the Master Boot Record
zerombr

# Delete all existing partitions
clearpart --all --initlabel

# Configure partitioning based on Profile
%include /tmp/part.ks

# Halt for user input after installation is complete
halt

#########################################################################################################

#########################################################################################################

%pre --interpreter=/bin/bash
#change Virtual terminal to accept user input
exec < /dev/tty6 > /dev/tty6 2> /dev/tty6
chvt 6


read -p  "Enter hostname		: " HOSTNAME
read -p  "Enter root password	: " ROOTPW
read -p  "Enter LUKS password	: " LUKS
sleep 1

#Network Schema
ip addr | grep -i broadcast | awk '{ print $2}' > /tmp/interface0
sed -i 's/:/\ /g' /tmp/interface0
head -n 1 /tmp/interface0 > /tmp/interface1

INTERFACE='cat /tmp/interface1'

echo "network --bootproto dhcp  --device=em1 --noipv6 --activate --onboot=on"  > /tmp/network.ks
echo "network --hostname=$HOSTNAME" >> /tmp/network.ks

#Root User Configuration
echo "rootpw "\"$ROOTPW\""" > /tmp/root.ks

#LUKS Configuration
#echo "\"$LUKS"" > /tmp/luks.ks

#Partitioning Scheme based on Profile
function Partition ()
{
    read -r -p "Select your Profile [small/medium/large] : " PROFILE
    case $PROFILE in
        small)
            echo -e "Small PROFILE not configured yet, select another option"
			Partition;;
        medium)
            echo "part /boot --ondisk=sda --fstype="ext4" --size=1024" > /tmp/part.ks
			echo "part /boot/efi --ondisk=sda --size=1024" >> /tmp/part.ks
			echo "part / --ondisk=sda --fstype="ext4" --size=102400 --encrypted --passphrase="\"$LUKS\""" >> /tmp/part.ks
			echo "part swap --ondisk=sda --size=12288 --encrypted --passphrase="\"$LUKS\""" >> /tmp/part.ks
			echo "part /opt/imsdb --ondisk=sda --fstype="ext4" --size=346000 --encrypted --passphrase="\"$LUKS\""" >> /tmp/part.ks
			echo "part /usr/local/PACS --ondisk=sdb --fstype="ext4" --size=1382400" >> /tmp/part.ks
			echo "part /usr/local/PACS/images/dev1 --ondisk=sdb --fstype="ext4" --size=1382400" >> /tmp/part.ks
			echo "part /usr/local/PACS/images/dev2 --ondisk=sdb --fstype="ext4" --size=1382400" >> /tmp/part.ks
			echo "part /usr/local/PACS/images/dev3 --ondisk=sdb --fstype="ext4" --size=1382400" >> /tmp/part.ks
			echo -e "Configured as Medium";;
        large)
            echo "part /boot --ondisk=sda --fstype="ext4" --size=1024" > /tmp/part.ks
			echo "part /boot/efi --ondisk=sda --size=1024" >> /tmp/part.ks
			echo "part / --ondisk=sda --fstype="ext4" --size=153600 --encrypted --passphrase="\"$LUKS\""" >> /tmp/part.ks
			echo "part swap --ondisk=sda --size=12288 --encrypted --passphrase="\"$LUKS\""" >> /tmp/part.ks
			echo "part /opt/imsdb --ondisk=sda --fstype="ext4" --grow --encrypted --passphrase="\"$LUKS\""" >> /tmp/part.ks
			echo "part /usr/local/PACS --ondisk=sdb --fstype="ext4" --size=1894400" >> /tmp/part.ks
			echo "part /usr/local/PACS/images/dev1 --ondisk=sdb --fstype="ext4" --size=1894400" >> /tmp/part.ks
			echo "part /usr/local/PACS/images/dev2 --ondisk=sdb --fstype="ext4" --size=1894400" >> /tmp/part.ks
			echo "part /usr/local/PACS/images/dev3 --ondisk=sdb --fstype="ext4" --size=1894400" >> /tmp/part.ks
			echo -e "Configured as Large";;
        *)
            echo "Invalid Option"
            Partition
            ;;
    esac
}
Partition


chvt 1
exec < /dev/tty1 > /dev/tty1 2> /dev/tty1
%end

#########################################################################################################

%post --nochroot

cp -f /mnt/install/repo/binding.sh /mnt/sysimage/root

%end
