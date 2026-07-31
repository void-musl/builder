curl -LO https://raw.githubusercontent.com/voiz-linux/builder/main/scripts/build.sh

podman run --rm \
  --privileged \
  -v "$PWD":/workspace \
  -e ARCH=x86_64-musl \
  -e BOOTSTRAP=x86_64-musl \
  -e TEST=0 \
  -e XBPS_ALLOW_CHROOT_BREAKOUT=yes \
  -e PRIV_KEY="$PRIV_KEY" \
  ghcr.io/void-linux/voiz-linux-full \
  /bin/bash build.sh
