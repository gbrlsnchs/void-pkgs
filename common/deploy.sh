# Move packages to dist directory.
repo_branch="pages"
git switch $repo_branch || git checkout --orphan $repo_branch || exit 1

case "$ARCH" in
    *musl* ) libc="musl" ;;
    * ) libc="glibc" ;;
esac
mkdir -p "$libc"

# Delete files related to the package in the current architecture.
for pkg in $(cat "$DELETED_PATH"); do
	rm --force "$libc/$pkg"-[0-9]*.[0-9]*.[0-9]*_[0-9]*."$ARCH".*
done

pkg=$(cat $ADDED_PATH $MODIFIED_PATH)

if [ "$pkg" == "" ]; then
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
	xbps-rindex --privkey /tmp/privkey --sign-pkg --force "$libc"/pkg*."$ARCH".xbps || exit 1
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
added_list=$(cat "$ADDED_PATH" | sed --regexp-extended "s/(.+)/  * \1/")
modified_list=$(cat "$MODIFIED_PATH" | sed --regexp-extended "s/(.+)/  * \1/")
deleted_list=$(cat "$DELETED_PATH" | sed --regexp-extended "s/(.+)/  * \1/")

added_list=${added_list:-"  (Nothing)"}
modified_list=${modified_list:-"  (Nothing)"}
deleted_list=${deleted_list:-"  (Nothing)"}

git config --global user.name "GitLab CI (job #$CI_JOB_ID)"
git config --global user.email "$GITLAB_USER_EMAIL"
git add --all --force index.html $libc
git commit --file - << EOF
Update packages for $libc

Added packages:
$added_list

Updated packages:
$modified_list

Deleted packages:
$deleted_list
EOF

git remote set-url origin "$CI_REPOSITORY_URL"

echo "Pushing to $(git remote get-url origin)..."
git push --force --quiet $repo_branch || exit 1
echo "Done!!!"
