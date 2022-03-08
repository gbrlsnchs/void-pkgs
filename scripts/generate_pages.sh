#!/bin/sh

git fetch origin ci:ci && git worktree add /tmp/ci

added_list=$(cat /tmp/ci/added | sed --regexp-extended "s/(.+)/  * \1/")
modified_list=$(cat /tmp/ci/modified | sed --regexp-extended "s/(.+)/  * \1/")
deleted_list=$(cat /tmp/ci/deleted | sed --regexp-extended "s/(.+)/  * \1/")
rebuild_list=$(cat /tmp/ci/rebuild | sed --regexp-extended "s/(.+)/  * \1/")

added_list=${added_list:-"  (none)"}
modified_list=${modified_list:-"  (none)"}
deleted_list=${deleted_list:-"  (none)"}
rebuild_list=${rebuilt_list:-"  (none)"}

changelog_file="/tmp/changelog.txt"
cat << EOF > "$changelog_file"
Deploy packages for $libc

Added packages:
$added_list

Updated packages:
$modified_list

Deleted packages:
$deleted_list

Packages that have been rebuilt:
$rebuild_list
EOF

# Update templates
cat << EOF > index.html
<html>
<head>
<title>$CI_REPO_OWNER's personal XBPS binary repository</title>
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
<a href="$CI_REPO_LINK">Go to source</a>
<hr>
<h1>Available C standard libraries</h1>
<table>
<thead>
<tr><th>Library</th><th>Size</th><th>Last Update</th></tr>
</thead>
<tbody>
EOF
for libc in */; do
	path=$(basename "$libc")
	last_update=$(git --no-pager log -1 --format="%ad" -- "$libc")

	printf '<tr><td><a href="%s">%s</a></td><td>%s</td><td>%s</td></tr>' \
		"$path" "$path" "$(du --human-readable "$libc" | cut --fields 1)" "$last_update" >> index.html

	cat << EOF > "$libc/index.html"
<html>
<head>
<title>$CI_REPO_OWNER's custom Void packages - $libc</title>
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
		path=$(basename $file)
		if [ "$path" == "index.html" ]; then
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
