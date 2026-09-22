#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
export FAKE_VBOX_STATE="$TMP_DIR/state"
export FAKE_VBOX_HOME="$TMP_DIR/vbox"
export PATH="$ROOT_DIR/tests/fake_bin:$PATH"
export USER="sae51-ci"

mkdir -p "$FAKE_VBOX_STATE" "$FAKE_VBOX_HOME"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

pass=0

ok() {
    printf '[OK] %s\n' "$1"
    pass=$((pass + 1))
}

need() {
    grep -Fq -- "$2" <<<"$1" || {
        echo "[ECHEC] $3" >&2
        echo "Attendu : $2" >&2
        exit 1
    }
    ok "$3"
}

need_absent() {
    [ ! -e "$1" ] || {
        echo "[ECHEC] $2" >&2
        exit 1
    }
    ok "$2"
}

echo "=== SAE51 : tests unitaires ==="

echo
echo "--- V1 ---"
printf '\n' | bash "$ROOT_DIR/genmv_1.sh"
log_v1="$(cat "$FAKE_VBOX_STATE/commands.log")"
need "$log_v1" 'createvm --name Debian1' 'V1 crée Debian1'
need "$log_v1" 'unregistervm Debian1 --delete' 'V1 supprime Debian1'

echo
echo "--- V2 ---"
rm -f "$FAKE_VBOX_STATE/commands.log"
bash "$ROOT_DIR/genmv_2.sh"
bash "$ROOT_DIR/genmv_2.sh"
log_v2="$(cat "$FAKE_VBOX_STATE/commands.log")"
need "$log_v2" 'unregistervm Debian1 --delete' 'V2 gère une VM déjà existante'
need "$([ -f "$FAKE_VBOX_STATE/Debian1.state" ] && echo present)" "present" 'V2 recrée Debian1 correctement'
rm -f "$FAKE_VBOX_STATE/Debian1.state"

echo
echo "--- V3 ---"
bash "$ROOT_DIR/genmv_3.sh" N test-v3 >/dev/null
list_v3="$(bash "$ROOT_DIR/genmv_3.sh" L)"
need "$list_v3" '"test-v3"' 'V3 liste la VM'
bash "$ROOT_DIR/genmv_3.sh" D test-v3 >/dev/null
need "$(cat "$FAKE_VBOX_STATE/test-v3.state")" "running" 'V3 démarre la VM'
bash "$ROOT_DIR/genmv_3.sh" A test-v3 >/dev/null
need "$(cat "$FAKE_VBOX_STATE/test-v3.state")" "poweroff" 'V3 arrête la VM'
bash "$ROOT_DIR/genmv_3.sh" S test-v3 >/dev/null
need_absent "$FAKE_VBOX_STATE/test-v3.state" 'V3 supprime la VM'

echo
echo "--- V4 ---"
bash "$ROOT_DIR/genmv_4.sh" N test-v4 >/dev/null
list_v4="$(bash "$ROOT_DIR/genmv_4.sh" L)"
need "$list_v4" "test-v4" 'V4 liste la VM'
need "$list_v4" "createur=" 'V4 affiche le créateur'
need "$list_v4" "date=" 'V4 affiche la date'
bash "$ROOT_DIR/genmv_4.sh" D test-v4 >/dev/null
bash "$ROOT_DIR/genmv_4.sh" A test-v4 >/dev/null
need "$(cat "$FAKE_VBOX_STATE/test-v4.state")" "poweroff" 'V4 arrête la VM'
bash "$ROOT_DIR/genmv_4.sh" S test-v4 >/dev/null
need_absent "$FAKE_VBOX_STATE/test-v4.state" 'V4 supprime la VM'

echo
echo "--- V5 ---"
bash "$ROOT_DIR/genmv_5.sh" N test-v5 >/dev/null
log_v5="$(cat "$FAKE_VBOX_STATE/commands.log")"
need "$log_v5" 'modifyvm test-v5 --memory 4096 --nic1 nat --boot1 net --boot2 disk --boot3 dvd --boot4 none' 'V5 configure RAM/NAT/boot'
need "$log_v5" '--nat-tftp-server1 10.0.2.2' 'V5 configure le serveur TFTP'
need "$log_v5" '--nat-tftp-file1 pxelinux.0' 'V5 configure le fichier PXE'
need "$log_v5" '--nat-enable-tftp1 on' 'V5 active TFTP'
bash "$ROOT_DIR/genmv_5.sh" D test-v5 >/dev/null
bash "$ROOT_DIR/genmv_5.sh" A test-v5 >/dev/null
need "$(cat "$FAKE_VBOX_STATE/test-v5.state")" "poweroff" 'V5 arrête la VM'
bash "$ROOT_DIR/genmv_5.sh" S test-v5 >/dev/null
need_absent "$FAKE_VBOX_STATE/test-v5.state" 'V5 supprime la VM'

echo
printf 'Résultat : %d vérifications passées.\n' "$pass"
