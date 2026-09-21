#!/bin/bash

set -e

TFTP_DIR="${HOME}/.config/VirtualBox/TFTP"
URL="https://deb.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/netboot.tar.gz"

TMP_DIR="$(mktemp -d)"
ARCHIVE="${TMP_DIR}/netboot.tar.gz"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "Preparation du serveur TFTP VirtualBox..."
echo "Repertoire TFTP : $TFTP_DIR"

mkdir -p "$TFTP_DIR"

echo "Telechargement du netboot Debian..."

if command -v curl >/dev/null 2>&1; then
    curl -fL "$URL" -o "$ARCHIVE"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$URL" -O "$ARCHIVE"
else
    echo "ERREUR : curl ou wget est necessaire."
    exit 1
fi

echo "Extraction du netboot Debian..."

mkdir -p "$TMP_DIR/extract"
tar -xzf "$ARCHIVE" -C "$TMP_DIR/extract"

PXELINUX_SOURCE="$(find "$TMP_DIR/extract" -type f -name "pxelinux.0" | head -n 1)"
LDLINUX_SOURCE="$(find "$TMP_DIR/extract" -type f -name "ldlinux.c32" | head -n 1)"

if [ -z "$PXELINUX_SOURCE" ]; then
    echo "ERREUR : pxelinux.0 introuvable."
    exit 1
fi

if [ -z "$LDLINUX_SOURCE" ]; then
    echo "ERREUR : ldlinux.c32 introuvable."
    exit 1
fi

echo "Installation des fichiers PXE..."

cp -f "$PXELINUX_SOURCE" "$TFTP_DIR/pxelinux.0"
cp -f "$LDLINUX_SOURCE" "$TFTP_DIR/ldlinux.c32"

echo "Installation des fichiers Debian..."

rm -rf "$TFTP_DIR/debian-installer"

cp -a "$TMP_DIR/extract/debian-installer" "$TFTP_DIR/"

echo "Creation de la configuration PXELINUX..."

mkdir -p "$TFTP_DIR/pxelinux.cfg"

rm -f "$TFTP_DIR/pxelinux.cfg/default"

cat > "$TFTP_DIR/pxelinux.cfg/default" <<'EOF'
DEFAULT install
PROMPT 0
TIMEOUT 1

LABEL install
    MENU LABEL Installation Debian stable
    KERNEL debian-installer/amd64/linux
    APPEND vga=788 initrd=debian-installer/amd64/initrd.gz --- quiet
EOF

echo
echo "Preparation PXE terminee."
echo
echo "Fichiers principaux :"
echo "  $TFTP_DIR/pxelinux.0"
echo "  $TFTP_DIR/ldlinux.c32"
echo "  $TFTP_DIR/pxelinux.cfg/default"
echo "  $TFTP_DIR/debian-installer/amd64/linux"
echo "  $TFTP_DIR/debian-installer/amd64/initrd.gz"
echo
echo "Configuration PXELINUX :"
cat "$TFTP_DIR/pxelinux.cfg/default"
