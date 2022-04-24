#!/bin/sh

bootstrap_arch="$1"
arch="$2"
pkg="$3"

case "$bootstrap_arch" in
	*-musl) libc="musl" ;;
	*)      libc="glibc" ;;
esac

podman container run \
	--rm \
	--volume="$PWD/void-packages:/etc/void-packages" \
	--volume="$PWD/void-bins/$libc:/etc/void-packages/hostdir/binpkgs" \
	--volume="$PWD/out/log:/var/log/xbps-src" \
	--volume="$PWD/scripts/xbps/pkg.sh:/opt/pkg.sh" \
	--workdir=/etc/void-packages \
	"ghcr.io/void-linux/xbps-src-masterdir:20210313rc01-$bootstrap_arch" \
	/opt/pkg.sh "$bootstrap_arch" "$arch" "$pkg"
