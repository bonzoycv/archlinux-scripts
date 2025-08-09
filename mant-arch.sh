#!/usr/bin/env bash
set -euo pipefail

KEEP_VERSIONS=2
JOURNAL_RETENTION="30days"

say() { printf "\n==> %s\n" "$*"; }

# 0) Prep sudo si hace falta
if [[ $EUID -ne 0 ]]; then
  sudo -v || true
fi

# 1) Actualiza paquetes oficiales (pacman)
say "Actualizando paquetes de repos oficiales (pacman)…"
sudo pacman -Syu --noconfirm

# 2) Actualiza AUR solo si yay está instalado
if command -v yay >/dev/null 2>&1; then
  say "Actualizando paquetes del AUR (yay -Sua)…"
  # -S: sync, -u: upgrade, -a: AUR only
  yay -Sua --noconfirm || true
else
  say "yay no está instalado; se omiten actualizaciones del AUR."
fi

# 3) Actualiza Flatpak (usuario y sistema) y limpia runtimes no usados
if command -v flatpak >/dev/null 2>&1; then
  say "Actualizando Flatpak (usuario)…"
  flatpak update -y || true
  flatpak uninstall --unused -y || true

  # Intento de ámbito del sistema (requiere sudo)
  if sudo -n true 2>/dev/null; then
    say "Actualizando Flatpak (sistema)…"
    sudo flatpak update --system -y || true
    sudo flatpak uninstall --system --unused -y || true
  else
    say "Sudo no disponible sin contraseña; omitiendo Flatpak del sistema."
  fi
else
  say "Flatpak no está instalado; se omite."
fi

# 4) Limpieza de caché de paquetes, manteniendo 2 versiones
say "Limpiando caché de paquetes (manteniendo ${KEEP_VERSIONS} versiones)…"
if ! command -v paccache >/dev/null 2>&1; then
  say "Instalando pacman-contrib para usar paccache…"
  sudo pacman -S --needed --noconfirm pacman-contrib
fi
sudo paccache -rk "$KEEP_VERSIONS" || true     # mantiene N versiones de paquetes instalados
sudo paccache -ruk0 || true                    # borra paquetes desinstalados

# 5) Journal: conservar 30 días
say "Compactando/vaciando journal (conservando ${JOURNAL_RETENTION})…"
sudo journalctl --vacuum-time="$JOURNAL_RETENTION" || true

# 6) Eliminar huérfanos
say "Eliminando paquetes huérfanos…"
if ORPHANS=$(pacman -Qtdq 2>/dev/null) && [[ -n "${ORPHANS:-}" ]]; then
  sudo pacman -Rns --noconfirm $ORPHANS
else
  echo "No hay huérfanos."
fi

say "Listo."
