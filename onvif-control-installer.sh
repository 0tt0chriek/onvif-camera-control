#!/bin/bash

# 🔍 1. Identify the operating system
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    # Handle openSUSE derivatives (opensuse-leap, opensuse-tumbleweed, etc.)
    if [[ "$OS" == opensuse* ]]; then
        OS="opensuse"
    fi
else
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
fi

# 🛑 2. OS Check and Routing
case "$OS" in
    void|gentoo)
        echo "========================================================="
        echo "🕵️  Detected System: ${NAME:-$OS}"
        echo "--------------------------------------------------------="
        echo "Respect! You are running a system for true power users."
        echo "Since you prefer total control anyway, this script will"
        echo "gracefully exit to let you do your magic manually."
        echo "Happy customizing!"
        echo "========================================================="
        exit 0
        ;;
    
    ubuntu|debian|fedora|arch|opensuse)
        echo "🚀 Supported system detected: ${NAME:-$OS}"
        echo "Proceeding with the script..."
        ;;
    
    *)
        echo "⚠️ Unknown or untested system ($OS). Use at your own risk!"
        # Optional: exit 1 (to block unknown OS) or let it run
        ;;
esac

# ==========================================
# 🔧 CONFIGURATION
# ==========================================
APP_NAME="onvif_control"
PY_SCRIPT="onvif_control.py"
INSTALL_DIR="$HOME/.local/share/$APP_NAME"
BIN_DIR="$HOME/.local/bin"
DESKTOP_FILE="$HOME/.local/share/applications/$APP_NAME.desktop"
TOOLBOX_NAME="onvif-toolbox"

# ==========================================
# 🐍 EMBEDDED PYTHON SCRIPT
# ==========================================
# Using 'EOF' in quotes to prevent Bash from evaluating Python variables (like $PROFILE)
generate_python_script() {
    echo "Unpacking Python application..."
    cat << 'EOF' > "$INSTALL_DIR/$PY_SCRIPT"
import sys
import subprocess
import tkinter as tk
from tkinter import ttk, messagebox
from onvif import ONVIFCamera
from datetime import datetime
import os
import shutil
import json

# ==========================================
# 🌍 (DE, EN, ES, FR, PT)
# ==========================================
TEXTE = {
    "de": {
        "titel": "📹 Kamera Steuerung",
        "lbl_auswahl": " Kamera & Aufnahme ",
        "lbl_steuerung": " Steuerung (WASD) ",
        "lbl_presets": " Schnellwahl (Presets) ",
        "btn_verbinden": "Verbinden & Laden",
        "btn_rec_start": "🔴 Aufnahme starten",
        "btn_rec_stop": "⏹️ Aufnahme stoppen",
        "btn_einstellungen": "⚙️ Kameras verwalten",
        "btn_sichern": "💾 Sichern",
        "up": "▲ Hoch", "down": "▼ Runter", "left": "◀ Links", "right": "Rechts ▶",
        "preset": "📍 Position",
        "not_connected": "Nicht verbunden",
        "connecting": "Verbinde...",
        "connected": "✅ Verbunden",
        "rec_running": "🔴 Aufnahme läuft...",
        "rec_saved": "✅ Video gespeichert!",
        "no_cam": "Keine Kameras vorhanden",
        "warn_no_cam": "Richte zuerst eine Kamera im Menü ein!",
        "warn_connect_first": "Verbinde dich zuerst mit einer Kamera!",
        "err_title": "Fehler",
        "err_connect": "Verbindung fehlgeschlagen:\n",
        "set_title": "⚙️ Kameras verwalten",
        "set_list": "Kamera-Liste:",
        "set_name": "Kamera-Name:",
        "set_ip": "IP-Adresse:",
        "set_user": "ONVIF Benutzer:",
        "set_pass": "Passwort:",
        "set_inv_x": "Links/Rechts tauschen",
        "set_inv_y": "Hoch/Runter tauschen",
        "set_save_new": "💾 Sichern / Neu",
        "set_delete": "🗑️ Löschen",
        "set_fill_all": "Bitte alle Felder ausfüllen!",
        "set_saved_suc": "Kamera gespeichert!",
        "set_del_confirm": "Möchtest du sie wirklich löschen?",
        "dir_title": "Ordner auswählen",
        "dir_chosen": "Gewählter Pfad:",
        "dir_btn": "✅ Wählen"
    },
    "en": {
        "titel": "📹 Camera Control",
        "lbl_auswahl": " Camera & Recording ",
        "lbl_steuerung": " Control (WASD) ",
        "lbl_presets": " Fast Presets ",
        "btn_verbinden": "Connect & Load",
        "btn_rec_start": "🔴 Start Recording",
        "btn_rec_stop": "⏹️ Stop Recording",
        "btn_einstellungen": "⚙️ Manage Cameras",
        "btn_sichern": "💾 Save",
        "up": "▲ Up", "down": "▼ Down", "left": "◀ Left", "right": "Right ▶",
        "preset": "📍 Position",
        "not_connected": "Not connected",
        "connecting": "Connecting...",
        "connected": "✅ Connected",
        "rec_running": "🔴 Recording...",
        "rec_saved": "✅ Video saved!",
        "no_cam": "No cameras found",
        "warn_no_cam": "Please set up a camera in settings first!",
        "warn_connect_first": "Please connect to a camera first!",
        "err_title": "Error",
        "err_connect": "Connection failed:\n",
        "set_title": "⚙️ Manage Cameras",
        "set_list": "Camera List:",
        "set_name": "Camera Name:",
        "set_ip": "IP Address:",
        "set_user": "ONVIF Username:",
        "set_pass": "Password:",
        "set_inv_x": "Invert Left/Right",
        "set_inv_y": "Invert Up/Down",
        "set_save_new": "💾 Save / New",
        "set_delete": "🗑️ Delete",
        "set_fill_all": "Please fill in all fields!",
        "set_saved_suc": "Camera saved!",
        "set_del_confirm": "Do you really want to delete this camera?",
        "dir_title": "Select Folder",
        "dir_chosen": "Selected Path:",
        "dir_btn": "✅ Select"
    },
    "es": {
        "titel": "📹 Control de Cámara",
        "lbl_auswahl": " Cámara y Grabación ",
        "lbl_steuerung": " Control ",
        "lbl_presets": " Posiciones rápidas ",
        "btn_verbinden": "Conectar y Cargar",
        "btn_rec_start": "🔴 Grabar",
        "btn_rec_stop": "⏹️ Detener",
        "btn_einstellungen": "⚙️ Ajustes",
        "btn_sichern": "💾 Guardar",
        "up": "▲ Arriba", "down": "▼ Abajo", "left": "◀ Izquierda", "right": "Derecha ▶",
        "preset": "📍 Posición",
        "not_connected": "Desconectado",
        "connecting": "Conectando...",
        "connected": "✅ Conectado",
        "rec_running": "🔴 Grabando...",
        "rec_saved": "✅ ¡Guardado!",
        "no_cam": "Sin cámaras",
        "warn_no_cam": "¡Configure una cámara!",
        "warn_connect_first": "¡Conéctese primero!",
        "err_title": "Error",
        "err_connect": "Fallo:\n",
        "set_title": "⚙️ Ajustes",
        "set_list": "Lista:",
        "set_name": "Nombre:",
        "set_ip": "IP:",
        "set_user": "Usuario:",
        "set_pass": "Contraseña:",
        "set_inv_x": "Invertir X",
        "set_inv_y": "Invertir Y",
        "set_save_new": "💾 Nuevo",
        "set_delete": "🗑️ Borrar",
        "set_fill_all": "Rellene todo!",
        "set_saved_suc": "¡Guardado!",
        "set_del_confirm": "¿Borrar?",
        "dir_title": "Carpeta",
        "dir_chosen": "Ruta:",
        "dir_btn": "✅ Elegir"
    },
    "fr": {
        "titel": "📹 Contrôle Caméra",
        "lbl_auswahl": " Caméra & Enregistrement ",
        "lbl_steuerung": " Contrôle ",
        "lbl_presets": " Positions ",
        "btn_verbinden": "Connecter",
        "btn_rec_start": "🔴 Enregistrer",
        "btn_rec_stop": "⏹️ Arrêter",
        "btn_einstellungen": "⚙️ Réglages",
        "btn_sichern": "💾 Sauvegarder",
        "up": "▲ Haut", "down": "▼ Bas", "left": "◀ Gauche", "right": "Droite ▶",
        "preset": "📍 Position",
        "not_connected": "Déconnecté",
        "connecting": "Connexion...",
        "connected": "✅ Connecté",
        "rec_running": "🔴 Enregistrement...",
        "rec_saved": "✅ Sauvegardé!",
        "no_cam": "Aucune caméra",
        "warn_no_cam": "Configurez une caméra!",
        "warn_connect_first": "Connectez-vous d'abord!",
        "err_title": "Erreur",
        "err_connect": "Échec:\n",
        "set_title": "⚙️ Réglages",
        "set_list": "Liste:",
        "set_name": "Nom:",
        "set_ip": "IP:",
        "set_user": "Utilisateur:",
        "set_pass": "Passe:",
        "set_inv_x": "Inverser X",
        "set_inv_y": "Inverser Y",
        "set_save_new": "💾 Nouveau",
        "set_delete": "🗑️ Supprimer",
        "set_fill_all": "Remplir tout!",
        "set_saved_suc": "Sauvegardé!",
        "set_del_confirm": "Supprimer?",
        "dir_title": "Dossier",
        "dir_chosen": "Chemin:",
        "dir_btn": "✅ Choisir"
    },
    "pt": {
        "titel": "📹 Controle de Câmera",
        "lbl_auswahl": " Câmera & Gravação ",
        "lbl_steuerung": " Controle (WASD) ",
        "lbl_presets": " Posições Rápidas ",
        "btn_verbinden": "Conectar e Carregar",
        "btn_rec_start": "🔴 Iniciar Gravação",
        "btn_rec_stop": "⏹️ Parar Gravação",
        "btn_einstellungen": "⚙️ Gerenciar Câmeras",
        "btn_sichern": "💾 Salvar",
        "up": "▲ Cima", "down": "▼ Baixo", "left": "◀ Esquerda", "right": "Direita ▶",
        "preset": "📍 Posição",
        "not_connected": "Não conectado",
        "connecting": "Conectando...",
        "connected": "✅ Conectado",
        "rec_running": "🔴 Gravando...",
        "rec_saved": "✅ Vídeo salvo!",
        "no_cam": "Nenhuma câmera encontrada",
        "warn_no_cam": "Configure uma câmera primeiro no menu!",
        "warn_connect_first": "Conecte-se a uma câmera primeiro!",
        "err_title": "Erro",
        "err_connect": "Falha na conexão:\n",
        "set_title": "⚙️ Gerenciar Câmeras",
        "set_list": "Lista de Câmeras:",
        "set_name": "Nome da Câmera:",
        "set_ip": "Endereço IP:",
        "set_user": "Usuário ONVIF:",
        "set_pass": "Senha:",
        "set_inv_x": "Inverter Esquerda/Direita",
        "set_inv_y": "Inverter Cima/Baixo",
        "set_save_new": "💾 Salvar / Novo",
        "set_delete": "🗑️ Excluir",
        "set_fill_all": "Por favor, preencha todos os campos!",
        "set_saved_suc": "Câmera salva!",
        "set_del_confirm": "Tem certeza de que deseja excluir?",
        "dir_title": "Selecionar Pasta",
        "dir_chosen": "Caminho Selecionado:",
        "dir_btn": "✅ Selecionar"
    }
}

SPRACH_MAP = {
    "English 🇬🇧": "en",
    "Deutsch 🇩🇪": "de",
    "Español 🇪🇸": "es",
    "Français 🇫🇷": "fr",
    "Português 🇵🇹🇧🇷": "pt"
}

# ==========================================
# ⚙️  CONFIGURATION
# ==========================================
CONFIG_FILE = os.path.join(os.path.expanduser("~"), ".onvif_kameras.json")
ONVIF_PORT = 2020
SCHRITT_X = 0.05
SCHRITT_Y = 0.05

BG_DARK = "#1e1e1e"
BG_PANEL = "#2d2d2d"
FG_TEXT = "#ffffff"
ACCENT = "#3a3a3a"
HIGHLIGHT = "#0078d4"


def lade_konfiguration():
    daten = {"kameras": {}, "aufnahme_pfad": os.path.expanduser("~"), "sprache": "en"}
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                gl = json.load(f)
                if isinstance(gl, dict) and "kameras" in gl:
                    if "sprache" not in gl:
                        gl["sprache"] = "en"
                    return gl
        except Exception: pass
    return daten


def speichere_konfiguration(kameras, aufnahme_pfad, sprache="en"):
    try:
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump({
                "kameras": kameras, 
                "aufnahme_pfad": aufnahme_pfad, 
                "sprache": sprache
            }, f, indent=4)
    except Exception: pass


class OnvifControlApp:
    def __init__(self, root):
        self.root = root
        self.root.geometry("1320x690")
        self.root.configure(bg=BG_DARK)
        
        konfig = lade_konfiguration()
        self.kameras = konfig["kameras"]
        self.aufnahme_pfad = konfig["aufnahme_pfad"]
        
        self.cam = None
        self.ptz = None
        self.profile = None
        self.mpv_process = None
        
        self.is_recording = False
        self.invert_x = False
        self.invert_y = False

        self.aktuelle_sprache_code = konfig.get("sprache", "en")
        start_lang_name = "English 🇬🇧"
        for name, code in SPRACH_MAP.items():
            if code == self.aktuelle_sprache_code:
                start_lang_name = name
                break

        self.setup_styles()
        self.create_widgets()

        self.root.bind('<w>', lambda event: self.bewege_gefiltert(0.0, -SCHRITT_Y))
        self.root.bind('<s>', lambda event: self.bewege_gefiltert(0.0, SCHRITT_Y))
        self.root.bind('<a>', lambda event: self.bewege_gefiltert(-SCHRITT_X, 0.0))
        self.root.bind('<d>', lambda event: self.bewege_gefiltert(SCHRITT_X, 0.0))

        self.root.protocol("WM_DELETE_WINDOW", self.on_close)
        
        self.selected_lang.set(start_lang_name)
        self.sprache_wechseln()

    def setup_styles(self):
        style = ttk.Style()
        style.theme_use("clam")
        style.configure(".", background=BG_DARK, foreground=FG_TEXT, font=("Arial", 10))
        style.configure("TFrame", background=BG_DARK)
        style.configure("TLabelframe", background=BG_DARK, bordercolor=ACCENT)
        style.configure("TLabelframe.Label", background=BG_DARK, foreground=FG_TEXT, font=("Arial", 10, "bold"))
        style.configure("TButton", background=ACCENT, foreground=FG_TEXT, borderwidth=1, bordercolor=BG_DARK)
        style.map("TButton", background=[("active", "#4a4a4a")])
        style.configure("Record.TButton", background="#802020", foreground=FG_TEXT)

    def create_widgets(self):
        main_paned = ttk.PanedWindow(self.root, orient="horizontal")
        main_paned.pack(fill="both", expand=True, padx=5, pady=5)

        left_frame = tk.Frame(main_paned, width=300, bg=BG_DARK)
        left_frame.pack_propagate(False)
        main_paned.add(left_frame, weight=0)

        lang_frame = tk.Frame(left_frame, bg=BG_DARK)
        lang_frame.pack(fill="x", padx=10, pady=(5, 0))
        
        self.selected_lang = tk.StringVar()
        self.lang_dropdown = tk.OptionMenu(lang_frame, self.selected_lang, *SPRACH_MAP.keys(), command=lambda _: self.sprache_wechseln())
        self.lang_dropdown.config(bg=BG_PANEL, fg=FG_TEXT, highlightthickness=0, bd=0)
        self.lang_dropdown["menu"].config(bg=BG_PANEL, fg=FG_TEXT)
        self.lang_dropdown.pack(side="right")

        self.lf_auswahl = ttk.LabelFrame(left_frame, text="", padding=8)
        self.lf_auswahl.pack(fill="x", padx=5, pady=5)

        self.selected_cam = tk.StringVar()
        self.dropdown = tk.OptionMenu(self.lf_auswahl, self.selected_cam, "")
        self.dropdown.config(bg=BG_PANEL, fg=FG_TEXT, highlightthickness=0, bd=0)
        self.dropdown["menu"].config(bg=BG_PANEL, fg=FG_TEXT)
        self.dropdown.pack(fill="x", pady=5)

        self.btn_verbinden = ttk.Button(self.lf_auswahl, text="", command=self.verbinde_kamera)
        self.btn_verbinden.pack(fill="x", pady=2)
        
        self.btn_record = ttk.Button(self.lf_auswahl, text="", command=self.toggle_aufnahme)
        self.btn_record.pack(fill="x", pady=5)

        o_frame = tk.Frame(self.lf_auswahl, bg=BG_DARK)
        o_frame.pack(fill="x", pady=5)
        self.lbl_folder = tk.Label(o_frame, text=self.kurzer_pfad(self.aufnahme_pfad), bg=BG_DARK, fg="#aaaaaa", font=("Arial", 8), anchor="w")
        self.lbl_folder.pack(side="left", fill="x", expand=True)
        ttk.Button(o_frame, text="📂", width=3, command=self.waehle_speicherort).pack(side="right")

        self.lbl_status = ttk.Label(self.lbl_status, text="", foreground="#ff9900") if hasattr(self, 'lbl_status') else ttk.Label(self.lf_auswahl, text="", foreground="#ff9900")
        self.lbl_status.pack(pady=2)

        self.btn_einstellungen = ttk.Button(self.lf_auswahl, text="", command=self.oeffne_einstellungen)
        self.btn_einstellungen.pack(fill="x", pady=5)

        self.lf_steuerung = ttk.LabelFrame(left_frame, text="", padding=8)
        self.lf_steuerung.pack(fill="x", padx=5, pady=5)
        g_frame = tk.Frame(self.lf_steuerung, bg=BG_DARK)
        g_frame.pack(pady=5)
        
        self.btn_up = ttk.Button(g_frame, text="", width=10, command=lambda: self.bewege_gefiltert(0.0, -SCHRITT_Y))
        self.btn_up.grid(row=0, column=1, pady=3)
        self.btn_left = ttk.Button(g_frame, text="", width=10, command=lambda: self.bewege_gefiltert(-SCHRITT_X, 0.0))
        self.btn_left.grid(row=1, column=0, padx=3)
        self.btn_right = ttk.Button(g_frame, text="", width=10, command=lambda: self.bewege_gefiltert(SCHRITT_X, 0.0))
        self.btn_right.grid(row=1, column=2, padx=3)
        self.btn_down = ttk.Button(g_frame, text="", width=10, command=lambda: self.bewege_gefiltert(0.0, SCHRITT_Y))
        self.btn_down.grid(row=2, column=1, pady=3)

        self.lf_presets = ttk.LabelFrame(left_frame, text="", padding=8)
        self.lf_presets.pack(fill="x", padx=5, pady=5)
        self.btn_p1 = ttk.Button(self.lf_presets, text="", command=lambda: self.gehe_zu_preset("1"))
        self.btn_p1.pack(fill="x", pady=3)
        self.btn_p2 = ttk.Button(self.lf_presets, text="", command=lambda: self.gehe_zu_preset("2"))
        self.btn_p2.pack(fill="x", pady=3)
        self.btn_p3 = ttk.Button(self.lf_presets, text="", command=lambda: self.gehe_zu_preset("3"))
        self.btn_p3.pack(fill="x", pady=3)
        self.btn_p4 = ttk.Button(self.lf_presets, text="", command=lambda: self.gehe_zu_preset("4"))
        self.btn_p4.pack(fill="x", pady=3)
        
        tk.Frame(self.lf_presets, height=2, bg=ACCENT).pack(fill="x", pady=8)

        self.selected_save_preset = tk.StringVar(value="1")
        p_drop = tk.OptionMenu(self.lf_presets, self.selected_save_preset, "1", "2", "3", "4")
        p_drop.config(bg=BG_PANEL, fg=FG_TEXT, highlightthickness=0, bd=0)
        p_drop["menu"].config(bg=BG_PANEL, fg=FG_TEXT)
        p_drop.pack(side="left", padx=5)

        self.btn_sichern = ttk.Button(self.lf_presets, text="", command=self.speichere_preset)
        self.btn_sichern.pack(side="right", fill="x", expand=True, padx=5)

        self.video_container = tk.Frame(main_paned, bg="black")
        main_paned.add(self.video_container, weight=1)

    def sprache_wechseln(self):
        gewaehlter_name = self.selected_lang.get()
        self.aktuelle_sprache_code = SPRACH_MAP[gewaehlter_name]
        self.T = TEXTE[self.aktuelle_sprache_code]

        speichere_konfiguration(self.kameras, self.aufnahme_pfad, self.aktuelle_sprache_code)

        self.root.title(self.T["titel"])
        self.lf_auswahl.config(text=self.T["lbl_auswahl"])
        self.lf_steuerung.config(text=self.T["lbl_steuerung"])
        self.lf_presets.config(text=self.T["lbl_presets"])
        self.btn_verbinden.config(text=self.T["btn_verbinden"])
        self.btn_record.config(text=self.T["btn_rec_stop"] if self.is_recording else self.T["btn_rec_start"])
        self.btn_einstellungen.config(text=self.T["btn_einstellungen"])
        self.btn_sichern.config(text=self.T["btn_sichern"])
        self.btn_up.config(text=self.T["up"])
        self.btn_down.config(text=self.T["down"])
        self.btn_left.config(text=self.T["left"])
        self.btn_right.config(text=self.T["right"])
        self.btn_p1.config(text=f"{self.T['preset']} 1")
        self.btn_p2.config(text=f"{self.T['preset']} 2")
        self.btn_p3.config(text=f"{self.T['preset']} 3")
        self.btn_p4.config(text=f"{self.T['preset']} 4")
        self.aktualisiere_dropdown()

    def waehle_speicherort(self):
        dir_win = tk.Toplevel(self.root)
        dir_win.title(self.T["dir_title"])
        dir_win.geometry("500x400")
        dir_win.configure(bg=BG_DARK)
        dir_win.grab_set()

        akt = tk.StringVar(value=self.aufnahme_pfad)
        tk.Label(dir_win, text=self.T["dir_chosen"], bg=BG_DARK, fg=FG_TEXT).pack(pady=(10, 0))
        tk.Label(dir_win, textvariable=akt, bg=BG_PANEL, fg=FG_TEXT).pack(fill="x", padx=10, ipady=4)

        b = tk.Listbox(dir_win, bg=BG_PANEL, fg=FG_TEXT)
        b.pack(fill="both", expand=True, padx=10, pady=10)

        def lade(p):
            b.delete(0, tk.END); b.insert(tk.END, "..")
            try:
                for e in sorted(os.listdir(p)):
                    if os.path.isdir(os.path.join(p, e)) and not e.startswith("."): b.insert(tk.END, e)
            except Exception: pass

        lade(akt.get())

        def klick(evt):
            if not b.curselection(): return
            aus = b.get(b.curselection()[0])
            n = os.path.dirname(akt.get()) if aus == ".." else os.path.join(akt.get(), aus)
            if os.path.exists(n): akt.set(n); lade(n)

        b.bind('<Double-Button-1>', klick)

        def okay():
            self.aufnahme_pfad = akt.get(); self.lbl_folder.config(text=self.kurzer_pfad(self.aufnahme_pfad))
            speichere_konfiguration(self.kameras, self.aufnahme_pfad, self.aktuelle_sprache_code); dir_win.destroy()

        ttk.Button(dir_win, text=self.T["dir_btn"], command=okay).pack(pady=10)

    def kurzer_pfad(self, p):
        h = os.path.expanduser("~")
        return p.replace(h, "~") if len(p.replace(h, "~")) <= 30 else "..." + p.replace(h, "~")[-27:]

    def aktualisiere_dropdown(self):
        menu = self.dropdown["menu"]
        menu.delete(0, "end")
        if self.kameras:
            for name in self.kameras.keys(): menu.add_command(label=name, command=tk._setit(self.selected_cam, name))
            if self.selected_cam.get() not in self.kameras: self.selected_cam.set(list(self.kameras.keys())[0])
        else: self.selected_cam.set(self.T["no_cam"])

    def oeffne_einstellungen(self):
        win = tk.Toplevel(self.root)
        win.title(self.T["set_title"])
        win.geometry("580x460")
        win.configure(bg=BG_DARK)
        win.grab_set()

        lf = tk.Frame(win, bg=BG_DARK); lf.pack(side="left", fill="both", expand=True, padx=10, pady=10)
        tk.Label(lf, text=self.T["set_list"], bg=BG_DARK, fg=FG_TEXT).pack(anchor="w")
        box = tk.Listbox(lf, bg=BG_PANEL, fg=FG_TEXT, highlightthickness=0); box.pack(fill="both", expand=True)
        for name in self.kameras: box.insert(tk.END, name)

        rf = tk.Frame(win, bg=BG_DARK); rf.pack(side="right", fill="both", expand=True, padx=10, pady=10)
        tk.Label(rf, text=self.T["set_name"], bg=BG_DARK, fg=FG_TEXT).pack(anchor="w")
        en_n = tk.Entry(rf, bg=BG_PANEL, fg=FG_TEXT, relief="flat"); en_n.pack(fill="x", ipady=4)
        tk.Label(rf, text=self.T["set_ip"], bg=BG_DARK, fg=FG_TEXT).pack(anchor="w")
        en_i = tk.Entry(rf, bg=BG_PANEL, fg=FG_TEXT, relief="flat"); en_i.pack(fill="x", ipady=4)
        tk.Label(rf, text=self.T["set_user"], bg=BG_DARK, fg=FG_TEXT).pack(anchor="w")
        en_u = tk.Entry(rf, bg=BG_PANEL, fg=FG_TEXT, relief="flat"); en_u.pack(fill="x", ipady=4)
        tk.Label(rf, text=self.T["set_pass"], bg=BG_DARK, fg=FG_TEXT).pack(anchor="w")
        en_p = tk.Entry(rf, show="*", bg=BG_PANEL, fg=FG_TEXT, relief="flat"); en_p.pack(fill="x", ipady=4)

        vx, vy = tk.BooleanVar(), tk.BooleanVar()
        tk.Checkbutton(rf, text=self.T["set_inv_x"], variable=vx, bg=BG_DARK, fg=FG_TEXT, selectcolor=BG_PANEL).pack(anchor="w")
        tk.Checkbutton(rf, text=self.T["set_inv_y"], variable=vy, bg=BG_DARK, fg=FG_TEXT, selectcolor=BG_PANEL).pack(anchor="w")

        def select(evt):
            if not box.curselection(): return
            n = box.get(box.curselection()[0]); d = self.kameras[n]
            en_n.delete(0, tk.END); en_n.insert(0, n)
            en_i.delete(0, tk.END); en_i.insert(0, d['ip'])
            en_u.delete(0, tk.END); en_u.insert(0, d['user'])
            en_p.delete(0, tk.END); en_p.insert(0, d['pass'])
            vx.set(d.get("invert_x", False)); vy.set(d.get("invert_y", False))

        box.bind('<<ListboxSelect>>', select)

        def save():
            n = en_n.get().strip()
            if not n or not en_i.get() or not en_u.get() or not en_p.get(): return
            self.kameras[n] = {"ip": en_i.get().strip(), "user": en_u.get().strip(), "pass": en_p.get().strip(), "invert_x": vx.get(), "invert_y": vy.get()}
            speichere_konfiguration(self.kameras, self.aufnahme_pfad, self.aktuelle_sprache_code)
            box.delete(0, tk.END)
            for k in self.kameras: box.insert(tk.END, k)
            self.sprache_wechseln()

        def delete():
            if not box.curselection(): return
            n = box.get(box.curselection()[0])
            if messagebox.askyesno(self.T["set_delete"], f"{n}: {self.T['set_del_confirm']}", parent=win):
                del self.kameras[n]; speichere_konfiguration(self.kameras, self.aufnahme_pfad, self.aktuelle_sprache_code)
                box.delete(box.curselection()[0]); self.sprache_wechseln()

        b_box = tk.Frame(rf, bg=BG_DARK); b_box.pack(fill="x", pady=15)
        ttk.Button(b_box, text=self.T["set_save_new"], command=save).pack(side="left", fill="x", expand=True, padx=2)
        ttk.Button(b_box, text=self.T["set_delete"], command=delete).pack(side="right", fill="x", expand=True, padx=2)

    def verbinde_kamera(self):
        c = self.selected_cam.get()
        if c == self.T["no_cam"]: return
        d = self.kameras[c]; self.invert_x, self.invert_y = d.get("invert_x", False), d.get("invert_y", False)
        self.stoppe_live_preview()
        try:
            self.cam = ONVIFCamera(d['ip'], ONVIF_PORT, d['user'], d['pass'])
            self.ptz = self.cam.create_ptz_service(); self.profile = self.cam.create_media_service().GetProfiles()[0]
            self.starte_live_preview(d['ip'], d['user'], d['pass'])
        except Exception: pass

    def toggle_aufnahme(self):
        if not self.cam: return
        cam_name = self.selected_cam.get()
        cam_data = self.kameras[cam_name]
        
        if not self.is_recording:
            self.is_recording = True
            self.btn_record.config(text=self.T["btn_rec_stop"])
            ts = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
            self.temp_filename = f"/tmp/{cam_name}_{ts}.ts"
            self.final_filename = os.path.join(self.aufnahme_pfad, f"{cam_name}_{ts}.ts")
            self.starte_live_preview(cam_data['ip'], cam_data['user'], cam_data['pass'], aufnahme_pfad=self.temp_filename)
        else:
            self.is_recording = False; self.btn_record.config(text=self.T["btn_rec_start"])
            self.starte_live_preview(cam_data['ip'], cam_data['user'], cam_data['pass'])
            if os.path.exists(self.temp_filename): 
                try: shutil.move(self.temp_filename, self.final_filename)
                except Exception: pass

    def starte_live_preview(self, ip, user, password, aufnahme_pfad=None):
        self.stoppe_live_preview()
        url = f"rtsp://{user}:{password}@{ip}:554/stream1"
        args = ["--ontop", f"--wid={self.video_container.winfo_id()}", "--vo=xv,x11", "--no-border"]
        if aufnahme_pfad: args.append(f"--stream-record={aufnahme_pfad}")
        args.append(url)
        for cmd in [["mpv"] + args, ["flatpak", "run", "io.mpv.Mpv"] + args, ["flatpak-spawn", "--host", "flatpak", "run", "io.mpv.Mpv"] + args]:
            try: 
                self.mpv_process = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                break
            except Exception: continue

    def bewege_gefiltert(self, x, y):
        if not self.ptz: return
        try:
            req = self.ptz.create_type('RelativeMove')
            req.ProfileToken = self.profile.token
            req.Translation = {'PanTilt': {'x': -x if self.invert_x else x, 'y': -y if self.invert_y else y}}
            self.ptz.RelativeMove(req)
        except Exception: pass

    def gehe_zu_preset(self, t):
        if not self.ptz: return
        try:
            req = self.ptz.create_type('GotoPreset')
            req.ProfileToken = self.profile.token; req.PresetToken = t
            self.ptz.GotoPreset(req)
        except Exception: pass

    def speichere_preset(self):
        if not self.ptz: return
        try:
            req = self.ptz.create_type('SetPreset')
            req.ProfileToken = self.profile.token; req.PresetToken = self.selected_save_preset.get()
            self.ptz.SetPreset(req)
        except Exception: pass

    def stoppe_live_preview(self):
        if self.mpv_process: self.mpv_process.terminate(); self.mpv_process = None
        subprocess.call(["pkill", "mpv"])

    def on_close(self):
        self.stoppe_live_preview(); self.root.destroy()


if __name__ == "__main__":
    root = tk.Tk(); app = OnvifControlApp(root); root.mainloop()
EOF
}


# ==========================================
# 🛑 UNINSTALL LOGIC
# ==========================================
uninstall() {
    echo -e "\n🗑️ Starting uninstallation..."

    # 1. Stop and delete toolbx (if Fedora Silverblue/Atomic)
    if [ -f /usr/bin/rpm-ostree ]; then
        if toolbox list 2>/dev/null | grep -q "$TOOLBOX_NAME"; then
            echo "Stopping and deleting toolbx '$TOOLBOX_NAME'..."
            podman stop "$TOOLBOX_NAME" 2>/dev/null
            toolbox rm -f "$TOOLBOX_NAME"
        fi
    fi

    # 2. Delete Python Virtual Environment (for standard Linux distributions)
    if [ -d "$INSTALL_DIR/venv" ]; then
        echo "Deleting Python Virtual Environment (venv)..."
        rm -rf "$INSTALL_DIR/venv"
    fi

    # 3. Delete the entire program directory (including scripts and shell.nix)
    if [ -d "$INSTALL_DIR" ]; then
        echo "Deleting program directory: $INSTALL_DIR"
        rm -rf "$INSTALL_DIR"
    fi

    # 4. Delete wrapper script in bin directory
    if [ -f "$BIN_DIR/$APP_NAME" ]; then
        echo "Deleting launcher: $BIN_DIR/$APP_NAME"
        rm -f "$BIN_DIR/$APP_NAME"
    fi

    # 5. Delete .desktop menu entry
    if [ -f "$DESKTOP_FILE" ]; then
        echo "Deleting desktop shortcut: $DESKTOP_FILE"
        rm -f "$DESKTOP_FILE"
    fi

    echo -e "\n=========================================="
    echo "✅ Uninstallation completed successfully for all systems!"
    echo "=========================================="
    exit 0
}


# ==========================================
# 🏁 MENU & SYSTEM DETECTION
# ==========================================
clear
echo "=========================================="
echo "📹 ONVIF Camera Control - Management"
echo "=========================================="
echo "What would you like to do?"
echo "  [1] Install / Update"
echo "  [2] Uninstall (Completely remove everything)"
echo "------------------------------------------"
read -p "Choice (1 or 2): " USER_CHOICE

case "$USER_CHOICE" in
    2) uninstall ;;
    1|*) echo -e "\n🚀 Starting installation..." ;;
esac


# ==========================================
# 📥 INSTALLATION LOGIC
# ==========================================

# 1. Detect System Type
echo -e "\n📦 Checking system environment..."

if [ -f /etc/NIXOS ]; then
    echo "❄️ NixOS detected!"
    SYSTEM_TYPE="nixos"

elif [ -f /usr/bin/rpm-ostree ]; then
    echo "⚛️ Fedora Silverblue / Atomic Desktop detected!"
    SYSTEM_TYPE="atomic"

elif [ -f /etc/debian_version ]; then
    # ✅ Ubuntu & Debian
    echo "🟠 Debian/Ubuntu detected!"
    PM_CMD="sudo apt-get update && sudo apt-get install -y python3 python3-pip python3-venv mpv fonts-noto-color-emoji"

elif grep -q "opensuse" /etc/os-release 2>/dev/null; then
    # ✅ openSUSE
    echo "🟢 openSUSE detected!"
    PM_CMD="sudo zypper install -y python3 python3-pip mpv google-noto-coloremoji-fonts"

elif [ -f /etc/redhat-release ]; then
    # ✅ Fedora Workstation / RHEL
    echo "🔴 Fedora Workstation / RHEL detected!"
    PM_CMD="sudo dnf install -y python3 python3-pip mpv google-noto-emoji-fonts"

elif [ -f /etc/arch-release ]; then
    # ✅ Arch Linux
    echo "🔵 Arch Linux detected!"
    PM_CMD="sudo pacman -Syu --noconfirm python python-pip mpv noto-fonts-emoji"
fi

if [ -n "$PM_CMD" ] && [ "$SYSTEM_TYPE" != "nixos" ] && [ "$SYSTEM_TYPE" != "atomic" ]; then
    echo "Running: $PM_CMD"
    eval $PM_CMD
fi

# 2. Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# ✨ GENERATE PYTHON SCRIPT AUTOMATICALLY FROM SCRIPT INNARDS
generate_python_script

# 3. System-specific installation
if [ "$SYSTEM_TYPE" == "nixos" ]; then
    # --- NIXOS STRATEGY ---
    echo "Creating shell.nix..."
    cat << EOF > "$INSTALL_DIR/shell.nix"
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = [
    pkgs.python3
    pkgs.python3Packages.onvif-zeep
    pkgs.noto-fonts-color-emoji
    pkgs.mpv
  ];
}
EOF

    cat << EOF > "$BIN_DIR/$APP_NAME"
#!/bin/bash
nix-shell "$INSTALL_DIR/shell.nix" --run "python3 $INSTALL_DIR/$PY_SCRIPT"
EOF

elif [ "$SYSTEM_TYPE" == "atomic" ]; then
    # --- 🧰 FEDORA SILVERBLUE STRATEGIE (SLIM TOOLBX + FLATPAK MPV) ---
    echo "Setting up Fedora Toolbx (slim)..."

    if ! flatpak list --columns=application | grep -q "io.mpv.Mpv"; then
        echo "Installing mpv Flatpak on the host..."
        flatpak install --user -y flathub io.mpv.Mpv
    fi

    if ! toolbox list 2>/dev/null | grep -q "$TOOLBOX_NAME"; then
        echo "Creating new toolbx '$TOOLBOX_NAME'..."
        if ! toolbox create -c "$TOOLBOX_NAME"; then
            echo "❌ Error creating toolbx! Installation aborted."
            exit 1
        fi
        
        echo "Installing Python & Tkinter inside the toolbx..."
        toolbox run -c "$TOOLBOX_NAME" sudo dnf install -y python3-pip python3-tkinter google-noto-emoji-fonts
        toolbox run -c "$TOOLBOX_NAME" pip3 install onvif-zeep
    fi

    cat << EOF > "$BIN_DIR/$APP_NAME"
#!/bin/bash
toolbox run -c "$TOOLBOX_NAME" python3 "$INSTALL_DIR/$PY_SCRIPT" "$@"
EOF

else
    # --- STANDARD LINUX STRATEGY (VENV) ---
    echo "Creating Python Virtual Environment (venv)..."
    python3 -m venv "$INSTALL_DIR/venv"
    source "$INSTALL_DIR/venv/bin/activate"
    pip install --upgrade pip onvif-zeep
    deactivate

    cat << EOF > "$BIN_DIR/$APP_NAME"
#!/bin/bash
source "$INSTALL_DIR/venv/bin/activate"
python3 "$INSTALL_DIR/$PY_SCRIPT" "$@"
EOF
fi

chmod +x "$BIN_DIR/$APP_NAME"

# 4. .desktop Shortcut
cat << EOF > "$DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Type=Application
Name=ONVIF Camera Control
Comment=Control and PTZ for ONVIF IP Cameras
Exec=$BIN_DIR/$APP_NAME
Icon=video-display
Terminal=false
Categories=Utility;Video;
EOF

chmod +x "$DESKTOP_FILE"

echo -e "\n=========================================="
echo "✅ Installation completed!"
echo "=========================================="
