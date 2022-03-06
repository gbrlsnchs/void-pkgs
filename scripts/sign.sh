#!/bin/sh

git fetch && git switch pages
git fetch origin pre:pre && git worktree add /tmp/pre
git fetch origin ci:ci && git worktree add /tmp/ci

echo "$SIGNING_KEY" > /tmp/signing_key

# Delete files related to the package in the current architecture.
for libc in */; do
	# Clean obsolete packages and existing repodata.
	for pkg in $(cat /tmp/ci/modified /tmp/ci/deleted); do
		rm --force "$libc/$pkg"-[0-9]*.[0-9]*.[0-9]*_[0-9]*.*.*
	done
	rm --force "$libc"/*-repodata

	cp --force /tmp/pre/"$libc"/* "$libc"
	echo "All files in $libc:"
	find "$libc" -maxdepth 1 -path "$libc/*" -printf "%f\n" | sed "s/^/  * /"

	# Sign the repository and its packages.
	xbps-rindex --add "$libc"/*.xbps || exit 1
	xbps-rindex --privkey /tmp/signing_key --sign --signedby "$CI_COMMIT_AUTHOR" "$libc" || exit 1
	xbps-rindex --privkey /tmp/signing_key --sign-pkg "$libc"/*.xbps || exit 1
done
