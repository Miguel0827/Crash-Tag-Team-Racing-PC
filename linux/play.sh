#!/usr/bin/env bash
# Crash Tag Team Racing PC - starts the converted game on Linux with the settings of the Config window (linux/config.sh).
# Nothing installed yet: the installer opens instead. Options given here win over the saved settings, for this start only:
#   ./linux/play.sh [--us|--eu] [--scale 1-4] [--fps] [--psp] [--window] [--lang 1-6]
#   --fps   50/60 FPS patch      --psp   PSP content unlock      --window   no full screen
#   --lang  game language: 1 English, 2 French, 3 Spanish, 4 German, 5 Italian, 6 Dutch (European disc)
# In the game, F1 opens the quick menu (resolution, picture, vertical sync, keys, quick save/load).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/ui.sh"

want="$(conf_get version)"; scale="$(conf_get scale)"; look="$(conf_get look)"; vsync="$(conf_get vsync)"
fps="$(conf_get fps)"; psp="$(conf_get psp)"; full="$(conf_get full)"; lang="$(conf_get lang)"
: "${fps:=0}" "${psp:=0}" "${full:=1}"
while [ $# -gt 0 ]; do
  case "$1" in
    --us) want=cttr_us ;; --eu) want=cttr_eu ;;
    --scale) scale="$2"; shift ;;
    --fps) fps=1 ;; --psp) psp=1 ;; --window) full=0 ;;
    --lang) lang="$2"; shift ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) echo "unknown option: $1 (see --help)" >&2; exit 1 ;;
  esac
  shift
done

games=($(installed_games))
if [ ${#games[@]} -eq 0 ]; then
  [ "$gui" = 1 ] && exec bash "$here/install.sh"
  echo "$(t 'The game is not installed: run' 'El juego no está instalado: ejecuta') ./linux/install.sh /path/to/your/game.iso" >&2
  exit 1
fi
name="${games[0]}"
for n in "${games[@]}"; do [ "$n" = "$want" ] && name="$n"; done
game="$root/games/$name"
exe="$root/build/native-$name/ps2run"
elf="$(sed -nE 's/.*"elf": *"([^"]+)".*/\1/p' "$game/region.json")"
wide="$(sed -nE 's/.*"widescreen": *(true|false).*/\1/p' "$game/region.json")"

# keys.ini (read by the game itself): resolution, picture look and vertical sync, and the right stick's left-right the right way round
ini="$game/keys.ini"
touch "$ini"
set_ini() { if grep -qE "^[[:space:]]*$1[[:space:]]*=" "$ini"; then sed -i -E "s/^[[:space:]]*$1[[:space:]]*=.*/$1 = $2/" "$ini"; else echo "$1 = $2" >> "$ini"; fi; }
if [ -n "$scale" ]; then set_ini scale "$scale"; elif ! grep -qE '^[[:space:]]*scale[[:space:]]*=' "$ini"; then set_ini scale 2; fi
[ -z "$look" ] || set_ini look "$look"
if [ -n "$vsync" ]; then set_ini vsync "$vsync"; elif ! grep -qE '^[[:space:]]*vsync[[:space:]]*=' "$ini"; then set_ini vsync on; fi
set_ini right_invert x

# the patches of this run: wide screen always, the others when chosen
{
  for f in ws $([ "$fps" = 1 ] && echo fps) $([ "$psp" = 1 ] && echo psp); do
    if [ -s "$game/patchsets/$f.txt" ]; then cat "$game/patchsets/$f.txt"; echo; fi   # (a disc may lack the FPS or PSP patch)
  done
} | sed '/^$/d' > "$game/patches_run.txt"

# languages: the game's from the settings (or --lang), else from $LANG (European disc); the quick menu in Spanish or English
case "${LANG:-}" in es*) def=3 ;; fr*) def=2 ;; de*) def=4 ;; it*) def=5 ;; nl*) def=6 ;; *) def=1 ;; esac
[ "$name" = cttr_us ] && def=1 && lang=1
[ -n "$lang" ] || lang=$def
menu=$([ "$es" = 1 ] && echo es || echo en)

elf_path="games/$name/patched/$elf"; [ -f "$root/$elf_path" ] || elf_path="games/$name/disc/$elf"
args=("$elf_path" --disc "games/$name/disc.iso" --window --game-dir "games/$name" --memcard "games/$name/memcard.ps2" --patches "games/$name/patches_run.txt")
[ "$wide" = true ] && args+=(--widescreen)
[ "$full" = 1 ] && args+=(--fullscreen)
cd "$root"
# the window: the Wumpa icon, and the name the menu entry (cttr-pc.desktop, StartupWMClass) is matched by in the taskbar
export PS2_WINDOW_ICON="$pkg/tools/starter/icon.bmp" SDL_VIDEO_X11_WMCLASS=cttr-pc SDL_VIDEO_WAYLAND_WMCLASS=cttr-pc
started_log="$({ ls -t "$game"/logs/ps2run_*.log 2> /dev/null || true; } | head -n1)"
set +e
PS2_LANGUAGE="$lang" PS2_MENU_LANG="$menu" PS2_GPU_BACKEND=vulkan PS2_DMA_TIME=120,16 "$exe" "${args[@]}"
code=$?
set -e
# The game closed with an error: a crash (exit code not 0), or a log that ends in anything but a window closed or Quit from the
# F1 menu. A report goes next to the programs, and a window says so (the console gets it too).
log="$({ ls -t "$game"/logs/ps2run_*.log 2> /dev/null || true; } | head -n1)"
[ "$log" != "$started_log" ] || log=""
reason=""; [ -z "$log" ] || reason="$(grep -E '^\[ee\] stopped after' "$log" | tail -n1 | sed -E 's/^[^:]*:[^:]*: //')"
if [ "$code" != 0 ] || { [ -n "$log" ] && ! printf '%s' "$reason" | grep -qE 'window closed|quit from the quick menu'; }; then
  report="$pkg/Informes de error/error-$(date +%Y-%m-%d_%H-%M-%S).txt"
  mkdir -p "$(dirname "$report")"
  {
    echo "$title $(sed -nE 's/.*(v[0-9]+\.[0-9]+\.[0-9]+)".*/\1/p' "$here/config.sh" | head -n1) (Linux)"
    echo; echo "Game: $name ($elf)"; echo "Exit code: $code"; echo "Stopped: ${reason:-no end line in the log}"
    echo "Settings: scale $(sed -nE 's/^[[:space:]]*scale[[:space:]]*=[[:space:]]*//p' "$ini" | tail -n1), full screen $full"
    echo "PC: $(uname -sr); $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //') ($(nproc) threads); $(awk '/MemTotal/ { printf "%.1f", $2 / 1048576 }' /proc/meminfo) GB RAM"
    echo "Graphics: $(command -v lspci > /dev/null && lspci | grep -iE 'vga|3d|display' | cut -d: -f3- | sed 's/^ //' | paste -sd ';' -)"
    echo "Log: ${log:-none}"; echo; echo '--- last lines of the log ---'
    [ -z "$log" ] || grep -vE '^\[(fileio|cdvdfsv|iop-io)\]' "$log" | tail -n 40
  } > "$report" 2> /dev/null
  msg="$(t "Sorry: the game closed because of an error. It is not your fault.
A report of what happened was saved to:
$report
Please send it (attach the file) so it can be fixed:
https://github.com/Miguel0827/Crash-Tag-Team-Racing-PC/issues" "Lo sentimos: el juego se cerró por un error. No es culpa tuya.
Se guardó un informe de lo que pasó en:
$report
Envíalo (adjunta el archivo) para poder arreglarlo:
https://github.com/Miguel0827/Crash-Tag-Team-Racing-PC/issues")"
  printf '\n%s\n' "$msg" >&2
  if [ "$gui" = 1 ]; then z --error --width=620 --no-markup --text="$msg"; fi
fi
exit "$code"