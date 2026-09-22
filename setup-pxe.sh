#!/bin/bash

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

TFTP_DIR="${HOME}/.config/VirtualBox/TFTP"
URL="https://deb.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/netboot.tar.gz"
PRESEED_SOURCE="${SCRIPT_DIR}/preseed.cfg"

TMP_DIR="$(mktemp -d)"
ARCHIVE="${TMP_DIR}/netboot.tar.gz"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
    echo "ERREUR : $*" >&2
    exit 1
}

echo "Preparation du serveur TFTP VirtualBox..."
echo "Repertoire TFTP : $TFTP_DIR"

[ -f "$PRESEED_SOURCE" ] || fail "Fichier preseed.cfg introuvable dans $SCRIPT_DIR"

mkdir -p "$TFTP_DIR"

echo "Telechargement du netboot Debian..."

if command -v curl >/dev/null 2>&1; then
    curl -fL "$URL" -o "$ARCHIVE"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$URL" -O "$ARCHIVE"
else
    fail "curl ou wget est necessaire."
fi

echo "Extraction du netboot Debian..."

mkdir -p "$TMP_DIR/extract"
tar -xzf "$ARCHIVE" -C "$TMP_DIR/extract"

PXELINUX_SOURCE="$(find "$TMP_DIR/extract" -type f -name "pxelinux.0" | head -n 1)"
LDLINUX_SOURCE="$(find "$TMP_DIR/extract" -type f -name "ldlinux.c32" | head -n 1)"

[ -n "$PXELINUX_SOURCE" ] || fail "pxelinux.0 introuvable."
[ -n "$LDLINUX_SOURCE" ] || fail "ldlinux.c32 introuvable."

echo "Installation des fichiers PXE..."

cp -f "$PXELINUX_SOURCE" "$TFTP_DIR/pxelinux.0"
cp -f "$LDLINUX_SOURCE" "$TFTP_DIR/ldlinux.c32"

echo "Installation des fichiers Debian..."

rm -rf "$TFTP_DIR/debian-installer"
cp -a "$TMP_DIR/extract/debian-installer" "$TFTP_DIR/"

echo "Installation du fichier preseed.cfg..."
cp -f "$PRESEED_SOURCE" "$TFTP_DIR/preseed.cfg"

echo "Creation de la configuration PXELINUX..."

mkdir -p "$TFTP_DIR/pxelinux.cfg"

cat > "$TFTP_DIR/pxelinux.cfg/default" <<'EOF'
DEFAULT install
PROMPT 0
TIMEOUT 1

LABEL install
    MENU LABEL Installation automatique Debian stable
    KERNEL debian-installer/amd64/linux
    APPEND auto=true priority=critical preseed/url=tftp://10.0.2.2/preseed.cfg vga=788 initrd=debian-installer/amd64/initrd.gz --- quiet
EOF

echo
echo "Preparation PXE terminee."
echo
echo "Fichiers principaux :"
echo "  $TFTP_DIR/pxelinux.0"
echo "  $TFTP_DIR/ldlinux.c32"
echo "  $TFTP_DIR/preseed.cfg"
echo "  $TFTP_DIR/pxelinux.cfg/default"
echo "  $TFTP_DIR/debian-installer/amd64/linux"
echo "  $TFTP_DIR/debian-installer/amd64/initrd.gz"
echo
echo "Configuration PXELINUX :"
cat "$TFTP_DIR/pxelinux.cfg/default"
echo
echo "Installation Debian automatisee par preseed : active"
echo "Compte de test : sae51"
echo "Mot de passe de test : debian"
