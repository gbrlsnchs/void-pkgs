#!/bin/sh

get_size() {
	du --human-readable "$1" | cut --fields 1
}

get_last_update() {
	git --no-pager log -1 --format="%ad" -- "$1"
}

repo_url="$(
	git config --get remote.origin.url | \
	sed \
		--expression "s/git@\(.*\)\.git/\1/" \
		--expression "s|:|/|"
)"
repo_branch="$(git rev-parse --abbrev-ref HEAD)"

author="Gabriel Sanches"
meta='
	<meta name="viewport" content="width=device-width, initial-scale=1">
'
common_styles='
	table {
		border-collapse: collapse;
	}
	th, td {
		border: 1px solid black;
		padding: 5px;
	}
	pre {
		font-size: 1.2em;
	}
'

cd void-bins || exit 1
git add --all && git commit --message "Update repository binaries"

for libc in *; do
	if [ ! -d "$libc" ]; then
		continue
	fi

	rows=""

	for pkgbin in "$libc"/*.xbps; do
		pkgname="$(basename "$pkgbin")"
		pkgsize="$(get_size "$pkgbin")"
		last_update="$(get_last_update "$pkgbin")"
		last_update_sig="$(get_last_update "$pkgbin.sig")"
		original_pkgname="$(echo "$pkgname" | sed --regexp-extended "s/(.*)-[0-9](\.[0-9]*)?(\.[0-9]*)?(.*)?_[0-9]*\..*/\1/")"

		entries="$(
			sed \
				--expression "s/{{name}}/$pkgname/g" \
				--expression "s/{{size}}/$pkgsize/g" \
				--expression "s/{{last_update}}/$last_update/g" \
				--expression "s|{{source_url}}|https://$repo_url/src/branch/$repo_branch/srcpkgs/$original_pkgname|g" \
				../templates/pkgs.html
		)"
		rows="$rows\n$entries"
	done

	awk \
		-v author="$author" \
		-v meta="$meta" \
		-v common_styles="$common_styles" \
		-v libc="$libc" \
		-v rows="$rows" \
		'{
			sub(/{{author}}/, author);
			sub(/{{meta}}/, meta);
			sub(/{{common_styles}}/, common_styles);
			sub(/{{libc}}/, libc);
			sub(/{{rows}}/, rows);
			print;
		}' \
		../templates/repo.html > "$libc/index.html"
	
	libname="$(basename "$libc")"
	libsize="$(get_size "$libc")"
	last_update="$(get_last_update "$libc")"

	entries="$(
		sed \
			--expression "s/{{name}}/$libname/g" \
			--expression "s/{{size}}/$libsize/g" \
			--expression "s/{{last_update}}/$last_update/g" \
			../templates/libc.html
	)"
	librows="$librows\n$entries"
done

awk \
	-v author="$author" \
	-v meta="$meta" \
	-v common_styles="$common_styles" \
	-v repo_url="https://$repo_url" \
	-v rows="$librows" \
	'{
		sub(/{{author}}/, author);
		sub(/{{meta}}/, meta);
		sub(/{{common_styles}}/, common_styles);
		sub(/{{repo_url}}/, repo_url);
		sub(/{{rows}}/, rows);
		print;
	}' \
	../templates/home.html > "index.html"

git add --all && git commit --message "Update repository pages"
