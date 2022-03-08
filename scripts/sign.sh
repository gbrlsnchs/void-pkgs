#!/bin/sh

git fetch && git switch pages
git fetch origin pre:pre && git worktree add /tmp/pre
git fetch origin ci:ci && git worktree add /tmp/ci

echo "$SIGNING_KEY" > /tmp/signing_key

# Delete files related to the package in the current architecture.
for libc in *; do
	if [ ! -d "$libc" ]; then
		continue
	fi

	# Clean obsolete packages and existing repodata.
	for pkg in $(cat /tmp/ci/modified /tmp/ci/deleted); do
		rm --force "$libc/$pkg"-[0-9]*.[0-9]*.[0-9]*_[0-9]*.*.*
	done

	cp --force /tmp/pre/"$libc"/* "$libc"
	echo "All files in $libc:"
	find "$libc" -maxdepth 1 -path "$libc/*" -printf "%f\n" | sed "s/^/  * /"

	for repodata in "$libc"/*-repodata; do
		arch="${repodata%-repodata}"
		export XBPS_TARGET_ARCH="$arch"

		# Sign the repository and its packages.
		xbps-rindex --add "$libc"/*."$arch".xbps || exit 1
		xbps-rindex --privkey /tmp/signing_key --sign-pkg "$libc"/*."$arch".xbps || exit 1

		unset XBPS_TARGET_ARCH
	done

	xbps-rindex --privkey /tmp/signing_key --sign --signedby "$CI_COMMIT_AUTHOR" "$libc" || exit 1
done
