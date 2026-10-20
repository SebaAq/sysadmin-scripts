#!/usr/bin/env bash
# Chequeo rápido de salud de un host Linux: carga, memoria, discos y servicios caídos.
# Sale con código 1 si encuentra algún problema, así se puede usar en cron o en alertas.
set -euo pipefail

DISK_WARN=85   # % de uso de disco a partir del cual avisa
MEM_WARN=90    # % de uso de memoria a partir del cual avisa

usage() {
  cat <<USO
Uso: $(basename "$0") [-d PORCENTAJE_DISCO] [-m PORCENTAJE_MEMORIA]
  -d  umbral de uso de disco (default $DISK_WARN)
  -m  umbral de uso de memoria (default $MEM_WARN)
USO
}

while getopts "d:m:h" opt; do
  case $opt in
    d) DISK_WARN=$OPTARG ;;
    m) MEM_WARN=$OPTARG ;;
    h) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

problems=0
warn() { echo "  ⚠  $*"; problems=$((problems + 1)); }
ok()   { echo "  ✓  $*"; }

echo "== $(hostname) · $(date '+%F %T')"

echo "-- Carga"
read -r load1 _ < /proc/loadavg
cores=$(nproc)
if awk -v l="$load1" -v c="$cores" 'BEGIN{exit !(l > c)}'; then
  warn "load 1m = $load1 con $cores núcleos"
else
  ok "load 1m = $load1 ($cores núcleos)"
fi

echo "-- Memoria"
mem_used=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%d", (t-a)*100/t}' /proc/meminfo)
if (( mem_used >= MEM_WARN )); then warn "memoria usada ${mem_used}%"; else ok "memoria usada ${mem_used}%"; fi

echo "-- Discos"
while read -r use mount; do
  use=${use%\%}
  if (( use >= DISK_WARN )); then warn "$mount al ${use}%"; else ok "$mount al ${use}%"; fi
done < <(df -P -x tmpfs -x devtmpfs -x overlay -x squashfs | awk 'NR>1{print $5, $6}')

if command -v systemctl >/dev/null && [[ -d /run/systemd/system ]]; then
  echo "-- Servicios"
  mapfile -t failed < <(systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}')
  if (( ${#failed[@]} )); then warn "servicios caídos: ${failed[*]}"; else ok "ningún servicio caído"; fi
fi

echo "== $problems problema(s)"
(( problems == 0 ))
