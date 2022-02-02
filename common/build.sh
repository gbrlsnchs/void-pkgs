# Clone upstream package repository.
dir=$(pwd)/upstream-packages

if [ ! -d "$dir" ]; then
	echo "Cloning upstream packages to $dir"
	git clone --depth 1 git://github.com/void-linux/void-packages.git "$dir"
else
	echo "Updating upstream packages in $dir"
	cd "$dir" || exit 1
	git pull
fi

# Move elegible packages to upstream directory. This guarantees we use our own versions when
# building other packages.
eligible_pkgs=$(ls -1 srcpkgs | grep --invert-match --file "$DELETED_PATH")
echo "The following packages will be added/updated:"
echo "$eligible_pkgs" | sed "s/^/  * /"

for pkg in $eligible_pkgs; do
	src="srcpkgs/$pkg"
	dst="$dir/$src"

	echo "Copying $src to $dst"
	cp --no-target-directory --recursive --force "$src" "$dst"
done
# Prepare system for ethereal chroot.
echo XBPS_CHROOT_CMD=ethereal >> "$dir/etc/conf"
echo XBPS_ALLOW_CHROOT_BREAKOUT=yes >> "$dir/etc/conf"
ln -s / "$dir/masterdir"

# Build packages that have been either added or modified.
pkgs=$(cat "$ADDED_PATH" "$MODIFIED_PATH")
build_pkgs=$("$dir/xbps-src" sort-dependencies "$pkgs")
for pkg in $build_pkgs; do
	echo "Building package $pkg..."
	if [ "$CROSS_COMPILE" == "true" ]; then
		"$dir"/xbps-src -a "$ARCH" -j "$(nproc)" pkg "$pkg" || exit 1
	else
		"$dir"/xbps-src -j "$(nproc)" pkg "$pkg" || exit 1
	fi
	echo "Finished building package $pkg!"
done
