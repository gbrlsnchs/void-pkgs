# My custom Void packages
[![Woodpecker CI](https://ci.codeberg.org/api/badges/gbrlsnchs/void-pkgs/status.svg)](https://codeberg.org/gbrlsnchs/void-pkgs/commits/branch/trunk)

## About
This repository holds custom templates I have written for my personal use. They're picked by GitLab
CI and transformed into binary packages, which are hosted at https://void.gsr.dev.

## How to use
From [the official handbook](https://docs.voidlinux.org/xbps/repositories/custom.html):
```console
# echo 'repository=https://void.gsr.dev/glibc' > /etc/xbps.d/my-remote-repo.conf
```

After that, all XBPS commands will be able to see the custom packages.

Have fun!
