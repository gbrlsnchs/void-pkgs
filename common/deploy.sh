# Move packages to dist directory.
repo_branch="pages"
git switch $repo_branch || git checkout --orphan $repo_branch || exit 1

case "$ARCH" in
    *musl* ) libc="musl" ;;
    * ) libc="glibc" ;;
esac
mkdir -p "$libc"

for pkg in $(cat "$ADDED_PATH" "$MODIFIED_PATH" "$DELETED_PATH"); do
	rm --force "$libc/$pkg"*
done

if [ pkg == "" ]; then
	echo "No packages to deploy!"
	exit 0
fi

binpkgs="$dir/hostdir/binpkgs/$pkg"
cp --recursive --force "$binpkgs"/* "$libc"

# Sign packages.
ssh_dir=$HOME/.ssh
mkdir -p $ssh_dir
echo "$PRIVATE_PEM" | base64 --decode > "$ssh_dir/id_rsa"

xbps-rindex --add "$libc"/*.xbps || exit 1
xbps-rindex --sign --signedby "$GITLAB_USER_NAME" "$libc" || exit 1
for pkg in $pkgs; do
	xbps-rindex --sign-pkg "$libc"/pkg*.xbps || exit 1
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
git push --force --quiet "$CI_REPOSITORY_URL" $repo_branch || exit 1
