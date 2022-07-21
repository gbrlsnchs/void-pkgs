#!/bin/sh

set -e

arch="$1"

rm --force ./*."$arch".xbps.sig ./"$arch"-repodata
xbps-rindex --add ./*."$arch".xbps
xbps-rindex --sign --privkey /var/private.pem --signedby "Gabriel Sanches" .
xbps-rindex --sign-pkg --privkey /var/private.pem ./*."$arch".xbps
xbps-rindex --remove-obsoletes "$PWD"
