#!/bin/sh

. ./scripts/common/print.sh

if [ ! -d /tmp/void-packages ]; then
	print_header $info "Cloning helper 'void-packages'"
	if ! git clone --depth 1 https://github.com/void-linux/void-packages.git /tmp/void-packages > out/msg 2>&1; then
		print_header $error "Could not clone helper 'void-packages'"
		print_msg "$(cat out/msg)"
		exit 1
	fi

	print_header $info "Initializing helper 'void-packages'"
	if ! /tmp/void-packages/xbps-src binary-bootstrap > out/msg 2>&1; then
		print_header $error "Could not initialize helper 'void-packages'"
		print_msg "$(cat out/msg)"
		exit 1
	fi
fi
