#!/usr/bin/env bash

# SAE 51 - Installation des fichiers Debian netboot dans le TFTP VirtualBox
# Le script prepare le TFTP integre pour un boot PXE BIOS avec pxelinux.0.

set -u

fail() {
    echo "ERREUR: $*" >&2
    exit 1
}

command -v wget >/dev/null 2>&1 || fail "wget est requis."
command -v tar >/dev/null 2>&1 || fail "tar est requis."
command -v VBoxManage >/dev/null 2>&1 || fail "VBoxManage est introuvable dans le PATH."

TFTP_ROOT="${HOME}/.config/VirtualBox/TFTP"
NETBOOT_URL="https://deb.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/netboot.tar.gz"
TMP_ARCHIVE="${TMPDIR:-/tmp}/debian-netboot.tar.gz"

mkdir -p "$TFTP_ROOT"

echo "Telechargement du netboot Debian stable..."
wget -O "$TMP_ARCHIVE" "$NETBOOT_URL" || fail "Impossible de telecharger l'archive netboot Debian."

echo "Extraction dans : $TFTP_ROOT"
tar -xzf "$TMP_ARCHIVE" -C "$TFTP_ROOT" || fail "Extraction de l'archive impossible."
rm -f "$TMP_ARCHIVE"

[ -f "$TFTP_ROOT/pxelinux.0" ] || fail "pxelinux.0 absent du TFTP."
[ -f "$TFTP_ROOT/debian-installer/amd64/linux" ] || fail "linux absent du netboot Debian."
[ -f "$TFTP_ROOT/debian-installer/amd64/initrd.gz" ] || fail "initrd.gz absent du netboot Debian."

chmod -R u+rwX,go+rX "$TFTP_ROOT"

echo
 echo "Preparation PXE terminee."
echo "TFTP : $TFTP_ROOT"
echo "Boot : pxelinux.0"
echo "Kernel : debian-installer/amd64/linux"
echo "Initrd : debian-installer/amd64/initrd.gz"
