#!/bin/sh

git fetch && git restore --source "origin/ci" -- "commit_index"

commit_index="$(cat commit_index)"
commit_index="${commit_index:-"$CI_PREV_COMMIT_SHA"}"

echo "$commit_index" > commit_index

for file in "added" "modified" "deleted"; do
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
		"$commit_index" trunk \
		-- "srcpkgs/*" \
		| cut --delimiter / --fields 2 \
		| uniq \
		| tee "$file" \
		| sed "s/^/  * /"
done
