#!/bin/sh

git switch pages
git fetch origin pre:pre && git worktree add /tmp/pre
git fetch origin ci:ci && git worktree add /tmp/ci

echo "$SIGNING_KEY" > /tmp/signing_key

# Delete files related to the package in the current architecture.
for libc in */; do
	for pkg in $(cat "$MODIFIED_PATH" "$DELETED_PATH"); do
		rm --force "$libc/$pkg"-[0-9]*.[0-9]*.[0-9]*_[0-9]*."$ARCH".*
	done

	cp --force /tmp/pre/"$libc"/* "$libc"

	xbps-rindex --add "$libc"/*.xbps || exit 1
	xbps-rindex --privkey /tmp/signing_key --sign --signedby "$CI_COMMIT_AUTHOR" "$libc" || exit 1
	xbps-rindex --privkey /tmp/signing_key --sign-pkg "$libc"/*.xbps || exit 1
done
