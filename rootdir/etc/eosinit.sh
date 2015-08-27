#!/sbin/busybox sh

if [ ! -f "/system/etc/eos" ]
then
   echo "Wrong ROM, reboot...";
   reboot recovery;
else
   echo "This is EuphoriaOS, continue...";
fi

# Mount / as RW
mount -t rootfs -o remount,rw rootfs

# Initialize Synapse
chown -R root.root /res/synapse
chmod -R 777 /res/synapse
ln -s /res/synapse/uci /sbin/uci
/sbin/uci

# Initialize Wolfson Sound Control
echo "0x0FA4 0x0404 0x0170 0x1DB9 0xF233 0x040B 0x08B6 0x1977 0xF45E 0x040A 0x114C 0x0B43 0xF7FA 0x040A 0x1F97 0xF41A 0x0400 0x1068" > /sys/class/misc/wolfson_control/eq_sp_freqs
echo -5 > /sys/class/misc/wolfson_control/eq_sp_gain_1
echo 1 > /sys/class/misc/wolfson_control/eq_sp_gain_2
echo 0 > /sys/class/misc/wolfson_control/eq_sp_gain_3
echo 4 > /sys/class/misc/wolfson_control/eq_sp_gain_4
echo 3 > /sys/class/misc/wolfson_control/eq_sp_gain_5

echo 1 > /sys/class/misc/wolfson_control/switch_eq_speaker

# PVR GPU Tweaks
echo 0 > /sys/module/pvrsrvkm/parameters/gPVRDebugLevel
echo 0 > /sys/module/pvrsrvkm/parameters/gPVREnableVSync

# I/O Tweaks
for i in /sys/block/*/queue/add_random;do echo 0 > $i;done

# Initialize NTFS Driver
mkdir -p /mnt/ntfs
chmod 777 /mnt/ntfs
mount -o mode=0777,gid=1000 -t tmpfs tmpfs /mnt/ntfs

# Remove unused auditd binary
mount -w -o remount /system
rm -f /system/bin/auditd

# Initialize SuperSU
set -e

if [[ -f "/system/bin/mksh" ]]; then
	cp -p "/system/bin/mksh" "/system/xbin/sugote-mksh"
else
	cp -p "/system/bin/sh" "/system/xbin/sugote-mksh"
fi

mkdir -p "/system/bin/.ext"
chmod 0777 "/system/bin/.ext"
cp -p "/system/xbin/su" "/system/bin/.ext/.su"

rm -f "/system/bin/app_process"
ln -s "/system/xbin/daemonsu" "/system/bin/app_process"

for BIT in "64" "32"; do
	if [[ -f "/system/bin/app_process${BIT}" ]]; then
		if [[ ! -f "/system/bin/app_process${BIT}_original" ]]; then
			mv "/system/bin/app_process${BIT}" "/system/bin/app_process${BIT}_original"
			ln -s "/system/xbin/daemonsu" "/system/bin/app_process${BIT}"
		fi
		if [[ ! -f "/system/bin/app_process_init" ]]; then
			cp -p "/system/bin/app_process${BIT}_original" "/system/bin/app_process_init"
		fi
	fi
done

exit 0
