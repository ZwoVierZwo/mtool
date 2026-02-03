#!/bin/bash

run_image_conv() {
    local in=$1; local out=$2; local qual=$3
    shopt -s nocaseglob
    local files=( *."$in" )

    if [ ! -e "${files[0]}" ]; then
        echo -e "\n⚠️  Keine .$in Bilder gefunden."; shopt -u nocaseglob
        read -p "ENTER..." ; return
    fi
    local target_dir
    target_dir="conv_img_$(date +%H%M%S)"
    mkdir -p "$target_dir"

    echo -e "\n🖼️  Konvertiere Bilder..."
    for file in *."$in"; do
        [ -e "$file" ] || continue
        printf "🔹 %-30s " "${file:0:27}..."
        magick "$file" -quality "$qual" -background white -alpha remove -flatten \
               -gravity center -extent "%[fx:h>w?h:w]x%[fx:h>w?h:w]" "$target_dir/${file%.*}.$out" > /dev/null 2>&1
        echo -e "\033[1;32m✔\033[0m"
    done
    shopt -u nocaseglob
    read -p "🏁 Fertig! ENTER..."
}

run_video_to_img() {
    local in="mp4" # Standardmäßig mp4, kannst du via Parameter ändern
    local out=$2   # Zielformat (jpg, png, etc.)
    local qual=$3  # Qualität
    shopt -s nocaseglob
    local files=( *."$in" )

    if [ ! -e "${files[0]}" ]; then
        echo -e "\n⚠️  Keine .$in Videos gefunden."; shopt -u nocaseglob
        read -p "ENTER..." ; return
    fi
    local target_dir
    target_dir="video_thumbs_$(date +%H%M%S)"
    mkdir -p "$target_dir"

    echo -e "\n🎞️  Erstelle Screenshots von Videos..."
    for file in *."$in"; do
        [ -e "$file" ] || continue

        # Verbesserte Anzeige des Dateinamens (längere Anzeige)
        printf "📸 %-45s " "${file:0:42}..."

        # ffmpeg Logik:
        # -ss 00:00:05 : Springt zur 5. Sekunde (vermeidet oft schwarze Intros)
        # -frames:v 1  : Extrahiert genau ein Bild
        # -q:v         : Qualität (bei jpg 2-5, wobei 2 sehr gut ist)

        ffmpeg -ss 00:00:05 -i "$file" -frames:v 1 -q:v 2 \
               "$target_dir/${file%.*}.$out" -y > /dev/null 2>&1

        echo -e "\033[1;32m✔\033[0m"
    done
    shopt -u nocaseglob
    read -p "🏁 Fertig! Screenshots sind in $target_dir. ENTER..."
}