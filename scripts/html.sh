#!/bin/sh

libc="$1"
author="Gabriel Sanches"

changelog_msg="$(cat out/changelog)"

# Update templates
cd void-bins
cat << EOF > index.html
<html>
<head>
<title>$author's personal XBPS binary repository</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
table {
	border-collapse: collapse;
}
th, td {
	border: 1px solid black;
	padding: 5px;
}
pre {
	overflow: visible;
	width: fit-content;
	border: 1px solid black;
	padding: 15px;
}
</style>
</head>
<body>
<a href="https://codeberg.org/gbrlsnchs/void-pkgs">Go to source</a>
<hr>
<h1>Available C standard libraries</h1>
<table>
<thead>
<tr><th>Library</th><th>Size</th><th>Last Update</th></tr>
</thead>
<tbody>
EOF
for libc in *; do
	if [ ! -d "$libc" ]; then
		continue
	fi

	path=$(basename "$libc")
	last_update=$(git --no-pager log -1 --format="%ad" -- "$libc")

	printf '<tr><td><a href="%s">%s</a></td><td>%s</td><td>%s</td></tr>' \
		"$path" "$path" "$(du --human-readable "$libc" | cut --fields 1)" "$last_update" >> index.html

	cat << EOF > "$libc"/index.html
<html>
<head>
<title>$author's custom Void packages - $libc</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
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
<tr><th>Package</th><th>Size</th><th>Last Update</th><th>Signature</th><th>Signed At</th></tr>
</thead>
<tbody>
EOF
	for file in "$libc"/*.xbps; do
		path="$(basename "$file")"
		if [ "$path" = "index.html" ]; then
			continue
		fi

		last_update=$(git --no-pager log -1 --format="%ad" -- "$file")
		sig_file="$path.sig"
		last_update_sig=$(git --no-pager log -1 --format="%ad" -- "$file.sig")

		printf '<tr><td><a href="%s">%s</a></td><td>%s</td><td>%s</td><td><a href="%s">%s</a></td><td>%s</td></tr>' \
			"$path" "$path" "$(du --human-readable "$file" | cut --fields 1)" "$last_update" "$sig_file" "$sig_file" "$last_update_sig" \
			>> "$libc/index.html"
	done

	cat << EOF >> "$libc/index.html"
</tbody>
</table>
</body>
</html>
EOF
done
cat << EOF >> index.html
</tbody>
</table>
<h1>Latest Changelog</h1>
<pre><code>$changelog_msg</code></pre>
</body>
</html>
EOF
