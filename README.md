# sysadmin-scripts

Scripts de Bash que uso para tareas repetitivas de administración de servidores Linux. Son chicos, sin dependencias raras y pasan [ShellCheck](https://www.shellcheck.net/).

> *Small, dependency-free Bash scripts for day-to-day Linux administration: health checks, backups with rotation, log cleanup and TLS certificate expiry.*

| Script | Qué hace | Código de salida |
| --- | --- | --- |
| [`healthcheck.sh`](healthcheck.sh) | Carga, memoria, uso de discos y servicios de systemd caídos | 1 si hay algún problema |
| [`backup-rotate.sh`](backup-rotate.sh) | Comprime directorios en un `.tar.gz` con fecha y conserva los últimos N | ≠0 si falla |
| [`clean-logs.sh`](clean-logs.sh) | Comprime logs viejos y borra comprimidos más viejos aún (simula por defecto) | ≠0 si falla |
| [`cert-expiry.sh`](cert-expiry.sh) | Días que le quedan al certificado TLS de cada host | 1 si alguno vence pronto o no responde |

Todos aceptan `-h` para ver las opciones.

## Ejemplos

```bash
# Salud del host, avisando desde 80 % de disco
./healthcheck.sh -d 80

# Backup diario de /etc conservando dos semanas
./backup-rotate.sh -o /srv/backups -n etc -k 14 /etc

# Ver qué limpiaría en /var/log y después aplicarlo
./clean-logs.sh -c 7 -r 30
sudo ./clean-logs.sh -c 7 -r 30 --apply

# Certificados que vencen en menos de 30 días
./cert-expiry.sh -w 30 ejemplo.com mail.ejemplo.com:465
./cert-expiry.sh -f hosts.txt
```

## Con cron

Como salen con código distinto de 0 cuando algo anda mal, se pueden encadenar con un aviso:

```cron
# Todos los días a las 3:15, backup de /etc
15 3 * * *  /opt/sysadmin-scripts/backup-rotate.sh -o /srv/backups -n etc -k 14 /etc
# Cada lunes, revisar certificados y mandar mail si alguno vence
0 9 * * 1   /opt/sysadmin-scripts/cert-expiry.sh -f /opt/hosts.txt || mail -s "Certificados por vencer" yo@ejemplo.com < /dev/null
```

## Desarrollo

```bash
shellcheck -S style *.sh
```

## Licencia

MIT
