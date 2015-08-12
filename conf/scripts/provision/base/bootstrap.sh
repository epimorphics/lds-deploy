#!/bin/sh
# Generic provisioning script to run on a new instance
# Formats any attached EBS volume at standard location /dev/xvdf and mounts it
# Forces any instance disk at /dev/xvdg to be mounted at /mnt/ephemeral1 
# (seems to vary by instance type whether the virtualname setting works or not)
# These rely on the device naming set up the generic allocate script

set -o nounset
set -o errexit

# Format and mount disk if possible.
# Usage:  install_disk device location
install_disk() {
    local DEV="$1"
    local MOUNT="$2"

    # Ensure formatted
    if ! blkid $DEV > /dev/null; then
        # No visible attached volume but might not be formatted yet
        # This will just fail if no such device
        echo "Attempting to format disk at $DEV"
        mkfs -t ext4 $DEV || true
    fi

    if blkid $DEV > /dev/null; then

        # Disk exists and formatted, check mounting
        if grep -q $DEV /etc/fstab ; then
            # Check if mounted in right place, AWS doesn't always respect request
            if grep -q "$DEV.*$MOUNT" /etc/fstab; then
                echo "$MOUNT already set up"
            else
                umount $DEV || true
                sed -i "s@$DEV.*\$@$DEV  $MOUNT  auto  defaults,nodev,nobootwait 0 2@" /etc/fstab
            fi
        else
            echo "$DEV  $MOUNT  auto  defaults,nodev,nobootwait 0 2" >> /etc/fstab
        fi

        echo "Mount disk at $MOUNT"
        mkdir -p "$MOUNT"
        mount "$MOUNT" || true          # May fail if already mounted and busy, which occurs during retry
    fi 
}

install_disk /dev/xvdg  /mnt/ephemeral0
install_disk /dev/xvdf  /mnt/disk1

# Basic packages - probably should leave these to chef but can't see how
apt-get -q -y update
DEBIAN_FRONTEND=noninteractive apt-get -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade 
locale-gen en_GB.UTF-8
