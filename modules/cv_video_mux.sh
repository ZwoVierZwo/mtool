run_video_mux() {
    local file_de=$1
    local file_en=$2

    # 1. Dauer beider Dateien auslesen (in Sekunden)
    local dur_de dur_en
    dur_de=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file_de")
    dur_en=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file_en")

    # 2. Differenz berechnen (absolute Zahl ohne Vorzeichen)
    local diff
    diff=$(echo "$dur_de - $dur_en" | bc -l | sed 's/-//')

    echo "📏 Zeit-Check: DE ($dur_de s) | EN ($dur_en s) | Diff: $diff s"

    # 3. Prüfung: Wenn Differenz > 2.0 Sekunden, dann Warnung und Abbruch
    if (( $(echo "$diff > 2.0" | bc -l) )); then
        echo -e "\033[1;31m⚠️  Abbruch: Zeitdifferenz zu groß ($diff s)! Nicht synchron?\033[0m"
        return 1
    fi

    # 4. Zusammenfügen (Muxing)
    local output="${file_de%.*}_Dual.mkv"
    echo "🎬 Muxing zu $output..."

    ffmpeg -i "$file_de" -i "$file_en" \
        -map 0:v:0 -map 0:a:0 -map 1:a:0 \
        -c copy \
        -metadata:s:a:0 language=ger -metadata:s:a:0 title="Deutsch" \
        -metadata:s:a:1 language=eng -metadata:s:a:1 title="English" \
        "$output" -y > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "\033[1;32m✔ Erfolgreich zusammengefügt!\033[0m"
    else
        echo -e "\033[1;31m✘ Fehler beim Muxen.\033[0m"
    fi
}

start_video_muxing() {
    echo -e "\n🔍 Suche nach Sprach-Paaren..."
    shopt -s nocaseglob

    local found=0
    for f_en in *" (Englisch)".{mp4,mkv,avi}; do
        [ -e "$f_en" ] || continue

        local base="${f_en% (Englisch).*}"
        local ext="${f_en##*.}"
        local f_de="${base}.$ext"
        local f_dual="${base}_Dual.mkv" # Das erwartete Ziel

        if [ -f "$f_de" ]; then
            # --- SCHUTZ-LOGIK ---
            if [ -f "$f_dual" ]; then
                # Falls die Dual-Datei schon da ist, ignorieren wir das Paar
                echo -e "⏭️  Bereits vorhanden: $f_dual (Wird übersprungen)"
                continue
            fi
            # --------------------

            found=1
            echo -e "\n------------------------------------------------"
            echo -e "💎 \033[1;32mNEUES PAAR GEFUNDEN:\033[0m"
            echo -e "   🇩🇪 DE: $f_de"
            echo -e "   🇬🇧 EN: $f_en"
            echo -e "------------------------------------------------"

            read -r -p "❓ Zusammenfügen zu '$f_dual'? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                run_video_mux "$f_de" "$f_en"
            else
                echo -e "⏭️  Übersprungen."
            fi
        fi
    done

    [ $found -eq 0 ] && echo -e "✨ Keine neuen Paare zu verarbeiten."

    shopt -u nocaseglob
    echo ""
    read -r -p "🏁 ENTER..."
}