#!/bin/sh

bootstrap_arch="$1"
pkg="$2"

podman container run \
	--rm \
	--userns=keep-id \
	--volume="/tmp/void-packages:/etc/void-packages" \
	--volume="$PWD/srcpkgs:/etc/void-packages/srcpkgs" \
	--volume=/bin/xdistdir:/bin/xdistdir \
	--volume=/bin/xgensum:/bin/xgensum \
	--workdir=/etc/void-packages \
	"ghcr.io/void-linux/xbps-src-masterdir:20210313rc01-$bootstrap_arch" \
	xgensum -f -i "$pkg"
