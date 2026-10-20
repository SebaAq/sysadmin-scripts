#!/usr/bin/env bash
# Comprime los logs de más de N días y borra los comprimidos de más de M días.
# Por defecto solo muestra qué haría: hace falta --apply para tocar archivos.
set -euo pipefail

DIR=/var/log
COMPRESS_AFTER=7
DELETE_AFTER=30
APPLY=0

usage() {
  cat <<USO
Uso: $(basename "$0") [-d DIRECTORIO] [-c DIAS] [-r DIAS] [--apply]
  -d  directorio de logs (default $DIR)
  -c  comprimir .log con más de estos días (default $COMPRESS_AFTER)
  -r  borrar .gz con más de estos días (default $DELETE_AFTER)
  --apply  ejecuta los cambios (sin esto, solo los lista)
USO
}

args=()
for a in "$@"; do [[ $a == --apply ]] && APPLY=1 || args+=("$a"); done
set -- "${args[@]+"${args[@]}"}"

while getopts "d:c:r:h" opt; do
  case $opt in
    d) DIR=$OPTARG ;;
    c) COMPRESS_AFTER=$OPTARG ;;
    r) DELETE_AFTER=$OPTARG ;;
    h) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done
[[ -d $DIR ]] || { echo "No existe el directorio: $DIR" >&2; exit 1; }

mode="[simulación]"; (( APPLY )) && mode="[aplicando]"
echo "$mode $DIR · comprimir > ${COMPRESS_AFTER} días · borrar .gz > ${DELETE_AFTER} días"

compressed=0; deleted=0
while IFS= read -r -d '' f; do
  echo "  comprimir $f"
  (( APPLY )) && gzip -9 -- "$f"
  compressed=$((compressed + 1))
done < <(find "$DIR" -type f -name '*.log' -mtime +"$COMPRESS_AFTER" -print0)

while IFS= read -r -d '' f; do
  echo "  borrar    $f"
  (( APPLY )) && rm -f -- "$f"
  deleted=$((deleted + 1))
done < <(find "$DIR" -type f -name '*.gz' -mtime +"$DELETE_AFTER" -print0)

echo "$mode $compressed para comprimir, $deleted para borrar"
(( APPLY )) || echo "Corré de nuevo con --apply para hacer los cambios."
