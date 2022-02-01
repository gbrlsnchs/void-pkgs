# Prepare system for ethereal chroot.
echo XBPS_CHROOT_CMD=ethereal >> $dir/etc/conf
echo XBPS_ALLOW_CHROOT_BREAKOUT=yes >> $dir/etc/conf
ln -s / $dir/masterdir

# Build packages that have been either added or updated.
pkgs=$(cat /tmp/added /tmp/updated)
build_pkgs=$($dir/xbps-src sort-dependencies $pkgs)
for pkg in $build_pkgs; do
	$dir/xbps-src -j$(nproc) pkg "$pkg"
done

echo $pkgs > /tmp/pkgs
