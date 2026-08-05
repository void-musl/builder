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


echo "Preparing chroot environment..."
# Attempt to mount essential virtual filesystems (fixes nproc and device nodes)
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sys /sys 2>/dev/null || true
mount -t devtmpfs dev /dev 2>/dev/null || true

echo "Ensuring essential device nodes exist..."
# If mounting devtmpfs failed/was restricted, manually create the missing nodes
[ -e /dev/null ]    || mknod -m 666 /dev/null c 1 3 2>/dev/null || true
[ -e /dev/zero ]    || mknod -m 666 /dev/zero c 1 5 2>/dev/null || true
[ -e /dev/random ]  || mknod -m 666 /dev/random c 1 8 2>/dev/null || true
[ -e /dev/urandom ] || mknod -m 666 /dev/urandom c 1 9 2>/dev/null || true

# Force permissions and ignore errors to prevent set -e from killing the script
chmod 666 /dev/null /dev/zero /dev/random /dev/urandom 2>/dev/null || true

echo "Creating unprivileged build user with sudo access..."
# Create the user and add them to the 'wheel' group
useradd -m -G wheel builder 2>/dev/null || true
chown -R builder:builder .

# Configure passwordless sudo for the wheel group
mkdir -p /etc/sudoers.d
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel-nopasswd
chmod 0440 /etc/sudoers.d/wheel-nopasswd

echo "Building package..."
# Now that /proc is likely mounted, nproc should work reliably
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
