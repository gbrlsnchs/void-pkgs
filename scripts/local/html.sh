#!/bin/sh

get_size() {
	du --human-readable "$1" | cut --fields 1
}

get_last_update() {
	git --no-pager log -1 --format="%ad" -- "$1"
}

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
		last_update_sig=$(get_last_update "$pkgbin.sig")

		entries="$(
			sed \
				--expression "s/{{name}}/$pkgname/g" \
				--expression "s/{{size}}/$pkgsize/g" \
				--expression "s/{{last_update}}/$last_update/g" \
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
	-v rows="$librows" \
	'{
		sub(/{{author}}/, author);
		sub(/{{meta}}/, meta);
		sub(/{{common_styles}}/, common_styles);
		sub(/{{rows}}/, rows);
		print;
	}' \
	../templates/home.html > "index.html"

git add --all && git commit --message "Update repository pages"
