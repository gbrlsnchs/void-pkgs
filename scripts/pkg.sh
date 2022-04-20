#!/bin/sh

bootstrap_arch="$1"
arch="$2"

echo XBPS_CHROOT_CMD=ethereal >> /tmp/upstream/etc/conf
echo XBPS_ALLOW_CHROOT_BREAKOUT=yes >> /tmp/upstream/etc/conf
ln -s / /tmp/upstream/masterdir

build_pkgs="$(/tmp/upstream/xbps-src sort-dependencies "$(cat /tmp/class/A /tmp/class/M)")"
for pkg in $build_pkgs; do
	log_dir="/var/log/xbps-src/$pkg-$arch"

	if [ "$arch" != "$bootstrap_arch" ]; then
		extra_args="-a $arch"
	else
		extra_args="-Q"
	fi

	if /tmp/upstream/xbps-src -j "$(nproc)" "$extra_args" pkg "$pkg" > "$log_dir".log; then
		echo "Finished building package '$pkg' for '$arch' architecture"
	else
		echo "Package '$pkg' failed to build for '$arch' architecture"
	fi
done
