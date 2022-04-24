#!/bin/sh

# This script is intended for building a single package, making it more granular.

bootstrap_arch="$1"
arch="$2"
pkg="$3"

echo XBPS_CHROOT_CMD=ethereal >> etc/conf
echo XBPS_ALLOW_CHROOT_BREAKOUT=yes >> etc/conf
ln -s / "$PWD"/masterdir

build_pkgs="$(./xbps-src sort-dependencies "$pkg")"
for pkg in $build_pkgs; do
	log_dir=/var/log/xbps-src

	if [ "$arch" != "$bootstrap_arch" ]; then
		extra_args="-a $arch"
	else
		extra_args="-Q"
	fi

	if ! ./xbps-src -j "$(nproc)" "$extra_args" pkg "$pkg" > "$log_dir/$pkg-$arch.log" 2>&1; then
		exit 2
	fi
done
