#!/bin/bash

# === Arch News Checker ===
# Este script revisa si hay noticias nuevas en https://archlinux.org/news/
# Si hay una novedad desde la última revisión, abre el navegador.

# URL del sitio de noticias de Arch
NEWS_URL="https://archlinux.org/news/"

# Archivo donde guardaremos la última fecha que revisamos
LAST_CHECK_FILE="$HOME/.ultima_revision_archnews"

# Descargar el HTML del sitio usando curl
# -s evita que muestre la barra de progreso
html=$(curl -s "$NEWS_URL") || {
    echo "No se pudo acceder a Arch News"
    exit 1
}

# Extrae la primera fecha encontrada en el HTML (formato YYYY-MM-DD)
# grep busca coincidencias con el patrón de fecha
# head -n 1 toma solo la primera
ultima_fecha=$(echo "$html" | grep -oP '\d{4}-\d{2}-\d{2}' | head -n 1)

# Si no existe un registro previo de revisión, se crea con la fecha actual
# y se abre el navegador con la página de noticias
if [ ! -f "$LAST_CHECK_FILE" ]; then
    echo "$ultima_fecha" > "$LAST_CHECK_FILE"
    xdg-open "$NEWS_URL"
    exit 0
fi

# Lee la última fecha que fue registrada
ultima_guardada=$(cat "$LAST_CHECK_FILE")

# Si la fecha nueva es posterior a la guardada, actualiza y abre el navegador
if [[ "$ultima_fecha" > "$ultima_guardada" ]]; then
    echo "$ultima_fecha" > "$LAST_CHECK_FILE"
    xdg-open "$NEWS_URL"
else
    echo "No hay noticias nuevas de Arch Linux."
fi
