import os
import sqlite3
import sys

# Versuche mutagen zu laden, falls installiert
try:
    from mutagen import File
except ImportError:
    File = None

def load_config():
    config = {}
    # Pfad zur mtool.conf (eine Ebene über modules/)
    base_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    conf_path = os.path.join(base_path, "mtool.conf")

    if os.path.exists(conf_path):
        with open(conf_path, "r") as f:
            for line in f:
                if "=" in line and not line.startswith("#"):
                    name, value = line.split("=", 1)
                    # Entfernt Leerzeichen UND Anführungszeichen (" oder ')
                    clean_value = value.strip().strip('"').strip("'")
                    config[name.strip()] = clean_value
    return config


def setup_db(db_path):
    # Wandelt die Tilde ~ in /home/user um
    full_path = os.path.expanduser(db_path)

    # Erstellt den Ordner (~/.mtool), falls er nicht existiert
    os.makedirs(os.path.dirname(full_path), exist_ok=True)

    conn = sqlite3.connect(full_path)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS tracks (
            id INTEGER PRIMARY KEY,
            filepath TEXT UNIQUE,
            artist TEXT,
            album TEXT,
            title TEXT,
            format TEXT
        )
    ''')
    conn.commit()
    print(f"🗄️  Datenbank bereit: {full_path}")
    return conn

def cleanup_db(conn):
    cursor = conn.cursor()
    cursor.execute('SELECT id, filepath FROM tracks')
    rows = cursor.fetchall()

    deleted_count = 0
    for row_id, filepath in rows:
        if not os.path.exists(filepath):
            cursor.execute('DELETE FROM tracks WHERE id = ?', (row_id,))
            deleted_count += 1

    conn.commit()
    if deleted_count > 0:
        print(f"🧹 Bereinigung: {deleted_count} veraltete Einträge gelöscht.")


def scan_audio(path, conn):
    if File is None:
        print("❌ 'mutagen' nicht gefunden. Bitte 'sudo apt install python3-mutagen' ausführen.")
        return

    cursor = conn.cursor()
    extensions = ('.flac', '.mp3', '.m4a', '.ogg', '.opus')
    print(f"🔎 Scanne Verzeichnis: {path} ...")

    found_count = 0
    for root, dirs, files in os.walk(path):
        for file in files:
            if file.lower().endswith(extensions):
                full_path = os.path.join(root, file)
                try:
                    audio = File(full_path, easy=True)
                    # Falls Tags fehlen, nutzen wir Fallbacks
                    artist = audio.get('artist', ['Unbekannt'])[0]
                    album = audio.get('album', ['Unbekannt'])[0]
                    title = audio.get('title', [file])[0]
                    ext = os.path.splitext(file)[1][1:].upper()

                    cursor.execute('''
                        INSERT OR REPLACE INTO tracks (filepath, artist, album, title, format)
                        VALUES (?, ?, ?, ?, ?)
                    ''', (full_path, artist, album, title, ext))
                    found_count += 1
                except Exception as e:
                    print(f"⚠️  Fehler bei {file}: {e}")

    conn.commit()
    print(f"✅ Scan beendet. {found_count} Dateien verarbeitet.")

if __name__ == "__main__":
    conf = load_config()
    # Nutzt den Pfad aus der Config oder einen Standard im Home-Ordner
    db_path_from_conf = conf.get("DB_NAME", "~/.mtool/music_archive.db")

    current_scan_path = sys.argv[1] if len(sys.argv) > 1 else "."

    db_conn = setup_db(db_path_from_conf)
    cleanup_db(db_conn)
    scan_audio(current_scan_path, db_conn)
    db_conn.close()