filter_added="A"
filter_modified="M"
filter_deleted="D"

for action in added modified deleted; do
	echo "Packages to be $action":

	file=/tmp/$action
	touch $file

	filter="filter_$action"
	git diff-tree \
		-r \
		--name-only \
		--no-rename \
		--diff-filter=${!filter} \
		HEAD HEAD~ \
		"srcpkgs/*/template" \
		| cut -d / -f 2 \
		| tee $file \
		| sed "s/^/  * /" >&2
done

# Clone upstream package repository.
dir=$(pwd)/upstream-packages

if [ ! -d $dir ]; then
	echo "Cloning upstream packages to $dir"
	git clone --depth 1 git://github.com/void-linux/void-packages.git $dir
else
	echo "Updating upstream packages in $dir"
	cd $dir
	git pull
fi

# Move elegible packages to upstream directory. This guarantees we use our own versions when
# building other packages.
eligible_pkgs=$(ls -1 srcpkgs | grep --invert-match --file /tmp/removed)
echo "The following packages will be added/updated:"
echo $eligible_pkgs | sed "s/^/ *  /"
for pkg in $eligible_pkgs; do
	cp --no-target-directory --recursive srcpkgs/$pkg $dir/$pkg
done
