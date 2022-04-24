#!/bin/sh

error=0
warn=1
info=2

print_header() {
	level=$1

	if [ $level -eq $error ]; then
		prefix="$(tput setaf 1)ERROR$(tput sgr0)" 
	elif [ $level -eq $warn ]; then
		prefix="$(tput setaf 3)WARN$(tput sgr0)" 
	elif [ $level -eq $info ]; then
		prefix="$(tput setaf 4)INFO$(tput sgr0)"
	fi

	msg="$2"

	printf "%s%s\t%s\n" "$(tput bold)" "$prefix" "$msg"
}

print_msg() {
	msg="$1"

	if [ -z "$msg" ]; then
		return
	fi

	echo "$(tput setaf 7)$msg$(tput sgr0)" | sed "s/^/\t/"
}
