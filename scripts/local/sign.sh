#!/bin/sh

bootstrap_arch="$1"
arch="$2"

case "$bootstrap_arch" in
	*-musl) libc="musl" ;;
	*)      libc="glibc" ;;
esac

podman container run \
	--rm \
	--env="XBPS_TARGET_ARCH=$arch" \
	--volume="$PWD/void-bins/$libc:/etc/void-bins" \
	--volume="$PWD/scripts/xbps/rindex.sh:/opt/rindex.sh" \
	--volume="$PWD/private.pem:/var/private.pem" \
	--workdir=/etc/void-bins \
	"ghcr.io/void-linux/xbps-src-masterdir:20210313rc01-$bootstrap_arch" \
	/opt/rindex.sh "$arch"
