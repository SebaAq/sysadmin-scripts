#!/usr/bin/env bash
# Muestra cuántos días le quedan al certificado TLS de cada host y avisa los que vencen pronto.
# Sale con código 1 si alguno vence antes del umbral o no responde.
set -euo pipefail

WARN_DAYS=21

usage() {
  cat <<USO
Uso: $(basename "$0") [-w DIAS] HOST[:PUERTO] [HOST[:PUERTO]...]
     $(basename "$0") [-w DIAS] -f ARCHIVO     (un host por línea)
  -w  avisar si quedan menos de estos días (default $WARN_DAYS)
Ejemplo: $(basename "$0") -w 30 ejemplo.com mail.ejemplo.com:465
USO
}

hosts=()
while getopts "w:f:h" opt; do
  case $opt in
    w) WARN_DAYS=$OPTARG ;;
    f) mapfile -t -O "${#hosts[@]}" hosts < <(grep -v '^\s*\(#\|$\)' "$OPTARG") ;;
    h) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
hosts+=("$@")
(( ${#hosts[@]} )) || { usage >&2; exit 2; }

bad=0
printf '%-40s %8s  %s\n' HOST DÍAS VENCE
for target in "${hosts[@]}"; do
  host=${target%%:*}; port=${target##*:}; [[ $port == "$target" ]] && port=443
  end=$(echo | timeout 10 openssl s_client -servername "$host" -connect "$host:$port" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2) || true
  if [[ -z $end ]]; then
    printf '%-40s %8s  %s\n' "$host:$port" "-" "sin respuesta o sin TLS"; bad=1; continue
  fi
  days=$(( ($(date -d "$end" +%s) - $(date +%s)) / 86400 ))
  flag=""; (( days < WARN_DAYS )) && { flag="  ⚠"; bad=1; }
  printf '%-40s %8s  %s%s\n' "$host:$port" "$days" "$(date -d "$end" +%F)" "$flag"
done
exit $bad
