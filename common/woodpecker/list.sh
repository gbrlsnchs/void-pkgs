#!/bin/sh

git fetch && git worktree add ci

commit_index="$(cat ci/commit_index)"
tip="$(git rev-parse HEAD)"

for file in added modified deleted; do
	action=$(basename $file)
	echo "List of packages to be $action":

	# NOTE: File names have to match Git filters.
	# This is will give us "A" for "added", "M" for modified and "D" for deleted.
	filter=$(echo "$action" | cut --characters 1 | tr "[:lower:]" "[:upper:]")

	git diff-tree \
		-r \
		--name-only \
		--no-rename \
		--diff-filter "$filter" \
		"$commit_index" "$tip" \
		-- "srcpkgs/*" \
		| cut --delimiter / --fields 2 \
		| uniq \
		| tee "ci/$file" \
		| sed "s/^/  * /"
done
