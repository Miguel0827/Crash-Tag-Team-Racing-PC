# Crash Tag Team Racing PC - what install.sh, config.sh and play.sh share (sourced, not run): where things are, the language of
# the windows (Spanish or English, from $LANG), the zenity windows when there is a desktop, the saved settings, the menu entries
# and the Partidas folder. Without zenity or a desktop everything works from the terminal.
pkg="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
root="${CTTR_ROOT:-$pkg/engine}"
conf="$root/cttr-linux.conf"
icon="$pkg/tools/starter/logo.png"
title="Crash Tag Team Racing PC"

gui=0
if [ "${CTTR_NO_GUI:-0}" != 1 ] && command -v zenity > /dev/null && { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; }; then gui=1; fi
case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in es*) es=1 ;; *) es=0 ;; esac
t() { if [ "$es" = 1 ]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }
# zenity 4 wants the kind of window (--forms, --question...) first, before --title. GSK_RENDERER=cairo: its GTK 4 draws in
# software when the GPU path fails (WSL, some virtual machines); a few small windows do not need the GPU.
# The launcher's purple: linux/theme/gtk-4.0/gtk.css, for these windows only (XDG_CONFIG_HOME), on GTK's dark style.
z() {
  local kind="$1"; shift
  GSK_RENDERER="${GSK_RENDERER:-cairo}" XDG_CONFIG_HOME="$pkg/linux/theme" ADW_DEBUG_COLOR_SCHEME=prefer-dark \
    zenity "$kind" --title="$title" "$@" 2> /dev/null
}
say_error() {
  printf '\nERROR: %s\n' "$1" >&2
  if [ "$gui" = 1 ]; then z --error --width=480 --text="$1"; fi
}

# the settings the Config window saves and play.sh uses (key=value lines)
conf_get() { [ -f "$conf" ] && sed -nE "s/^$1=(.*)$/\1/p" "$conf" | tail -n1; return 0; }
conf_set() {
  mkdir -p "$(dirname "$conf")"; touch "$conf"
  if grep -q "^$1=" "$conf"; then sed -i "s|^$1=.*|$1=$2|" "$conf"; else echo "$1=$2" >> "$conf"; fi
}
installed_games() {
  local n
  for n in cttr_eu cttr_us; do
    [ -f "$root/games/$n/region.json" ] && [ -x "$root/build/native-$n/ps2run" ] && echo "$n"
  done
  return 0
}

# the entries in the desktop's application menu (the game, and the Config window), with the Wumpa icon
apps_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
write_entry() {  # file, name, script, comment
  mkdir -p "$(dirname "$1")"
  cat > "$1" << EOF
[Desktop Entry]
Type=Application
Name=$2
Comment=$4
Exec=bash "$3"
Path=$pkg
Icon=$icon
Terminal=false
Categories=Game;
StartupWMClass=cttr-pc
EOF
  chmod +x "$1"
}
make_menu_entries() {
  write_entry "$apps_dir/cttr-pc.desktop" "Crash Tag Team Racing" "$pkg/linux/play.sh" "$(t 'Play' 'Jugar')"
  write_entry "$apps_dir/cttr-pc-config.desktop" "Crash Tag Team Racing - Config" "$pkg/linux/config.sh" "$(t 'Install and settings' 'Instalar y configurar')"
  command -v update-desktop-database > /dev/null && update-desktop-database "$apps_dir" 2> /dev/null
  return 0
}
desktop_file() {
  local d
  d="$(xdg-user-dir DESKTOP 2> /dev/null)"; [ -n "$d" ] || d="$HOME/Desktop"
  echo "$d/crash-tag-team-racing.desktop"
}
make_desktop_shortcut() {
  local f; f="$(desktop_file)"
  mkdir -p "$(dirname "$f")"
  cp "$apps_dir/cttr-pc.desktop" "$f" && chmod +x "$f"
  gio set "$f" metadata::trusted true 2> /dev/null   # GNOME: start it without asking
  return 0
}

# "Partidas" next to the programs: a link per installed version to the folder with its saves, and a note on which file is which
update_saves_folder() {
  local dir="$pkg/Partidas" n link
  mkdir -p "$dir"
  for n in $(installed_games); do
    link="$dir/$([ "$n" = cttr_eu ] && echo Europa || echo USA)"
    [ -e "$link" ] || [ -L "$link" ] || ln -s "$root/games/$n" "$link"
  done
  [ -f "$dir/LEEME - README.txt" ] || cat > "$dir/LEEME - README.txt" << 'EOF'
Tus partidas de Crash Tag Team Racing PC (una carpeta por versión: Europa / USA)

  memcard.ps2        la tarjeta de memoria: tus partidas del juego. Copia este archivo para tener una copia de seguridad.
  states/quick_*     los guardados rápidos (F5 guarda, F8 carga)
  memcard.backups/   copias de seguridad automáticas de la tarjeta

Cierra el juego antes de copiar o reemplazar estos archivos.

Your Crash Tag Team Racing PC saves (one folder per version: Europa = Europe / USA)

  memcard.ps2        the memory card: your game saves. Copy this file to back them up.
  states/quick_*     quick saves (F5 saves, F8 loads)
  memcard.backups/   automatic backups of the card

Close the game before copying or replacing these files.
EOF
  return 0
}
