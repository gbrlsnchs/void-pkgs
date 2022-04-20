#!/bin/sh

filter="$1"

if [ -z "$filter" ]; then
	echo "error: --diff-filter argument is missing"
	exit 1
fi

base="$(cat data/commit_index)"
tip="$(git rev-parse HEAD)"

git diff-tree \
	-r \
	--name-only \
	--no-rename \
	--diff-filter "$filter" \
	"${base:-"$tip"}" "$tip" \
	-- "srcpkgs/*/template"
