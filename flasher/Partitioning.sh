#!/bin/bash
echo "***************************************************************"
echo "Sitara Partitioning Script - 23.11.2016"

#Choose device
DRIVE="/dev/mmcblk0"

# Figure out the size of eMMC in Gb and in Cylinders
SIZE=`fdisk -l $DRIVE | grep Disk | awk '{print $5}'`
GB=`echo $SIZE/1024/1024/1024 | bc`
CYLINDERS=`echo $SIZE/255/63/512 | bc`
echo "eMMC size: " $GB

#Function for checking mounted eMMC partitions
check_mounted(){
	if grep -q ${DRIVE}p /proc/mounts; then

		#Check mounted partitions
		is_mounted=`grep ${DRIVE}p /proc/mounts | awk '{print $2}'`
		echo "Found mounted partitions on " $DRIVE ":" $is_mounted
		
		echo "Do you want to erase old partition table? (y/N)"
		read item
		case "$item" in
    		y|Y) #Backup old partition table 
				 	

    			#Erase start blocks in every partition
				echo "***Clearing eMMC***"
				echo "Unmounting partitions "
				umount $is_mounted
				counter=1
				for i in is_mounted	do \
					echo "deleting ${DRIVE}p${counter}";
					dd if=/dev/zero of=${DRIVE}p${counter} bs=4k count=1;
					counter=$((counter+1))
				done
				#Erase start block on eMMC
				dd if=/dev/zero of=$DRIVE bs=4k count=1
				sync
				sync
        		;;
    		n|N) echo "Exit"
        		exit 0
        		;;
    		*) echo "Exit"
				exit 0
        		;;
		esac
	else 
    	echo "No partitions found. Continuing."
}


check_mounted;

#Partitioning eMMC. This command creates to partitions: 
#1. Size = 9 cylinders * 255 heads * 63 sectors * 512 bytes/sec = ~70MB, with ID=0x0C(FAT), is bootable,  
#2. Size=456 cylinders * 255 heads * 63 sectors * 512 bytes/sec= ~3GB  , with EXT3 FS, isn't bootable.
sfdisk -D -H 255 -S 63 -C $CYLINDERS $DRIVE << EOF
,9,0x0C,*
10,,,-
EOF
sleep 2

		
  		