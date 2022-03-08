#!/bin/sh

git fetch pages:pages && git switch pages

echo "$SIGNING_KEY" > /tmp/signing_key

case "$ARCH" in
    *musl* ) libc="musl" ;;
    * ) libc="glibc" ;;
esac

# Remove packages that have either been deleted or updated.
for pkg in $(cat /tmp/ci/modified /tmp/ci/deleted); do
	rm --force "$libc/$pkg"-[0-9]*.[0-9]*.[0-9]*_[0-9]*."$ARCH".*
done

# Copy new binaries over to correct directory.
cp --force /tmp/upstream/hostdir/binpkgs/* "$libc"

# Sign the repository and its packages.
export XBPS_TARGET_ARCH="$ARCH"
xbps-rindex --add "$libc"/*."$ARCH".xbps || exit 1
xbps-rindex --privkey /tmp/signing_key --sign-pkg "$libc"/*."$ARCH".xbps || exit 1
xbps-rindex --privkey /tmp/signing_key --sign --signedby "$CI_COMMIT_AUTHOR" "$libc" || exit 1
