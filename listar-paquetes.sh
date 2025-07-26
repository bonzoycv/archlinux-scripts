#!/bin/bash

# Este script genera listas separadas de paquetes instalados desde:
# - Repositorios oficiales de Arch (pacman)
# - AUR (paquetes instalados vía yay u otros helpers)
# - Flatpak (contenedor de apps)

# ========================
# Paquetes instalados con pacman (oficiales + AUR)
# ========================
# Obtiene todos los paquetes instalados localmente
# y filtra solo los que provienen de repos oficiales
# (es decir, NO construidos localmente)
pacman -Qqen > paquetes_oficiales.txt
# Explicación:
# -Q  : consulta a la base de datos de paquetes instalados
# -q  : salida en formato simple (solo el nombre del paquete)
# -e  : paquetes instalados explícitamente (no como dependencias)
# -n  : paquetes que NO son locales, es decir, provienen de los repos oficiales

# ========================
# Paquetes instalados desde AUR
# ========================
# Lista paquetes que son explícitos (-e) y locales (-m), lo que implica que
# no están en los repos oficiales → normalmente vienen del AUR
pacman -Qqem > paquetes_aur.txt
# -m : indica paquetes "locales" (no están en ningún repositorio oficial)

# ========================
# Paquetes instalados con Flatpak
# ========================
# Lista todas las aplicaciones flatpak instaladas por el usuario o globalmente
flatpak list --app --columns=application > paquetes_flatpak.txt
# --app : muestra solo aplicaciones (no runtimes)
# --columns=application : solo el nombre de la aplicación

# Mensaje final
echo "Listas generadas:"
echo "- paquetes_oficiales.txt"
echo "- paquetes_aur.txt"
echo "- paquetes_flatpak.txt"
