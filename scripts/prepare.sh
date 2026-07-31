curl -LO https://raw.githubusercontent.com/voiz-linux/builder/main/scripts/build.sh

udocker run \
  -v "$PWD":/workspace \
  -e ARCH=x86_64-musl \
  -e BOOTSTRAP=x86_64-musl \
  -e TEST=0 \
  -e XBPS_ALLOW_CHROOT_BREAKOUT=yes \
  -e PRIV_KEY="$PRIV_KEY" \
  ghcr.io/void-linux/void-musl-full \
  /bin/bash build.sh
