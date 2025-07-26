#!/bin/bash

# === Actualización de mirrors para ArchLinux ===
# Autor: bonzoycv


# Verifica si reflector está instalado
if ! command -v reflector &> /dev/null; then
    echo "Instalando reflector..."
    sudo pacman -S --noconfirm reflector
else
    echo "Reflector ya está instalado."
fi

# Actualiza lista usando HTTPS, ordenando por velocidad, solo mirrors activos y recientes
echo "Actualizando lista de mirrors..."
sudo reflector \
  --protocol https \
  --latest 20 \
  --sort rate \
  --save /etc/pacman.d/mirrorlist

# Verifica éxito
if [ $? -ne 0 ]; then
    echo "Reflector falló. Revisa conexión o parámetros."
    exit 1
fi

# Sincroniza la base de datos de paquetes
echo "Sincronizando base de datos de paquetes..."
sudo pacman -Syy

echo "Mirrors actualizados correctamente."
