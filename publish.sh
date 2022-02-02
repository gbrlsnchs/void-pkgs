added_label="added"
modified_label="modified"
deleted_label="deleted"

declare filter_$added_label="A"
declare filter_$modified_label="M"
declare filter_$deleted_label="D"

declare ${added_label}_list=""
declare ${modified_label}_list=""
declare ${deleted_label}_list=""

for action in $added_label $modified_label $deleted_label; do
	echo "Packages to be $action":

	file="/tmp/$action"
	touch "$file"

	filter="filter_$action"

	git diff-tree \
		-r \
		--name-only \
		--no-rename \
		--diff-filter=${!filter} \
		HEAD~ HEAD \
		"srcpkgs/*" \
		| cut -d / -f 2 \
		| tee $file \
		| sed "s/^/  * /" >&2
done

# Clone upstream package repository.
dir=$(pwd)/upstream-packages

if [ ! -d "$dir" ]; then
	echo "Cloning upstream packages to $dir"
	git clone --depth 1 git://github.com/void-linux/void-packages.git "$dir"
else
	echo "Updating upstream packages in $dir"
	cd "$dir" || exit 1
	git pull
fi

# Move elegible packages to upstream directory. This guarantees we use our own versions when
# building other packages.
eligible_pkgs=$(ls -1 srcpkgs | grep --invert-match --file "/tmp/$deleted_label")
echo "The following packages will be added/updated:"
echo "$eligible_pkgs" | sed "s/^/  * /"

for pkg in $eligible_pkgs; do
	cp --no-target-directory --recursive "srcpkgs/$pkg" "$dir/$pkg"
done
# Prepare system for ethereal chroot.
echo XBPS_CHROOT_CMD=ethereal >> "$dir/etc/conf"
echo XBPS_ALLOW_CHROOT_BREAKOUT=yes >> "$dir/etc/conf"
ln -s / "$dir/masterdir"

# Build packages that have been either added or modified.
pkgs=$(cat "/tmp/$added_label" "/tmp/$modified_label")
build_pkgs=$("$dir/xbps-src" sort-dependencies "$pkgs")
for pkg in $build_pkgs; do
	echo "Building package $pkg..."
	"$dir"/xbps-src -j"$(nproc)" pkg "$pkg"
	echo "Finished building package $pkg!"
done

# Move packages to dist directory.
repo_branch="pages"
git switch $repo_branch || git checkout --orphan $repo_branch

libc=${LIBC:-"glibc"}
mkdir -p "$libc"

for pkg in $(cat "/tmp/$added_label" "/tmp/$modified_label" "/tmp/$deleted_label"); do
	rm "$libc/$pkg"*
done

binpkgs="$dir/hostdir/binpkgs/$pkg"
cp --recursive --force "$binpkgs"/* "$libc"

# Sign packages.
ssh_dir=$HOME/.ssh
mkdir -p $ssh_dir
echo "$PRIVATE_PEM" | base64 --decode > "$ssh_dir/id_rsa"

xbps-rindex --add "$libc"/*.xbps
xbps-rindex --sign --signedby "$GITLAB_USER_NAME" "$libc"
for pkg in $pkgs; do
	xbps-rindex --sign-pkg "$libc"/pkg*.xbps
done

# Generate HTML.
cat << EOF > index.html
<html>
<head><title>$GITLAB_USER_NAME's custom Void packages</title></head>
<body>
<h1>Available C libraries</h1>
<ul>
EOF
for lib in */; do
	last_update=$(stat -c %y "$lib")

	printf '<li><a href="%s">%s</a> [%s]</li>' "$lib" "$lib" "$last_update" >> index.html
done
cat << EOF >> index.html
</ul>
</body>
</html>
EOF

cat << EOF > "$libc/index.html"
<html>
<head><title>$GITLAB_USER_NAME's custom Void packages - $libc</title></head>
<body>
<h1>Available packages for $libc</h1>
<ul>
EOF
for file in "$libc"/*.xbps; do
	last_update=$(stat -c %y "$file")
	sig_file="$file.sig"

	printf '<li><a href="%s">%s [%s] (<a href="%s">signature</a>)</li>' "$file" "$file" "$last_update" "$sig_file" >> "$libc/index.html"
done
cat << EOF >> "$libc/index.html"
</ul>
</body>
</html>
EOF

# Commit changes.
added_list=$(cat "/tmp/$added_label" | sed --regexp-extended "s/(.+)/  * \1/")
modified_list=$(cat "/tmp/$modified_label" | sed --regexp-extended "s/(.+)/  * \1/")
deleted_list=$(cat "/tmp/$deleted_label" | sed --regexp-extended "s/(.+)/  * \1/")

added_list=${added_list:-"  (Nothing)"}
modified_list=${modified_list:-"  (Nothing)"}
deleted_list=${deleted_list:-"  (Nothing)"}

git config --global user.name "GitLab CI (job #$CI_JOB_ID)"
git config --global user.email "$GITLAB_USER_EMAIL"
git add --all --force .
git commit --file - << EOF
Update packages for $libc

Added packages:
$added_list

Updated packages:
$modified_list

Deleted packages:
$deleted_list
EOF
git push --force --quiet "https://$CI_REPOSITORY_URL" $repo_branch
