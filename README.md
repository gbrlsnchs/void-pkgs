# My custom Void packages
[![Woodpecker CI](https://ci.codeberg.org/api/badges/gbrlsnchs/void-pkgs/status.svg)](https://codeberg.org/gbrlsnchs/void-pkgs/commits/branch/trunk)

## About
This repository holds custom templates I have written for my personal use. It used to be fully
automated but in order to not exploit free computing from Codeberg's CI I decided to embrace a full
local compilation process through some helper shell scripts.

## Dependencies
- `git`
- `podman`
- `xtools`

## How to use the binary repository
From [the official handbook](https://docs.voidlinux.org/xbps/repositories/custom.html):
```console
# echo 'repository=https://void.gsr.dev/glibc' > /etc/xbps.d/my-remote-repo.conf
```

After that, all XBPS commands will be able to see the custom packages.

Have fun!
