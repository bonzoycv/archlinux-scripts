#!/bin/bash

# === CONFIGURACIÓN ===
LOG_DIR="$HOME/registro_de_actualizaciones"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/actualizaciones_$(date +%F_%H-%M-%S).log"
UPDATE_RECORD="/tmp/actualizacion_diaria_realizada"

# === FUNCIONES ===
log() { echo "$(date +'%F %T') - $1" | tee -a "$LOG_FILE"; }
has() { command -v "$1" &>/dev/null; }

# === VALIDACIÓN DE PERMISOS ===
sudo -v || { echo "Se requieren privilegios de sudo"; exit 1; }

# === PREVENCIÓN DE ACTUALIZACIÓN REPETIDA ===
if [ -f "$UPDATE_RECORD" ] && [ "$(date -r "$UPDATE_RECORD" +%F)" = "$(date +%F)" ]; then
    echo "Ya se realizó una actualización hoy."
    exit 0
fi

# === INICIO DEL PROCESO ===
log "INICIO DE ACTUALIZACIÓN"
log "Usuario: $USER"
log "Kernel: $(uname -r)"

# === RESPALDO DE LISTA DE PAQUETES ===
pacman -Q > "$LOG_DIR/paquetes_antes.txt"

# === ACTUALIZACIÓN DE PAQUETES OFICIALES ===
log "Actualizando paquetes oficiales con pacman..."
if ! sudo pacman -Syu 2>&1 | tee -a "$LOG_FILE"; then
    log "Error durante la actualización de pacman"
    exit 1
fi

# === LIMPIEZA DE CACHÉ ===
log "Limpiando caché de paquetes antiguos..."
if has paccache; then
    sudo paccache -r -k3 2>&1 | tee -a "$LOG_FILE"
else
    log "paccache no está instalado"
fi

# === ACTUALIZACIÓN DE AUR ===
if has yay; then
    log "Actualizando paquetes AUR con yay..."
    yay -Sua --noconfirm 2>&1 | tee -a "$LOG_FILE"
else
    log "yay no está instalado"
fi

# === ACTUALIZACIÓN DE FLATPAK (OPCIONAL) ===
if has flatpak; then
    log "Actualizando paquetes Flatpak..."
    flatpak update -y 2>&1 | tee -a "$LOG_FILE"
    flatpak repair 2>&1 | tee -a "$LOG_FILE"
    flatpak uninstall --unused -y 2>&1 | tee -a "$LOG_FILE"
fi

# === COMPARACIÓN DE CAMBIOS EN PAQUETES ===
pacman -Q > "$LOG_DIR/paquetes_despues.txt"
diff "$LOG_DIR/paquetes_antes.txt" "$LOG_DIR/paquetes_despues.txt" > "$LOG_DIR/cambios.txt"

log "Resumen de cambios:"
if [ -s "$LOG_DIR/cambios.txt" ]; then
    cat "$LOG_DIR/cambios.txt" | tee -a "$LOG_FILE"
else
    log "No hubo cambios en la lista de paquetes."
fi

# === INFORMACIÓN DEL SISTEMA ===
if has fastfetch; then
    fastfetch 2>&1 | tee -a "$LOG_FILE"
elif has neofetch; then
    neofetch 2>&1 | tee -a "$LOG_FILE"
fi

# === LIMPIEZA FINAL ===
rm -f "$LOG_DIR/paquetes_antes.txt" "$LOG_DIR/paquetes_despues.txt" "$LOG_DIR/cambios.txt"

# === REGISTRO DE LA ACTUALIZACIÓN ===
touch "$UPDATE_RECORD"
log "FIN DE ACTUALIZACIÓN"
echo "Log guardado en: $LOG_FILE"
