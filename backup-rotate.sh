#!/usr/bin/env bash
# Comprime uno o más directorios en DESTINO/NOMBRE-AAAAMMDD-HHMMSS.tar.gz
# y deja solo los últimos N backups de ese nombre.
set -euo pipefail

KEEP=7
NAME=backup
DRY_RUN=0

usage() {
  cat <<USO
Uso: $(basename "$0") -o DESTINO [-n NOMBRE] [-k CANTIDAD] [--dry-run] DIR [DIR...]
  -o  carpeta donde guardar los backups (obligatorio)
  -n  prefijo del archivo (default "$NAME")
  -k  cuántos backups conservar (default $KEEP)
  --dry-run  muestra qué haría sin crear ni borrar nada
Ejemplo: $(basename "$0") -o /srv/backups -n etc -k 14 /etc
USO
}

args=()
for a in "$@"; do [[ $a == --dry-run ]] && DRY_RUN=1 || args+=("$a"); done
set -- "${args[@]+"${args[@]}"}"

DEST=""
while getopts "o:n:k:h" opt; do
  case $opt in
    o) DEST=$OPTARG ;;
    n) NAME=$OPTARG ;;
    k) KEEP=$OPTARG ;;
    h) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

[[ -n $DEST && $# -gt 0 ]] || { usage >&2; exit 2; }
[[ $KEEP =~ ^[0-9]+$ && $KEEP -ge 1 ]] || { echo "-k tiene que ser un número mayor a 0" >&2; exit 2; }
for d in "$@"; do [[ -d $d ]] || { echo "No existe el directorio: $d" >&2; exit 1; }; done

file="$DEST/$NAME-$(date +%Y%m%d-%H%M%S).tar.gz"
if (( DRY_RUN )); then
  echo "[dry-run] crearía $file con: $*"
else
  mkdir -p "$DEST"
  tar -czf "$file" "$@"
  echo "Backup creado: $file ($(du -h "$file" | cut -f1))"
fi

# Rotación: borra los más viejos que superen KEEP
mapfile -t old < <(find "$DEST" -maxdepth 1 -name "$NAME-*.tar.gz" -printf '%T@ %p\n' 2>/dev/null | sort -rn | awk -v k="$KEEP" 'NR>k{print $2}')
for f in "${old[@]+"${old[@]}"}"; do
  if (( DRY_RUN )); then echo "[dry-run] borraría $f"; else rm -f -- "$f"; echo "Rotado: $f"; fi
done
