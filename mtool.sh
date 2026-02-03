#!/bin/bash

# Pfade ermitteln
BASE_DIR="$(dirname "$(readlink -f "$0")")"
MOD_DIR="$BASE_DIR/modules"
CONF_FILE="$BASE_DIR/mtool.env"

# 1. Config laden (Werte für das Menü)
if [ -f "$CONF_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONF_FILE"
else
    # Fallback falls Config fehlt
    BITRATE_OPUS=160; BITRATE_AAC=256; BITRATE_OGG=256; BITRATE_MP3=320; IMG_QUALITY=95
fi

# 2. Module laden
mkdir -p "$MOD_DIR"
for module in "$MOD_DIR"/*.sh; do
    # shellcheck disable=SC1090
    [ -f "$module" ] && source "$module"
done

# --- HAUPTMENÜ ---
while true; do
    clear
    echo -e "\033[1;34m      ⭐ UNIVERSAL M-TOOL: MODULAR ⭐      \033[0m"
    echo "------------------------------------------------"

    echo -e "🖼️  \033[1;33mBILDER (Quadratisch, Qualität: $IMG_QUALITY%)\033[0m"
    echo "  1) WebP -> JPG"
    echo "  2) PNG  -> JPG"
    echo "  3) MP4  -> JPG"
    echo ""

    echo -e "🎬 \033[1;33mVIDEO -> AUDIO (Extraktion)\033[0m"
    echo "  4) MP4  -> OPUS (${BITRATE_VIDEO_OPUS}k)"
    echo "  5) MP4  -> AAC  (${BITRATE_VIDEO_AAC}k)"
    echo "  6) Dual-Audio Mux (DE + EN -> MKV)"
    echo ""

    echo -e "🎵 \033[1;33mAUDIO -> AUDIO (Konvertierung)\033[0m"
    echo "  7) FLAC -> OPUS (${BITRATE_OPUS}k)"
    echo "  8) FLAC -> AAC  (${BITRATE_AAC}k)"
    echo "  9) FLAC -> OGG  (${BITRATE_OGG}k)"
    echo "  10) FLAC -> MP3  (${BITRATE_MP3}k)"
    echo ""

    echo -e "📚 \033[1;33mHÖRBUCH (Merge - Ohne Verlust)\033[0m"
    echo " 11) Alle MP3 -> Eine Datei"
    echo " 12) Alle M4A -> Eine Datei"
    echo "------------------------------------------------"

    echo -e "🧠 \033[1;35mPYTHON INTELLIGENZ\033[0m"
    echo " 14) Musik-Archiv scan (SQLite DB)"
    echo " 15) Lyrics extrahieren (.txt)"
    echo "------------------------------------------------"

    echo "  m) ⌨️  Manuelle Eingabe"
    echo "  q) 🚪 Beenden"
    echo "------------------------------------------------"
    echo -n " 👉 Wahl: "
    read -r choice

    case $choice in
        1) run_image_conv "webp" "jpg" "$IMG_QUALITY" ;;
        2) run_image_conv "png" "jpg" "$IMG_QUALITY" ;;
        3) run_video_to_img "mp4" "jpg" "$IMG_QUALITY";;
        4) run_audio_conv "mp4" "opus" "$BITRATE_VIDEO_OPUS" ;;
        5) run_audio_conv "mp4" "aac" "$BITRATE_VIDEO_AAC" ;;
        7) run_audio_conv "flac" "opus" "$BITRATE_OPUS" ;;
        8) run_audio_conv "flac" "aac" "$BITRATE_AAC" ;;
        9) run_audio_conv "flac" "ogg" "$BITRATE_OGG" ;;
        10) run_audio_conv "flac" "mp3" "$BITRATE_MP3" ;;
        11) run_audio_merge "mp3" ;;
        12) run_audio_merge "m4a" ;;
        14) python3 "$MOD_DIR/cv_db.py" "$(pwd)"; echo ""; read -p "Drücke ENTER für Menü..." ;;
        15) python3 "$MOD_DIR/cv_lyrics.py" "$(pwd)"; echo ""; read -p "Drücke ENTER für Menü..." ;;
        m)
            echo -e "\n⌨️  Manuell:"
            read -r -p " Dateiendung Quelle (z.B. wav): " my_in
            read -r -p " Zielformat (z.B. mp3): " my_out
            read -r -p " Qualität/Bitrate (z.B. 320): " my_qual
            if [[ "$my_out" =~ (jpg|png|webp) ]]; then
                run_image_conv "$my_in" "$my_out" "$my_qual"
            else
                run_audio_conv "$my_in" "$my_out" "$my_qual"
            fi
            ;;
        q) clear; exit 0 ;;
        *) echo -e "\033[1;31m❌ Ungültige Wahl!\033[0m"; sleep 1 ;;
    esac
done