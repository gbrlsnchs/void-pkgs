# Move packages to dist directory.
repo_branch="pages"
git fetch
git checkout $repo_branch || exit 1

case "$ARCH" in
    *musl* ) libc="musl" ;;
    * ) libc="glibc" ;;
esac
mkdir -p "$libc"

# Delete files related to the package in the current architecture.
for pkg in $(cat "$DELETED_PATH"); do
	rm --force "$libc/$pkg"-[0-9]*.[0-9]*.[0-9]*_[0-9]*."$ARCH".*
done
rm --force "$libc/$ARCH-repodata"

# Update all packages when there are CI changes.
if [ "$IS_CI_UPDATE" == "true" ]; then
	echo "Preparing all existing packages to get rebuilt due to CI configuration changes"
	ls -1 srcpkgs > "$REBUILD_PATH"
fi

pkgs=$(cat $ADDED_PATH $MODIFIED_PATH $REBUILD_PATH)

if [ "$pkgs" == "" ]; then
	echo "No packages to deploy!"
	exit 0
fi

binpkgs="$UPSTREAM_PATH/hostdir/binpkgs"
cp --recursive --force "$binpkgs"/* "$libc"

# Sign packages.
if [ "$PRIVATE_PEM" == "" ]; then
	echo "Missing private key!"
	exit 1
fi

echo "$PRIVATE_PEM" | base64 --decode > /tmp/privkey

xbps-rindex --add "$libc"/*."$ARCH".xbps || exit 1
xbps-rindex --privkey /tmp/privkey --sign --signedby "$GITLAB_USER_NAME" "$libc" || exit 1
xbps-rindex --privkey /tmp/privkey --sign-pkg "$libc"/*."$ARCH".xbps || exit 1

# Commit changes.
added_list=$(cat "$ADDED_PATH" | sed --regexp-extended "s/(.+)/  * \1/")
modified_list=$(cat "$MODIFIED_PATH" | sed --regexp-extended "s/(.+)/  * \1/")
deleted_list=$(cat "$DELETED_PATH" | sed --regexp-extended "s/(.+)/  * \1/")
rebuilt_list=$(cat "$REBUILD_PATH" | sed --regexp-extended "s/(.+)/  * \1/")

added_list=${added_list:-"  (None)"}
modified_list=${modified_list:-"  (None)"}
deleted_list=${deleted_list:-"  (None)"}
rebuilt_list=${rebuilt_list:-"  (None)"}

git config --global user.name "GitLab CI (job #$CI_JOB_ID)"
git config --global user.email "$GITLAB_USER_EMAIL"
git add $libc
git commit --file - << EOF
Update packages for $libc

Added packages:
$added_list

Updated packages:
$modified_list

Deleted packages:
$deleted_list

Packages rebuilt due to infrastructure changes:
$rebuilt_list
EOF

# Generate HTML.
cat << EOF > index.html
<html>
<head>
<title>$GITLAB_USER_NAME's custom Void packages</title>
<style>
table {
	border-collapse: collapse;
}
th, td {
	border: 1px solid black;
	padding: 5px;
}
</style>
</head>
<body>
<h1>Available C libraries</h1>
<table>
<thead>
<tr><th>Library</th><th>Last Updated</th></tr>
</thead>
<tbody>
EOF
for lib in *; do
	path=$(basename $lib)

	if [ "$path" == "index.html" ]; then
		continue
	fi

	last_update=$(git --no-pager log -1 --format="%ad" -- "$lib")

	printf '<tr><td><a href="%s">%s</a></td><td>%s</td></tr>' "$path" "$path" "$last_update" >> index.html
done
cat << EOF >> index.html
</tbody>
</table>
</body>
</html>
EOF

cat << EOF > "$libc/index.html"
<html>
<head>
<title>$GITLAB_USER_NAME's custom Void packages - $libc</title>
<style>
table {
	border-collapse: collapse;
}
th, td {
	border: 1px solid black;
	padding: 5px;
}
</style>
</head>
<body>
<a href="..">Go back to previous page</a>
<hr>
<h1>Available packages for $libc</h1>
<table>
<thead>
<tr><th>Package</th><th>Last Updated</th><th>Signature</th><th>Last Updated (Signature)</th></tr>
</thead>
<tbody>
EOF
for file in "$libc"/*.xbps; do
	path=$(basename $file)
	if [ "$path" == "index.html" ]; then
		continue
	fi

	last_update=$(git --no-pager log -1 --format="%ad" -- "$file")
	sig_file="$path.sig"
	last_update_sig=$(git --no-pager log -1 --format="%ad" -- "$file.sig")

	printf '<tr><td><a href="%s">%s</a></td><td>%s</td><td><a href="%s">%s</a></td><td>%s</td></tr>' \
		"$path" "$path" "$last_update" "$sig_file" "$sig_file" "$last_update_sig" >> "$libc/index.html"
done
cat << EOF >> "$libc/index.html"
</tbody>
</table>
</body>
</html>
EOF
git add index.html $libc
git commit --amend --no-edit

git remote set-url origin "https://${GITLAB_USER_LOGIN}:${ACCESS_TOKEN}@gitlab.com/${CI_PROJECT_PATH}.git"

echo "Pushing to $(git remote get-url origin)..."
git push --set-upstream --force --quiet origin $repo_branch || exit 1
echo "Done!!!"
