if [ "$IS_DEPLOYMENT_ONLY" == "true" ]; then
	echo "There are only changes in deploy, skipping build..."
	exit 0
fi

# Clone upstream package repository.
dir=$(pwd)/upstream-packages

if [ ! -d "$UPSTREAM_PATH" ]; then
	echo "Cloning upstream packages to $UPSTREAM_PATH"
	git clone --depth 1 git://github.com/void-linux/void-packages.git "$UPSTREAM_PATH"
else
	echo "Updating upstream packages in $UPSTREAM_PATH"
	cd "$UPSTREAM_PATH" || exit 1
	git pull
fi

# Move elegible packages to upstream directory. This guarantees we use our own versions when
# building other packages.
eligible_pkgs=$(find srcpkgs -maxdepth 1 -path "srcpkgs/*" | grep --invert-match --file "$DELETED_PATH")
echo "The following custom packages will be used alongside upstream packages:"
echo "$eligible_pkgs" | sed "s/^/  * /"

for src in $eligible_pkgs; do
	dst="$UPSTREAM_PATH/$src"

	echo "Copying $src to $dst"
	cp --no-target-directory --recursive --force "$src" "$dst"
done
# Prepare system for ethereal chroot.
echo XBPS_CHROOT_CMD=ethereal >> "$UPSTREAM_PATH/etc/conf"
echo XBPS_ALLOW_CHROOT_BREAKOUT=yes >> "$UPSTREAM_PATH/etc/conf"
ln -s / "$UPSTREAM_PATH/masterdir"

# Build packages that have been either added or modified.
cat "$ADDED_PATH" "$MODIFIED_PATH" "$REBUILD_PATH" > "$PKGS_PATH"
build_pkgs=$("$UPSTREAM_PATH/xbps-src" sort-dependencies "$(cat "$PKGS_PATH")")
for pkg in $build_pkgs; do
	echo "Building package $pkg..."
	if [ "$CROSS_COMPILE" == "true" ]; then
		"$UPSTREAM_PATH"/xbps-src -a "$ARCH" -j "$(nproc)" pkg "$pkg" || exit 1
	else
		"$UPSTREAM_PATH"/xbps-src -j "$(nproc)" pkg "$pkg" || exit 1
	fi
	echo "Finished building package $pkg!"
done
