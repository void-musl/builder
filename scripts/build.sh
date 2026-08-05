#!/bin/bash
set -e

echo "Starting Build..."

echo "Configuring mirrors..."
mkdir -p /etc/xbps.d

for conf in /usr/share/xbps.d/*-repository-*.conf; do
    if [ -f "$conf" ]; then
        cp "$conf" /etc/xbps.d/
    fi
done

if ls /etc/xbps.d/*-repository-*.conf 1> /dev/null 2>&1; then
    sed -i 's|https://repo-default.voidlinux.org|https://repo-fastly.voidlinux.org|g' /etc/xbps.d/*-repository-*.conf
fi

xbps-install -S

echo "Installing dependencies..."
xbps-install -Syu xbps
xbps-install -yu
xbps-install -y git curl base-devel bash jq

ls -lr

DIR=$(pwd)

remove=(
    "void-packages"
    "musl-packages"
)

for FILE in "${remove[@]}"; do
    if [ -e "$FILE" ]; then
        echo "    Removing: $FILE"
        rm -rf "$FILE"
    fi
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


echo "Fixing device node permissions for chroot..."
chmod 666 /dev/null /dev/zero /dev/random /dev/urandom

echo "Creating unprivileged build user with sudo access..."
# Create the user and add them to the 'wheel' group
useradd -m -G wheel builder 2>/dev/null || true
chown -R builder:builder .

# Configure passwordless sudo for the wheel group
mkdir -p /etc/sudoers.d
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel-nopasswd
chmod 0440 /etc/sudoers.d/wheel-nopasswd

echo "Building package..."
CORES=$(nproc 2>/dev/null || echo 4)

# Run the xbps-src command as the builder user
su builder -c "/bin/bash ./xbps-src -j$CORES pkg ayugram-desktop"

echo "Signing and indexing..."
cd hostdir/binpkgs

if [ -n "$PRIV_KEY" ]; then
    printf "%s\n" "$PRIV_KEY" > private.pem
    chmod 600 private.pem
    
    xbps-rindex -a *.xbps
    xbps-rindex -s --signedby "anrix <iz@anrix.org>" --privkey private.pem "$PWD"
    xbps-rindex -S --privkey private.pem *.xbps
    
    rm private.pem
else
    echo "Warning: PRIV_KEY not provided. Packages will not be signed."
    xbps-rindex -a *.xbps
fi

echo "Build complete!"
