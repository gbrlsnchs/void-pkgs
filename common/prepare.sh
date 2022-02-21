if [ "$IS_DEPLOYMENT_ONLY" == "true" ]; then
	echo "There are only changes in deploy, skipping preparation..."
	exit 0
fi

# Create files ahead of time so there are no errors in further scripts.
for file in "$ADDED_PATH" "$MODIFIED_PATH" "$DELETED_PATH" "$REBUILD_PATH"; do
	touch "$file"
done

# Get last deploy commit information from the deployment branch.
git restore --source "origin/$PAGES_BRANCH" -- "$LAST_DEPLOYMENT_COMMIT_FILE" || exit 1
mv "$LAST_DEPLOYMENT_COMMIT_FILE" "$LAST_DEPLOYMENT_COMMIT_PATH"

last_deploy_commit="$(cat "$LAST_DEPLOYMENT_COMMIT_PATH")"
last_deploy_commit="${last_deploy_commit:-"$CI_COMMIT_BEFORE_SHA"}"

for file in "$ADDED_PATH" "$MODIFIED_PATH" "$DELETED_PATH"; do
	action=$(basename $file)
	echo "Packages to be $action":

	# NOTE: File names have to match Git filters.
	filter=$(echo "${action^}" | cut --characters 1)

	git diff-tree \
		-r \
		--name-only \
		--no-rename \
		--diff-filter $filter \
		"$last_deploy_commit" HEAD \
		"srcpkgs/*" \
		| cut --delimiter / --fields 2 \
		| uniq \
		| tee "$file" \
		| sed "s/^/  * /"
done

# Update all packages when there are CI changes.
if [ "$IS_CI_UPDATE" == "true" ]; then
	echo "Preparing all existing packages that wouldn't be built to get rebuilt due to CI configuration changes"
	find srcpkgs -maxdepth 1 -path "srcpkgs/*" -printf "%f\n" \
		| grep --invert-match --file "$ADDED_PATH" \
		| grep --invert-match --file "$MODIFIED_PATH" \
		| tee "$REBUILD_PATH" \
		| sed "s/^/  * /"
fi
