#!/usr/bin/env bash
# Prepara un sandbox Linux remoto (senza Godot/Android SDK preinstallati) a
# validare le modifiche PRIMA di commit/push, invece di scoprire un errore
# solo dopo averlo pushato e aver aspettato un run CI. Installa Godot
# headless e (se mancante) Xvfb/Mesa per gli script che richiedono un vero
# contesto di rendering (es. tools/_capture_ui_screenshots.gd). Non
# sostituisce il percorso locale Windows di docs/setup.md: qui non c'è
# Android SDK/NDK, quindi non esporta l'APK, solo GDScript/scene/test.
#
# Uso:
#   tools/setup-remote-sandbox.sh
#   godot --headless --editor --path . --quit                 # warm-up cache import
#   godot --headless --path . -s addons/gut/gut_cmdln.gd \
#     -gdir=res://tests/unit -gexit                            # GUT (adatta ai file voluti)
#   xvfb-run --auto-servernum --server-args="-screen 0 2424x1080x24" \
#     godot --path . --script tools/_capture_ui_screenshots.gd # catture UI (serve rendering vero)

set -euo pipefail

GODOT_VERSION="4.7.1-stable"
INSTALL_PATH="/usr/local/bin/godot"

if command -v godot >/dev/null 2>&1; then
	echo "Godot già presente: $(godot --version)"
else
	echo "Installo Godot ${GODOT_VERSION}..."
	tmp_dir="$(mktemp -d)"
	trap 'rm -rf "${tmp_dir}"' EXIT
	curl -fsSL -o "${tmp_dir}/godot.zip" \
		"https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
	unzip -q "${tmp_dir}/godot.zip" -d "${tmp_dir}/godot_bin"
	install -m 0755 "${tmp_dir}/godot_bin/Godot_v${GODOT_VERSION}_linux.x86_64" "${INSTALL_PATH}"
	godot --version
fi

if command -v xvfb-run >/dev/null 2>&1; then
	echo "Xvfb già presente."
else
	echo "Installo Xvfb e Mesa software GL..."
	apt-get update -qq
	apt-get install -y --no-install-recommends xvfb mesa-utils libgl1-mesa-dri libglx-mesa0
fi

echo "Setup completato. Vedi l'intestazione dello script per i comandi di validazione."
