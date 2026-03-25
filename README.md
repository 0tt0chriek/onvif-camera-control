# 📹 ONVIF Camera Control (PTZ & Recording)

A lightweight Python/Tkinter GUI for controlling ONVIF cameras (Pan/Tilt/Zoom) and recording RTSP streams via `mpv`.

---

## ✨ Features
* **Multi-Distro support:** Debian, Ubuntu, Fedora, Arch, openSUSE, NixOS, and Fedora Silverblue/Atomic.
* **Safer system setup:** Uses Python Virtual Environments (`venv`) or container tools like `toolbx` to keep your host clean.
* **Fast recording:** Streams are temporarily cached in RAM (`/tmp/`) and automatically moved to your video folder when finished. No data waste left behind!

---

## 📥 Installation

1. Make the installer script executable and run the installer script:
   ```bash
   chmod +x onvif-control-installer.sh && ./onvif-control-installer.sh
