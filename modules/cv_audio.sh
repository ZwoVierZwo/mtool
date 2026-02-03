#!/bin/bash
run_audio_conv() {
    local in=$1; local out=$2; local qual=$3
    shopt -s nocaseglob
    local files=( *."$in" )

    # Prüfen, ob Dateien vorhanden sind
    if [ ! -e "${files[0]}" ]; then
        echo -e "\n⚠️  Keine .$in Dateien gefunden."; shopt -u nocaseglob
        read -p "ENTER..." ; return
    fi

    # Zielverzeichnis erstellen
    local target_dir
    target_dir="conv_audio_$(date +%H%M%S)"
    mkdir -p "$target_dir"

    echo -e "\n🎵 Verarbeite: .$in ➔ .$out (@${qual}k)..."

    for file in "${files[@]}"; do
        [ -e "$file" ] || continue
        printf "🎵 %-50s " "${file:0:47}..."

        # Codec-Zuweisung
        local codec="libopus"
        [[ "$out" == "aac" ]] && codec="aac"
        [[ "$out" == "mp3" ]] && codec="libmp3lame"
        [[ "$out" == "ogg" ]] && codec="libopus"

        # 1. VERSUCH: Stream Copy (Schnell & Verlustfrei)
        # Wir versuchen zu kopieren, wenn die Endungen gleich sind ODER es ein Video-Container ist
        local copy_possible=false
        [[ "${in,,}" == "${out,,}" ]] && copy_possible=true
        [[ "${in,,}" == "mp4" ]] && copy_possible=true

        if [ "$copy_possible" = true ]; then
            # Versuch den Audio-Stream ohne Neuberechnung zu extrahieren
            ffmpeg -i "$file" -vn -map_metadata 0 -c:a copy "$target_dir/${file%.*}.$out" -y > /dev/null 2>&1

            if [ $? -eq 0 ]; then
                echo -e "\033[1;34m➡ EXTRAHIERT (Copy)\033[0m"
                continue # Nächste Datei, da fertig
            fi
        fi

        # 2. SCHRITT: Konvertierung (Falls Copy nicht möglich oder nicht gewünscht)
        # Wenn Copy fehlschlägt oder nicht vorgesehen ist (z.B. FLAC -> Opus)
        ffmpeg -i "$file" -vn -map_metadata 0 -c:a "$codec" -b:a "${qual}k" "$target_dir/${file%.*}.$out" -y > /dev/null 2>&1

        if [ $? -eq 0 ]; then
            echo -e "\033[1;32m✔ KONVERTIERT\033[0m"
        else
            echo -e "\033[1;31m✘ FEHLER\033[0m"
        fi
    done

    shopt -u nocaseglob
    echo -e "\n---"
    read -p "🏁 Fertig! Dateien liegen in $target_dir. ENTER..."
}
}

run_audio_merge() {
    local ext=$1
    shopt -s nocaseglob
    if [ ! -e *."$ext" ]; then echo "Keine Dateien."; shopt -u nocaseglob; return; fi

    local out_file="Merged_Book_$(date +%H%M%S).$ext"
    echo -e "\n📚 Erstelle Hörbuch-Datei..."
    printf "file '%s'\n" *."$ext" > input_list.txt
    ffmpeg -f concat -safe 0 -i input_list.txt -c copy "$out_file" -y > /dev/null 2>&1
    rm input_list.txt

    shopt -u nocaseglob
    echo -e "✅ Datei erstellt: $out_file"
    read -p "ENTER..."
}