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
    vm_cmd list systemproperties --machinereadable \
        | tr -d '\r' \
        | sed -n 's/^defaultMachineFolder="\(.*\)"$/\1/p' \
        | head -n 1
}

vm_exists() { vm_cmd showvminfo "$1" >/dev/null 2>&1; }

VM="Debian1"
RAM_MB=4096
DISK_GIB=64
BASE_FOLDER="$(get_default_machine_folder)"
[ -n "$BASE_FOLDER" ] || fail "Impossible de recuperer le dossier par defaut des VM VirtualBox."
DISK_PATH="${BASE_FOLDER}/${VM}/${VM}.vdi"

# V2 : rendre la creation repetable.
if vm_exists "$VM"; then
    echo "La VM '$VM' existe deja : suppression avant recreation."
    run vm_cmd unregistervm "$VM" --delete
fi

run vm_cmd createvm --name "$VM" --ostype "Debian_64" --register
run vm_cmd modifyvm "$VM" --memory "$RAM_MB" --nic1 nat
run vm_cmd createhd --filename "$DISK_PATH" --size $((DISK_GIB * 1024))
run vm_cmd storagectl "$VM" --name "SATA Controller" --add sata --controller IntelAHCI
run vm_cmd storageattach "$VM" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$DISK_PATH"

echo "VM '$VM' creee correctement."
