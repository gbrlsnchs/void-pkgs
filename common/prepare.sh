# Create files ahead of time so there are no errors in further scripts.
for file in $ADDED_PATH $MODIFIED_PATH $DELETED_PATH; do
	touch $file
done

# Update _all_ packages when there are CI changes.
if [ $IS_CI_UPDATE == "true" ]; then
	echo "Preparing all packages to get rebuilt"
	ls -1 srcpkgs > "$MODIFIED_PATH"
	exit 0
fi

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
		HEAD~ HEAD \
		"srcpkgs/*" \
		| cut -d / -f 2 \
		| tee $file \
		| sed "s/^/  * /" >&2
done
