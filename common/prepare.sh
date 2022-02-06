# Create files ahead of time so there are no errors in further scripts.
for file in $ADDED_PATH $MODIFIED_PATH $DELETED_PATH $REBUILD_PATH; do
	touch $file
done

for file in $ADDED_PATH $MODIFIED_PATH $DELETED_PATH; do
	echo "Packages to be $action":

	# NOTE: File names have to match Git filters.
	file_name=$(basename file)
	filter=$(echo "${file_name^}" | cut --characters 1)

	git diff-tree \
		-r \
		--name-only \
		--no-rename \
		--diff-filter $filter \
		$CI_COMMIT_BEFORE_SHA HEAD \
		"srcpkgs/*" \
		| cut -d / -f 2 \
		| tee $file \
		| sed "s/^/  * /" >&2
done
