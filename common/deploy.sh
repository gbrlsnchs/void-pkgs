case "$ARCH" in
    *musl* ) libc="musl" ;;
    * ) libc="glibc" ;;
esac
mkdir -p "public/$libc"

# Delete files related to the package in the current architecture.
for pkg in $(cat "$DELETED_PATH"); do
	rm --force "public/$libc/$pkg"-[0-9]*.[0-9]*.[0-9]*_[0-9]*."$ARCH".*
done

pkg=$(cat $ADDED_PATH $MODIFIED_PATH)

if [ "$pkg" == "" ]; then
	echo "No packages to deploy!"
	exit 0
fi

binpkgs="$UPSTREAM_PATH/hostdir/binpkgs"
cp --recursive --force "$binpkgs"/* "public/$libc"

# Sign packages.
if [ "$PRIVATE_PEM" == "" ]; then
	echo "Missing private key!"
	exit 1
fi

echo "$PRIVATE_PEM" | base64 --decode > /tmp/privkey

xbps-rindex --add --force "public/$libc"/*."$ARCH".xbps || exit 1
xbps-rindex --privkey /tmp/privkey --sign --signedby "$GITLAB_USER_NAME" "public/$libc" || exit 1
for pkg in $pkgs; do
	xbps-rindex --privkey /tmp/privkey --sign-pkg --force "public/$libc"/pkg*."$ARCH".xbps || exit 1
done

# Generate HTML.
cat << EOF > public/index.html
<html>
<head><title>$GITLAB_USER_NAME's custom Void packages</title></head>
<body>
<h1>Available C libraries</h1>
<ul>
EOF
for lib in public/*; do
	last_update=$(stat -c %y "$lib")

	printf '<li><a href="%s">%s</a> [%s]</li>' "$lib" "$lib" "$last_update" >> index.html
done
cat << EOF >> public/index.html
</ul>
</body>
</html>
EOF

cat << EOF > "public/$libc/index.html"
<html>
<head><title>$GITLAB_USER_NAME's custom Void packages - $libc</title></head>
<body>
<h1>Available packages for $libc</h1>
<ul>
EOF
for file in "public/$libc"/*.xbps; do
	last_update=$(stat -c %y "$file")
	sig_file="$file.sig"

	printf '<li><a href="%s">%s</a> [%s] (<a href="%s">signature</a>)</li>' "$file" "$file" "$last_update" "$sig_file" >> "$libc/index.html"
done
cat << EOF >> "public/$libc/index.html"
</ul>
</body>
</html>
EOF
