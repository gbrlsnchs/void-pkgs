git switch trunk || exit 1

upstream_dir="$(pwd)/upstream"

if [ ! -d "$upstream_dir" ]; then
	echo "Cloning upstream packages to $upstream_dir"
	git clone --depth 1 git://github.com/void-linux/void-packages.git "$upstream_dir" || exit 1
else
	echo "Updating upstream packages in $upstream_dir"
	cd "$upstream_dir"
fi

git restore --source origin/ci -- added modified deleted rebuild

eligible_pkgs=$(find srcpkgs -maxdepth 1 -path "srcpkgs/*" | grep --invert-match --file deleted)
echo "The following custom packages will be used alongside upstream packages:"
echo "$eligible_pkgs" | sed "s/^/  * /"

for src in "$eligible_pkgs"; do
	dst="$upstream_dir"/"$src"

	echo "Copying $src to $dst"
	cp --no-target-directory --recursive --force "$src" "$dst"
done

echo XBPS_CHROOT_CMD=ethereal >> "$upstream_dir/etc/conf"
echo XBPS_ALLOW_CHROOT_BREAKOUT=yes >> "$upstream_dir/etc/conf"
ln -s / "$upstream_dir/masterdir"

build_pkgs=$("$upstream_dir/xbps-src" sort-dependencies "$(cat added modified rebuild)")
for pkg in $build_pkgs; do
	echo "Building package \"$pkg...\""
	if [ "$ARCH" != "$BOOTSTRAP_ARCH" ]; then
		"$upstream_dir"/xbps-src -a "$ARCH" -j "$(nproc)" pkg "$pkg" || exit 1
	else
		"$upstream_dir"/xbps-src -j "$(nproc)" pkg "$pkg" || exit 1
	fi
	echo "Finished building package \"$pkg\"!"
done

git fetch && git worktree add pre
mkdir --parents pre/"$LIBC"
cp --force "$upstream_dir"/hostdir/binpkgs/* pre/"$LIBC"
