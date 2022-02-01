pkgs=$(cat /tmp/pkgs)

# Move packages to dist directory.
repo_branch="pages"
git switch $repo_branch || git checkout --orphan $repo_branch

libc=${LIBC:-"glibc"}
mkdir -p $libc

for pkg in $(cat /tmp/added /tmp/updated /tmp/removed); do
	rm $libc/$pkg*
done

binpkgs=$dir/hostdir/binpkgs/$pkg
cp --recursive --force $binpkgs/* $libc

# Sign packages.
ssh_dir=$HOME/.ssh
mkdir -p $ssh_dir
echo $PRIVATE_PEM > $ssh_dir/id_rsa

xbps-rindex --add $libc/*.xbps
xbps-rindex --sign --signed-by "$AUTHOR" $libc
for pkg in $pkgs; do
	xbps-rindex --sign-pkg $libc/pkg*.xbps
done

# Generate HTML.
cat << EOF > index.html
<html>
<head><title>$AUTHOR's custom Void packages</title></head>
<body>
<h1>Available C libraries</h1>
<ul>
EOF
for lib in */; do
	last_update=$(stat -c %y $lib)

	printf '<li><a href="%s">%s</a> [%s]</li>' "$lib" "$lib" "$last_update" >> index.html
done
cat << EOF >> index.html
</ul>
</body>
</html>
EOF

cat << EOF > $libc/index.html
<html>
<head><title>$AUTHOR's custom Void packages - $libc</title></head>
<body>
<h1>Available packages for $libc</h1>
<ul>
EOF
for file in $libc/*.xbps; do
	last_update=$(stat -c %y $file)
	sig_file="$file.sig"

	printf '<li><a href="%s">%s [%s] (<a href="%s">signature</a>)</li>' "$file" "$file" "$last_update" "$sig_file" >> $libc/index.html
done
cat << EOF >> $libc/index.html
</ul>
</body>
</html>
EOF

# Commit changes.
added_list=$(cat /tmp/added | sed --regexp-extended "s/(.+)/  * \1/")
updated_list=$(cat /tmp/updated | sed --regexp-extended "s/(.+)/  * \1/")
deleted_list=$(cat /tmp/deleted | sed --regexp-extended "s/(.+)/  * \1/")

added_list=${added_list:-"  (Nothing)"}
updated_list=${updated_list:-"  (Nothing)"}
deleted_list=${deleted_list:-"  (Nothing)"}

git add --all --force .
git commit --file - << EOF
Update packages for $libc

Added packages:
$added_list

Updated packages:
$updated_list

Deleted packages:
$deleted_list
EOF
git push --force --quiet $repo_branch > /dev/null
