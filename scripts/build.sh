#!/bin/bash
set -e

echo "Starting Build..."

echo "Configuring mirrors..."
mkdir -p /etc/xbps.d
cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/
sed -i 's|https://repo-default.voidlinux.org|https://repo-fastly.voidlinux.org|g' /etc/xbps.d/*-repository-*.conf
xbps-install -S

echo "Installing dependencies..."
xbps-install -Syu xbps
xbps-install -yu
xbps-install -y nodejs-lts git curl base-devel bash jq

ls -lr
pwd

remove=(
    void-packages
    musl-packages
)

for FILE in "${remove[@]}"; do
    [ -e "$FILE" ] && echo "    Removing: $FILE"
    rm -rf "$FILE"
done

echo "Cloning void-packages..."
git clone --depth=1 https://github.com/void-linux/void-packages.git void-packages

echo "Configuring ethereal mode..."
cd void-packages
mkdir -p etc
echo -e "XBPS_CHROOT_CMD=ethereal\nXBPS_MIRROR=https://repo-fastly.voidlinux.org/current" >> etc/conf
ln -s / masterdir

git clone --depth=1 https://github.com/voiz-linux/void-packages.git ../musl-packages
echo "Merging templates..."
cp -rv ../musl-packages/srcpkgs/ayugram-desktop srcpkgs/

echo "Building package..."
/bin/bash ./xbps-src -j$(nproc) pkg ayugram-desktop

echo "Signing and indexing..."
cd hostdir/binpkgs

if [ -n "$PRIV_KEY" ]; then
    echo "$PRIV_KEY" > private.pem
    xbps-rindex -a *.xbps
    xbps-rindex -s --signedby "anrix <iz@anrix.org>" --privkey private.pem $PWD
    xbps-rindex -S --privkey private.pem *.xbps
    rm private.pem
else
    echo "Warning: PRIV_KEY not provided. Packages will not be signed."
    xbps-rindex -a *.xbps
fi

echo "Exporting artifacts..."
mkdir -p /workspace/output
mv *.xbps *.sig2 *-repodata /workspace/output/ || true

echo "Build complete! Artifacts are in the /workspace/output directory."
