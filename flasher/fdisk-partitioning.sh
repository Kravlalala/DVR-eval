#!/bin/bash
echo "********************************************"
echo "Sitara Partitioning Script - 28.11.2016"

#Choose device
DRIVE="/dev/mmcblk0"

#Erase start block on eMMC
dd if=/dev/zero of=$DRIVE bs=4k count=1
sync
sync

# Figure out the size of eMMC in Gb and in Cylinders
SIZE=`fdisk -l $DRIVE | grep Disk | awk '{print $5}'`
GB=`echo $SIZE/1024/1024/1024 | bc`
echo "eMMC size: $GB Gb" 

#Function for checking mounted eMMC partitions
check_mounted(){
	if grep -q ${DRIVE}p /proc/mounts; then

		#Check mounted partitions
		is_mounted=`grep ${DRIVE}p /proc/mounts | awk '{print $2}'`
		echo "Found mounted partitions on " $DRIVE ":" $is_mounted
		
		#Erase old partition info, loaded from MBR
		echo "Do you want to create new partition table? (y/N)"
		read item
		case "$item" in
    		y|Y) 	
    			#Erase start blocks in every partition
				echo "************Clearing eMMC************"
				echo "Unmounting partitions "
				umount $is_mounted
				counter=1
				for i in $is_mounted; do \
					echo "deleting ${DRIVE}p${counter}";
					dd if=/dev/zero of=${DRIVE}p${counter} bs=4k count=1;
					counter=$((counter+1));
				done
        	;;
    		n|N) 
				echo "**************Cancelled**************"
				exit
			;;
    		*) 	
				echo "**************Cancelled**************"
				exit
        	;;
		esac
	else 
    	echo "No partitions found. Continuing."
    fi
}

check_mounted;

#Partitioning eMMC. This command creates to partitions: 
#1. Starting sector 2048 last sector 145407 size= 69MB, with ID=0x0C(FAT), is bootable,  
#2. Starting sector 145408 last sector default size=3GB  , with EXT3 FS, isn't bootable.
echo "****Creating new partition table****"
#Create new partition table
fdisk $DRIVE <<EOF
n
p
1
2048
145407
n
p
2
145408

t
1
b
t
2
83
a
1
w
EOF
sleep 2

#Formatting eMMC. This command format boot partition to fat32 and fs partition to ext4
echo "******Formatting boot partition******"
mkfs.vfat -F 32 -n "boot" ${DRIVE}p1
echo "*****Formatting rootfs partition*****"
mke2fs -L "rootfs" -t ext4 -j ${DRIVE}p2
sync
sync
echo "***********Formatting done***********"
     
#Mounting new partitions to current filesystem for transfering flashing images
#Mounting new partitions to current filesystem for transfering flashing images
mkdir tmp_boot
mkdir tmp_rootfs
mount -t vfat ${DRIVE}p1 tmp_boot
mount -t ext4 ${DRIVE}p2 tmp_rootfs 

echo "********************************************"
echo "Sitara Partitioning Script is complete."