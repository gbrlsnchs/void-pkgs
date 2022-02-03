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

pkgs=$(cat $ADDED_PATH $MODIFIED_PATH)

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

xbps-rindex --add --force "$libc"/*."$ARCH".xbps || exit 1
xbps-rindex --privkey /tmp/privkey --sign --signedby "$GITLAB_USER_NAME" "$libc" || exit 1
for pkg in $pkgs; do
	echo "Signing package $pkg"
	xbps-rindex --privkey /tmp/privkey --sign-pkg --force "$libc/$pkg"-[0-9]*.[0-9]*.[0-9]*_[0-9]*."$ARCH".xbps || exit 1
done

# Generate HTML.
cat << EOF > index.html
<html>
<head><title>$GITLAB_USER_NAME's custom Void packages</title></head>
<body>
<h1>Available C libraries</h1>
<ul>
EOF
for lib in *; do
	path=$(basename $lib)

	if [ "$path" == "index.html" ]; then
		continue
	fi

	last_update=$(stat -c %y "$lib")

	printf '<li><a href="%s">%s</a> [%s]</li>' "$path" "$path" "$last_update" >> index.html
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
	path=$(basename $file)
	if [ "$path" == "index.html" ]; then
		continue
	fi

	last_update=$(stat -c %y "$file")
	sig_file="$path.sig"

	printf '<li><a href="%s">%s</a> [%s] (<a href="%s">signature</a>)</li>' "$path" "$path" "$last_update" "$sig_file" >> "$libc/index.html"
done
cat << EOF >> "$libc/index.html"
</ul>
</body>
</html>
EOF

# Commit changes.
added_list=$(cat "$ADDED_PATH" | sed --regexp-extended "s/(.+)/  * \1/")
modified_list=$(cat "$MODIFIED_PATH" | sed --regexp-extended "s/(.+)/  * \1/")
deleted_list=$(cat "$DELETED_PATH" | sed --regexp-extended "s/(.+)/  * \1/")

added_list=${added_list:-"  (Nothing)"}
modified_list=${modified_list:-"  (Nothing)"}
deleted_list=${deleted_list:-"  (Nothing)"}

git config --global user.name "GitLab CI (job #$CI_JOB_ID)"
git config --global user.email "$GITLAB_USER_EMAIL"
git add index.html $libc
git commit --file - << EOF
Update packages for $libc

Added packages:
$added_list

Updated packages:
$modified_list

Deleted packages:
$deleted_list
EOF

git remote set-url origin "https://${GITLAB_USER_LOGIN}:${ACCESS_TOKEN}@gitlab.com/${CI_PROJECT_PATH}.git"

echo "Pushing to $(git remote get-url origin)..."
git push --set-upstream --force --quiet origin $repo_branch || exit 1
echo "Done!!!"