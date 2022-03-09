#!/bin/sh

git clone --depth 1 https://github.com/void-linux/void-packages.git /tmp/upstream || exit 1

git fetch origin ci:ci && git worktree add /tmp/ci

eligible_pkgs=$(find srcpkgs -maxdepth 1 -path "srcpkgs/*" | grep --invert-match --file /tmp/ci/deleted)
echo "The following custom packages will be used alongside upstream packages:"
echo "$eligible_pkgs" | sed "s/^/  * /"

for src in $eligible_pkgs; do
	dst=/tmp/upstream/"$src"

	echo "Copying $src to $dst"
	cp --no-target-directory --recursive --force "$src" "$dst"
done

echo XBPS_CHROOT_CMD=ethereal >> /tmp/upstream/etc/conf
echo XBPS_ALLOW_CHROOT_BREAKOUT=yes >> /tmp/upstream/etc/conf
ln -s / /tmp/upstream/masterdir

build_pkgs=$(/tmp/upstream/xbps-src sort-dependencies "$(cat /tmp/ci/added /tmp/ci/modified /tmp/ci/rebuild)")
for pkg in $build_pkgs; do
	echo "Building package \"$pkg...\""
	if [ "$ARCH" != "$BOOTSTRAP_ARCH" ]; then
		/tmp/upstream/xbps-src -a "$ARCH" -j "$(nproc)" pkg "$pkg"
	else
		/tmp/upstream/xbps-src -j "$(nproc)" pkg "$pkg"
	fi
	echo "Finished building package \"$pkg\"!"
done
