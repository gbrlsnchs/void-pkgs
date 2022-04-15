#!/bin/sh

git clone https://github.com/gbrlsnchs/void-bins.git pages

echo "$SIGNING_KEY" > /tmp/signing_key.pem

case "$ARCH" in
    *musl* ) libc="musl" ;;
    * ) libc="glibc" ;;
esac

# Remove packages that have either been deleted or updated.
for pkg in $(cat /tmp/ci/rebuild /tmp/ci/modified /tmp/ci/deleted); do
	rm --force pages/"$libc"/"$pkg"-[0-9]*.[0-9]*.[0-9]*_[0-9]*."$ARCH".xbps
	rm --force pages/"$libc"/"$pkg"-devel-[0-9]*.[0-9]*.[0-9]*_[0-9]*."$ARCH".xbps
done

rm --force pages/"$libc"/*."$ARCH".xbps.sig
rm --force pages/"$libc"/"$ARCH"-repodata

# Copy new binaries over to correct directory.
cp --force /tmp/upstream/hostdir/binpkgs/* pages/"$libc"

# Sign the repository and its packages.
export XBPS_TARGET_ARCH="$ARCH"
xbps-rindex --add pages/"$libc"/*."$ARCH".xbps || exit 1
xbps-rindex --privkey /tmp/signing_key.pem --sign --signedby "$CI_COMMIT_AUTHOR" pages/"$libc" || exit 1
xbps-rindex --privkey /tmp/signing_key.pem --sign-pkg pages/"$libc"/*."$ARCH".xbps || exit 1
