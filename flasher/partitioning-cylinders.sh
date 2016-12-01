#!/bin/bash
echo "********************************************"
echo "Sitara Partitioning Script - 28.11.2016"

#Choose device
DRIVE="/dev/mmcblk0"

# Figure out the size of eMMC in Gb 
SIZE=`fdisk -l $DRIVE | grep Disk | awk '{print $5}'`
GB=`echo $(($SIZE/1024/1024/1024))`
CYLINDERS=`echo $(($SIZE/255/63/512))`
echo "eMMC size: $GB Gb" 

#Confirm 
echo "Do you want to create new partition table? (y/N)"
	read item
	case "$item" in
    	y|Y) 	
    		echo "---------Starts partitioning---------"
        ;;
    	n|N) 
			echo "--------------Cancelled--------------"
			exit
		;;
    	*) 	
			echo "--------------Cancelled--------------"
			exit
        ;;
	esac

echo "************Clearing eMMC************"

#Erase start block on eMMC
dd if=/dev/zero of=$DRIVE bs=4k count=1
sync
sync

#Function for checking mounted eMMC partitions
check_mounted(){
	if grep -q ${DRIVE}p /proc/mounts; then

		#Check mounted partitions
		is_mounted=`grep ${DRIVE}p /proc/mounts | awk '{print $2}'`
		echo "Found mounted partitions on " $DRIVE ":" $is_mounted
		
		#Unmount partitions and erase old partition info, loaded from MBR
		echo "********Unmounting partitions********"
		umount $is_mounted
		counter=1
		for i in $is_mounted; do \
			echo "deleting ${DRIVE}p${counter}";
			dd if=/dev/zero of=${DRIVE}p${counter} bs=4k count=1;
			counter=$((counter+1));
		done

	else 
    	echo "No mounted partitions found. Continuing."
    fi
}

check_mounted;

#Partitioning eMMC. This command creates to partitions: 
#1. Size = 9 cylinders * 255 heads * 63 sectors * 512 bytes/sec = ~70MB, with ID=0x0C(FAT), is bootable,  
#2. Size=456 cylinders * 255 heads * 63 sectors * 512 bytes/sec= ~3GB  , with EXT3 FS, isn't bootable.
echo "****Creating new partition table****"
#Create new partition table
fdisk -C $CYLINDERS -H 255 -S 63 $DRIVE <<EOF
n
p
1
1
9
n
p
2
10

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
mkfs.ext2 -L "rootfs" ${DRIVE}p2
sync
sync
echo "***********Formatting done***********"
     
#Mounting new partitions to current filesystem for transfering flashing images
#Mounting new partitions to current filesystem for transfering flashing images
mkdir tmp_boot
mkdir tmp_rootfs
mount -t vfat ${DRIVE}p1 tmp_boot
mount -t ext2 ${DRIVE}p2 tmp_rootfs 

echo "********************************************"
echo "Sitara Partitioning Script is complete."