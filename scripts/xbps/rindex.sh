#!/bin/sh

rm --force *.xbps.sig *-repodata
xbps-rindex --add *.xbps || exit 1
xbps-rindex --sign --privkey /var/private.pem --signedby "Gabriel Sanches" . || exit 1
xbps-rindex --sign-pkg --privkey /var/private.pem *.xbps || exit 1
xbps-rindex --remove-obsoletes "$PWD" || exit 1
