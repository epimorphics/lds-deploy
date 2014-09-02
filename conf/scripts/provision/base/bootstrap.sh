#!/bin/bash
# Generic provisioning script to run on a new instance
# Formats any attached EBS volume at standard location /dev/xvdf and mounts it
# Forces any instance disk at /dev/xvdg to be mounted at /mnt/ephemeral1 
# (seems to vary by instance type whether the virtualname setting works or not)
# These rely on the device naming set up the generic allocate script

set -o nounset
set -o errexit

readonly INST_DEV=/dev/xvdg
readonly EBS_DEV=/dev/xvdf

# Check for instance disk
if blkid $INST_DEV > /dev/null; then
  if grep -q $INST_DEV /etc/fstab ; then
    umount $INST_DEV || true
    sed -i "s!$INST_DEV.*\$!$INST_DEV  /mnt/ephemeral0  auto  defaults,nobootwait 0 2!" /etc/fstab
  else
    echo "$INST_DEV  /mnt/ephemeral0  auto  defaults,nobootwait 0 2" | tee -a /etc/fstab > /dev/null
  fi
  echo "Mount instance disk"
  mkdir -p /mnt/ephemeral0
  mount /mnt/ephemeral0
fi 

# Check for possible EBS disk
if ! blkid $EBS_DEV > /dev/null; then
    # No visible attached volume but might not be formatted yet
    # This will just fail if no such device
    echo "Attempting to format EBS disk"
    mkfs -t ext4 $EBS_DEV || true
fi

if blkid $EBS_DEV > /dev/null; then
    # We have an attached volume, mount it
    if ! mount | grep -q $EBS_DEV ; then
        # Not mounted yet
        echo "Mounting EBS disk"
        mkdir -p /mnt/disk1
        UUID=$(blkid $EBS_DEV | sed -e 's/^.*\(UUID="[^"]*"\).*$/\1/')
#    echo "$UUID /mnt/disk1 ext4 rw 0 2" | tee -a /etc/fstab > /dev/null && mount /mnt/disk1
        echo "$EBS_DEV /mnt/disk1 ext4 rw 0 2" | tee -a /etc/fstab > /dev/null && mount /mnt/disk1
    fi
fi

# Basic packages - probably should leave these to chef but can't see how
apt-get -q update -y
apt-get -q upgrade -y
locale-gen en_GB.UTF-8
