import os
import subprocess
import json

def konvertiere_mp4_zu_opus(datei):
    ausgabe_datei = os.path.splitext(datei)[0] + ".opus"
    kommando = [
        "ffmpeg", "-i", datei, "-vn", "-c:a", "libopus", "-b:a", "128k", ausgabe_datei
    ]
    subprocess.run(kommando, check=True)
    print(f"Konvertiert: {datei} zu {ausgabe_datei}")

def hat_attached_picture(datei):
    kommando = [
        "ffprobe", "-v", "error",
        "-show_entries", "stream=index,codec_type,disposition",
        "-of", "json", datei
    ]
    result = subprocess.run(kommando, capture_output=True, text=True, check=True)
    info = json.loads(result.stdout)
    for stream in info.get("streams", []):
        disposition = stream.get("disposition", {})
        if disposition.get("attached_pic", 0) == 1:
            return True, stream["index"]
    return False, None

def extrahiere_bild(datei):
    hat_pic, stream_index = hat_attached_picture(datei)
    if hat_pic:
        # Hole die Dateiendung vom Originalbild (PNG)
        bild_datei = os.path.splitext(datei)[0] + "_frame.png"
        kommando = [
            "ffmpeg", "-i", datei,
            "-map", f"0:{stream_index}",
            "-c", "copy",
            bild_datei
        ]
    else:
        bild_datei = os.path.splitext(datei)[0] + "_frame.jpg"
        kommando = [
            "ffmpeg", "-ss", "00:00:17", "-i", datei,
            "-frames:v", "1", "-q:v", "3", bild_datei
        ]
    subprocess.run(kommando, check=True)
    print(f"Bild extrahiert: {bild_datei}")


def main():
    for datei in sorted(os.listdir('.')):
        if datei.endswith('.mp4'):
            try:
                konvertiere_mp4_zu_opus(datei)
                #extrahiere_bild(datei)
            except subprocess.CalledProcessError as e:
                print(f"Fehler bei Verarbeitung von {datei}: {e}")

if __name__ == "__main__":
    main()
