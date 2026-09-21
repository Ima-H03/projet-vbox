#!/usr/bin/env bash

# SAE 51 - Automatisation de la creation de machines VirtualBox
# Version 5 - Bash portable
#
# Le script doit etre execute dans un environnement Bash disposant de
# VBoxManage dans le PATH. Aucune dependance a WSL ou a un chemin Windows.

set -u

# -----------------------------------------------------------------------------
# Configuration modifiable
# -----------------------------------------------------------------------------
RAM_MB=4096
DISK_GIB=64
DISK_FORMAT="VDI"
DISK_VARIANT="Standard"

META_PREFIX="SAE51/metadata"

PXE_TFTP_SERVER="10.0.2.2"
PXE_TFTP_FILE="pxelinux.0"
PXE_TFTP_PREFIX="${HOME}/.config/VirtualBox/TFTP"

# -----------------------------------------------------------------------------
# Messages / erreurs
# -----------------------------------------------------------------------------
fail() {
    echo "ERREUR: $*" >&2
    exit 1
}

run() {
    "$@" || fail "Commande echouee: $*"
}

usage() {
    cat >&2 <<USAGE
Usage :
  $0 L
  $0 N nom_vm
  $0 S nom_vm
  $0 D nom_vm
  $0 A nom_vm

Actions :
  L              Liste les VM enregistrees et leurs metadonnees
  N nom_vm       Cree une VM (et la recrée proprement si elle existe deja)
  S nom_vm       Supprime une VM
  D nom_vm       Demarre une VM en mode headless
  A nom_vm       Arrete une VM proprement puis force l'arret si necessaire
USAGE
}

# -----------------------------------------------------------------------------
# Recherche de VBoxManage dans le PATH
# -----------------------------------------------------------------------------
find_vboxmanage() {
    local candidate

    for candidate in VBoxManage VBoxManage.exe vboxmanage; do
        if command -v "$candidate" >/dev/null 2>&1; then
            command -v "$candidate"
            return 0
        fi
    done

    return 1
}

VBOXMANAGE="$(find_vboxmanage || true)"
[ -n "$VBOXMANAGE" ] || fail "VBoxManage est introuvable dans le PATH. Installez VirtualBox et rendez VBoxManage accessible depuis Bash."

vm_cmd() {
    "$VBOXMANAGE" "$@"
}

# -----------------------------------------------------------------------------
# Fonctions VirtualBox
# -----------------------------------------------------------------------------
vm_exists() {
    vm_cmd showvminfo "$1" >/dev/null 2>&1
}

get_state() {
    vm_cmd showvminfo "$1" --machinereadable 2>/dev/null \
        | tr -d '\r' \
        | sed -n 's/^VMState="\([^"]*\)"/\1/p' \
        | head -n 1
}

get_extra() {
    vm_cmd getextradata "$1" "$2" 2>/dev/null \
        | tr -d '\r' \
        | sed -n 's/^Value: //p' \
        | head -n 1
}

get_default_machine_folder() {
    # VBoxManage list systemproperties ne propose pas --machinereadable.
    # On parse donc la ligne humaine. On accepte les libelles anglais/francais.
    vm_cmd list systemproperties 2>/dev/null \
        | tr -d '\r' \
        | awk '
            {
                line = tolower($0)
                if (index(line, "machine") && (index(line, "folder") || index(line, "dossier")) && index($0, ":")) {
                    sub(/^[^:]*:[[:space:]]*/, "", $0)
                    print $0
                    exit
                }
            }
        '
}

wait_poweroff() {
    local name="$1"
    local timeout="${2:-30}"
    local state

    while [ "$timeout" -gt 0 ]; do
        state="$(get_state "$name")"

        case "$state" in
            poweroff|aborted)
                return 0
                ;;
        esac

        sleep 1
        timeout=$((timeout - 1))
    done

    return 1
}

stop_vm() {
    local name="$1"
    local state

    state="$(get_state "$name")"

    case "$state" in
        poweroff|aborted|"")
            return 0
            ;;

        running)
            echo "Demande d'arret de '$name'..."

            if vm_cmd controlvm "$name" acpipowerbutton >/dev/null 2>&1; then
                if wait_poweroff "$name" 15; then
                    echo "VM '$name' arretee proprement."
                    return 0
                fi
            fi

            echo "Arret propre impossible ou trop long : arret force de '$name'." >&2
            run vm_cmd controlvm "$name" poweroff

            wait_poweroff "$name" 10 || \
                fail "La VM '$name' ne s'est pas arretee."
            ;;

        saved)
            fail "La VM '$name' est dans l'etat 'saved'. Arretez-la ou gerez son etat sauvegarde avant cette operation."
            ;;

        *)
            fail "Etat inattendu pour '$name' : ${state:-inconnu}."
            ;;
    esac
}

validate_name() {
    local name="$1"

    [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || \
        fail "Nom VM invalide. Utilisez uniquement lettres, chiffres, '.', '_' et '-'."
}

# -----------------------------------------------------------------------------
# Creation d'une VM
# -----------------------------------------------------------------------------
create_vm() {
    local name="$1"
    local base_folder
    local vm_folder
    local disk_path
    local created_at
    local creator

    validate_name "$name"

    # Le sujet demande une execution repetitive sans erreur :
    # si la VM existe deja, on la supprime puis on la recree.
    if vm_exists "$name"; then
        echo "La VM '$name' existe deja. Suppression avant recreation..."
        stop_vm "$name"
        run vm_cmd unregistervm "$name" --delete
    fi

    base_folder="$(get_default_machine_folder)"
    base_folder="$(printf '%s' "$base_folder" | sed 's/[[:space:]]*$//')"
    [ -n "$base_folder" ] || \
        fail "Impossible de recuperer le dossier par defaut des VM VirtualBox."

    vm_folder="${base_folder}/${name}"
    disk_path="${vm_folder}/${name}.vdi"

    echo "Creation de la VM '$name'..."

    run vm_cmd createvm \
        --name "$name" \
        --ostype "Debian_64" \
        --register

    run vm_cmd modifyvm "$name" \
        --memory "$RAM_MB" \
        --nic1 nat \
        --boot1 net \
        --boot2 disk \
        --boot3 dvd \
        --boot4 none \
        --nat-tftp-server1 "$PXE_TFTP_SERVER" \
        --nat-tftp-file1 "$PXE_TFTP_FILE" \
        --nat-tftp-prefix1 "$PXE_TFTP_PREFIX" \
        --nat-enable-tftp1 on

    run vm_cmd createmedium disk \
        --filename "$disk_path" \
        --size $((DISK_GIB * 1024)) \
        --format "$DISK_FORMAT" \
        --variant "$DISK_VARIANT"

    run vm_cmd storagectl "$name" \
        --name "SATA Controller" \
        --add sata \
        --controller IntelAHCI

    run vm_cmd storageattach "$name" \
        --storagectl "SATA Controller" \
        --port 0 \
        --device 0 \
        --type hdd \
        --medium "$disk_path"

    created_at="$(date '+%Y-%m-%d %H:%M:%S %z')"
    creator="${USER:-$(id -un)}"

    run vm_cmd setextradata "$name" "${META_PREFIX}/creation_date" "$created_at"
    run vm_cmd setextradata "$name" "${META_PREFIX}/creator" "$creator"

    mkdir -p "$PXE_TFTP_PREFIX"

    echo "VM '$name' creee avec succes."
    echo "  RAM                 : ${RAM_MB} MiB"
    echo "  Disque              : ${DISK_GIB} GiB (${DISK_FORMAT}, ${DISK_VARIANT})"
    echo "  Reseau              : NAT"
    echo "  Boot                : reseau, disque, DVD"
    echo "  Serveur TFTP NAT    : $PXE_TFTP_SERVER"
    echo "  Fichier PXE         : $PXE_TFTP_FILE"
    echo "  Prefixe TFTP        : $PXE_TFTP_PREFIX"
    echo "  Createur            : $creator"
    echo "  Date                : $created_at"
    echo "  Attention           : le fichier PXE doit etre place dans le repertoire TFTP pour qu'un boot PXE aboutisse."
}

# -----------------------------------------------------------------------------
# Liste des VM et metadonnees
# -----------------------------------------------------------------------------
list_vms() {
    local line
    local name
    local creator
    local created
    local found=0

    while IFS= read -r line; do
        line="$(printf '%s' "$line" | tr -d '\r')"
        [ -n "$line" ] || continue

        name="${line#\"}"
        name="${name%%\" *}"
        [ -n "$name" ] || continue

        found=1
        creator="$(get_extra "$name" "${META_PREFIX}/creator")"
        created="$(get_extra "$name" "${META_PREFIX}/creation_date")"

        printf '%-25s | createur=%-15s | date=%s\n' \
            "$name" "${creator:--}" "${created:--}"
    done < <(vm_cmd list vms | tr -d '\r')

    [ "$found" -eq 1 ] || echo "Aucune VM enregistree."
}

# -----------------------------------------------------------------------------
# Validation des arguments
# -----------------------------------------------------------------------------
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

    S)
        [ -n "$NAME" ] && [ -z "$EXTRA" ] || { usage; exit 2; }
        vm_exists "$NAME" || fail "La VM '$NAME' n'existe pas."
        stop_vm "$NAME"
        run vm_cmd unregistervm "$NAME" --delete
        echo "VM '$NAME' supprimee."
        ;;

    D)
        [ -n "$NAME" ] && [ -z "$EXTRA" ] || { usage; exit 2; }
        vm_exists "$NAME" || fail "La VM '$NAME' n'existe pas."

        state="$(get_state "$NAME")"
        case "$state" in
            running)
                echo "VM '$NAME' deja demarree."
                ;;
            poweroff|aborted|"")
                run vm_cmd startvm "$NAME" --type headless
                echo "VM '$NAME' demarree."
                ;;
            saved)
                run vm_cmd startvm "$NAME" --type headless
                echo "VM '$NAME' reprise depuis l'etat sauvegarde."
                ;;
            *)
                fail "Impossible de demarrer '$NAME' depuis l'etat '${state:-inconnu}'."
                ;;
        esac
        ;;

    A)
        [ -n "$NAME" ] && [ -z "$EXTRA" ] || { usage; exit 2; }
        vm_exists "$NAME" || fail "La VM '$NAME' n'existe pas."
        stop_vm "$NAME"
        ;;

    *)
        usage
        exit 2
        ;;
esac
