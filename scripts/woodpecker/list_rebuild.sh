#!/bin/sh

echo "Preparing all existing packages that wouldn't be built to get rebuilt due to CI configuration changes"
find srcpkgs -maxdepth 1 -path "srcpkgs/*" -printf "%f\n" \
	| grep --invert-match --file ci/added \
	| grep --invert-match --file ci/modified \
	| tee ci/rebuild \
	| sed "s/^/  * /"
