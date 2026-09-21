#!/usr/bin/env bash
set -u

fail() { echo "ERREUR: $*" >&2; exit 1; }
run() { "$@" || fail "Commande echouee: $*"; }

if command -v VBoxManage >/dev/null 2>&1; then
    VBOXMANAGE="$(command -v VBoxManage)"
elif command -v VBoxManage.exe >/dev/null 2>&1; then
    VBOXMANAGE="$(command -v VBoxManage.exe)"
elif command -v vboxmanage >/dev/null 2>&1; then
    VBOXMANAGE="$(command -v vboxmanage)"
else
    fail "VBoxManage est introuvable dans le PATH. Installez VirtualBox puis rendez VBoxManage accessible depuis Bash."
fi
vm_cmd() { "$VBOXMANAGE" "$@"; }

get_default_machine_folder() {
    vm_cmd list systemproperties 2>/dev/null \
        | tr -d '\r' \
        | sed -n 's/^Default machine folder:[[:space:]]*//p' \
        | head -n 1
}

vm_exists() { vm_cmd showvminfo "$1" >/dev/null 2>&1; }

RAM_MB=4096
DISK_GIB=64
META_PREFIX="SAE51/metadata"

validate_name() {
    local name="$1"
    [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || fail "Nom VM invalide. Utilisez seulement lettres, chiffres, ., _ et -."
}

get_extra() {
    vm_cmd getextradata "$1" "$2" 2>/dev/null \
        | tr -d '\r' \
        | sed -n 's/^Value: //p' \
        | head -n 1
}

create_vm() {
    local name="$1" base_folder disk_path created_at creator
    validate_name "$name"
    vm_exists "$name" && fail "La VM '$name' existe deja."
    base_folder="$(get_default_machine_folder)"
    [ -n "$base_folder" ] || fail "Impossible de recuperer le dossier par defaut des VM VirtualBox."
    disk_path="${base_folder}/${name}/${name}.vdi"

    run vm_cmd createvm --name "$name" --ostype "Debian_64" --register
    run vm_cmd modifyvm "$name" --memory "$RAM_MB" --nic1 nat
    run vm_cmd createhd --filename "$disk_path" --size $((DISK_GIB * 1024))
    run vm_cmd storagectl "$name" --name "SATA Controller" --add sata --controller IntelAHCI
    run vm_cmd storageattach "$name" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$disk_path"

    created_at="$(date '+%Y-%m-%d %H:%M:%S %z')"
    creator="${USER:-$(id -un)}"
    run vm_cmd setextradata "$name" "${META_PREFIX}/creation_date" "$created_at"
    run vm_cmd setextradata "$name" "${META_PREFIX}/creator" "$creator"
    echo "VM '$name' creee. Createur: $creator ; date: $created_at"
}

list_vms() {
    local line name creator created found=0
    while IFS= read -r line; do
        line="$(printf '%s' "$line" | tr -d '\r')"
        name="${line#\"}"
        name="${name%%\" *}"
        [ -n "$name" ] || continue
        found=1
        creator="$(get_extra "$name" "${META_PREFIX}/creator")"
        created="$(get_extra "$name" "${META_PREFIX}/creation_date")"
        printf '%-25s | createur=%-15s | date=%s\n' "$name" "${creator:--}" "${created:--}"
    done < <(vm_cmd list vms | tr -d '\r')
    [ "$found" -eq 1 ] || echo "Aucune VM enregistree."
}

usage() {
    cat >&2 <<USAGE
Usage:
  $0 L
  $0 N nom_vm
  $0 S nom_vm
  $0 D nom_vm
  $0 A nom_vm
USAGE
}

ACTION="${1:-}"
NAME="${2:-}"
EXTRA="${3:-}"

case "$ACTION" in
    L)
        [ -z "$NAME" ] && [ -z "$EXTRA" ] || { usage; exit 2; }
        list_vms
        ;;
    N)
        [ -n "$NAME" ] && [ -z "$EXTRA" ] || { usage; exit 2; }
        create_vm "$NAME"
        ;;
    S|D|A)
        [ -n "$NAME" ] && [ -z "$EXTRA" ] || { usage; exit 2; }
        vm_exists "$NAME" || fail "La VM '$NAME' n'existe pas."
        case "$ACTION" in
            S) run vm_cmd unregistervm "$NAME" --delete; echo "VM '$NAME' supprimee." ;;
            D) run vm_cmd startvm "$NAME" --type headless; echo "VM '$NAME' demarree." ;;
            A)
                STATE="$(vm_cmd showvminfo "$NAME" --machinereadable 2>/dev/null | tr -d '\r' | sed -n 's/^VMState="\([^"]*\)"/\1/p' | head -n 1)"
                if [ "$STATE" = "poweroff" ]; then
                    echo "VM '$NAME' deja arretee."
                else
                    run vm_cmd controlvm "$NAME" acpipowerbutton
                    echo "Demande d'arret envoyee a '$NAME'."
                fi
                ;;
        esac
        ;;
    *)
        usage
        exit 2
        ;;
esac
