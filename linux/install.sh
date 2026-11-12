#!/usr/bin/env bash
# Crash Tag Team Racing PC - Linux installer: prepares the converter (ps2-native-recomp + this project's fixes) and turns the
# player's own disc image into the native program. Nothing of the game is in this project; it all comes from the ISO.
# On a desktop with zenity it works with windows, like the Windows installer (the own-disc question, picking the ISO, a progress
# bar, a desktop shortcut button at the end); from a terminal it asks there.
#   ./linux/install.sh [--yes] [/path/to/your/game.iso]      --yes: skip the own-disc question
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/ui.sh"
commit=b1af7232b3200b12fbb8135ba583364c992f0aa5   # the ps2-native-recomp version the fixes are made for
patch="$pkg/patches/cttr-fixes.patch"

die() { printf '\nERROR: %s\n' "$1" >&2; exit 1; }
step() { printf '\n=== %s ===\n' "$1"; }

yes=0; iso=""
for a in "$@"; do
  case "$a" in
    --yes) yes=1 ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) iso="$a" ;;
  esac
done

# ---------------------------------------------------------------- 0. what the build needs from the system
missing=()
for tool in git curl unzip python3 cmake ninja; do command -v "$tool" > /dev/null || missing+=("$tool"); done
command -v clang++ > /dev/null || compgen -c clang++- | grep -qE '^clang\+\+-[0-9]+$' || missing+=(clang)
if ! pkg-config --exists sdl2 2> /dev/null && ! command -v sdl2-config > /dev/null; then missing+=(SDL2-dev); fi
if [ ${#missing[@]} -gt 0 ]; then
  msg="$(t "Missing: ${missing[*]}
Install them first, for example:" "Faltan: ${missing[*]}
Instálalos primero, por ejemplo:")
  Debian / Ubuntu / Mint:  sudo apt install clang libc++-dev libc++abi-dev cmake ninja-build python3 libsdl2-dev git curl unzip pkg-config zenity
  Fedora:                  sudo dnf install clang libcxx-devel libcxxabi-devel cmake ninja-build python3 SDL2-devel git curl unzip pkgconf zenity
  Arch / SteamOS dev:      sudo pacman -S clang libc++ cmake ninja python sdl2 git curl unzip pkgconf zenity"
  printf '%s\n' "$msg" >&2
  if [ "$gui" = 1 ]; then z --error --width=760 --no-markup --text="$msg"; fi
  exit 1
fi

# ---------------------------------------------------------------- the player's own disc, and which ISO
own="$(t "Remember: you need your own original disc of the game." "Recuerda: necesitas tu propio disco original del juego.")"
if [ "$yes" = 0 ]; then
  if [ "$gui" = 1 ]; then
    z --question --width=460 --no-markup --text="$own" --ok-label="$(t 'Got it' 'Entendido')" --cancel-label="$(t 'Cancel' 'Cancelar')" || exit 1
  elif [ -t 0 ]; then
    printf '%s [s/N] ' "$own"; read -r answer
    case "$answer" in s*|S*|y*|Y*) ;; *) exit 1 ;; esac
  fi
fi
if [ -z "$iso" ] && [ "$gui" = 1 ]; then
  iso="$(z --file-selection --file-filter="$(t 'Disc image' 'Imagen de disco') (*.iso) | *.iso *.ISO")" || exit 1
fi
[ -n "$iso" ] || die "$(t 'usage' 'uso'): $0 /path/to/your/game.iso"
[ -f "$iso" ] || { say_error "$(t 'No such file' 'No existe el archivo'): $iso"; exit 1; }
iso="$(realpath "$iso")"

# ---------------------------------------------------------------- the installation itself (its lines are what the progress bar reads)
do_install() (
  set -e
  # 1. the converter
  mkdir -p "$root"
  # the marker names the converter version and this package's fixes; older fixes (an update extracted over it) mean the
  # converter's original files are fetched again over the old ones and the new fixes applied to them
  patch_id="$commit $(sha256sum "$patch" | cut -c1-16)"
  applied="$(cat "$root/.cttr-fixes-applied" 2> /dev/null || true)"
  stale=0; if [ -n "$applied" ] && [ "$applied" != "$patch_id" ]; then stale=1; fi
  if [ "$stale" = 1 ] || [ ! -f "$root/scripts/port.sh" ]; then
    step "Downloading ps2-native-recomp (${commit:0:12})"
    tmp="$(mktemp -d)"
    # this project's own copy (fork) first, the original repository if the copy cannot be reached
    curl -fL "https://github.com/Miguel0827/ps2-native-recomp/archive/$commit.zip" -o "$tmp/src.zip" \
      || curl -fL "https://github.com/exoteric33/ps2-native-recomp/archive/$commit.zip" -o "$tmp/src.zip" \
      || die "ps2-native-recomp could not be downloaded (no internet?)"
    unzip -q "$tmp/src.zip" -d "$tmp/x"
    cp -a "$tmp/x/ps2-native-recomp-$commit/." "$root/"
    rm -rf "$tmp"
  fi
  cd "$root"
  if [ "$stale" = 1 ] || [ ! -f .cttr-fixes-applied ]; then
    step "Applying the Crash Tag Team Racing PC fixes"
    git apply --ignore-whitespace -p1 "$patch" || die "the fixes could not be applied (another ps2-native-recomp version?)"
    echo "$patch_id" > .cttr-fixes-applied
  fi
  chmod +x scripts/*.sh 2> /dev/null || true

  step "Building the converter (setup.sh)"
  bash scripts/setup.sh --native-only

  # 2. which version is the disc
  step "Recognising the disc"
  probe="$root/games/_probe"
  rm -rf "$probe"; mkdir -p "$probe"
  fetch="$(python3 -I scripts/pnach.py fetch "$iso" --out "$probe" 2>&1 || true)"
  echo "$fetch"
  elf="$(printf '%s\n' "$fetch" | sed -nE 's/.*program:[[:space:]]+([A-Z]{4}_[0-9]{3}\.[0-9]{2}).*/\1/p' | head -n1)"
  case "$elf" in
    SLES_534.39) name=cttr_eu; region=eu; langs='[3, 1, 2, 4, 5, 6]' ;;
    SLUS_211.91) name=cttr_us; region=us; langs='[1]' ;;
    *) die "this disc is not a supported version of Crash Tag Team Racing (program: '$elf'). Supported: Europe SLES-53439, USA SLUS-21191." ;;
  esac
  pnach="$(find "$probe" -name '*.pnach' | head -n1)"
  [ -n "$pnach" ] || die "the PCSX2 patch file could not be downloaded (no internet?)"
  mkdir -p "games/patches_$region"
  cp -f "$pnach" "games/patches_$region/"
  pnach="$root/games/patches_$region/$(basename "$pnach")"
  rm -rf "$probe"
  section() { grep -E '^\[.+\][[:space:]]*$' "$pnach" | sed -E 's/^\[(.+)\][[:space:]]*$/\1/' | grep -m1 "$1" || true; }
  ws="$(section Widescreen)"; fps="$(section FPS)"; psp="$(section PSP)"
  echo "version: $region ($elf); patches: [$ws] [$fps] [$psp]"

  # 3. the port (saves and settings of an earlier import are kept)
  game="$root/games/$name"
  saved="$(mktemp -d)"
  if [ -d "$game" ]; then
    step "Cleaning an earlier install of $name (saves and settings are kept)"
    for f in "$game"/memcard.ps2* "$game"/keys.ini "$game"/states "$game"/reports; do [ -e "$f" ] && cp -a "$f" "$saved/"; done
    rm -rf "$game"
  fi
  rm -rf "build/native-$name" "generated/$name"
  mkdir -p "$game"
  cp -a "$saved/." "$game/" 2> /dev/null || true
  rm -rf "$saved"
  step "Converting the game ($name) - this takes several minutes"
  args=("$name" "$iso" --native-only)
  [ -z "$ws" ] || args+=(--pnach "$pnach" --pnach-section "$ws")
  PS2_GPU_LOW_POWER=0 bash scripts/port.sh "${args[@]}"

  # 4. the patch sets play.sh picks from
  step "Preparing the options"
  mkdir -p "$game/patchsets"
  for pair in "ws:$ws" "fps:$fps" "psp:$psp"; do
    key="${pair%%:*}"; sec="${pair#*:}"; out="$game/patchsets/$key.txt"
    if [ -z "$sec" ]; then : > "$out"; continue; fi
    python3 -I scripts/pnach.py apply "$game/disc/$elf" "$game/patchsets/tmp.elf" "$out" --section "$sec" "$pnach"
    rm -f "$game/patchsets/tmp.elf"
  done
  printf '{\n  "name": "%s",\n  "region": "%s",\n  "elf": "%s",\n  "widescreen": %s,\n  "languages": %s\n}\n' \
    "$name" "$region" "$elf" "$([ -n "$ws" ] && echo true || echo false)" "$langs" > "$game/region.json"
  echo
  echo "READY: $name installed."
)

# what the progress window shows: the step (as zenity "# text" lines) and where the bar is, as the Windows installer does
progress_lines() {
  local line
  while IFS= read -r line; do
    case "$line" in
      "=== Downloading"*)      echo 2;  echo "# $(t 'Downloading the converter' 'Descargando el convertidor')" ;;
      "=== Applying"*)         echo 16; echo "# $(t 'Applying the fixes' 'Aplicando los arreglos')" ;;
      "=== Building"*)         echo 18; echo "# $(t 'Building the converter (a few minutes)' 'Compilando el convertidor (unos minutos)')" ;;
      "=== Recognising"*)      echo 30; echo "# $(t 'Recognising the disc' 'Reconociendo el disco')" ;;
      "== [1/6]"*)             echo 34; echo "# $(t 'Reading the disc' 'Leyendo el disco')" ;;
      "== [2/6]"*)             echo 37; echo "# $(t 'Reading the disc' 'Leyendo el disco')" ;;
      "== [3/6]"*)             echo 40; echo "# $(t "Translating the game's code" 'Traduciendo el código del juego')" ;;
      "== [4/6]"*)             echo 50; echo "# $(t 'Trying the game (the longest step)' 'Probando el juego (el paso más largo)')" ;;
      "== [5/6]"*)             echo 66; echo "# $(t 'Graphics programs' 'Programas gráficos')" ;;
      "== [6/6]"*)             echo 70; echo "# $(t 'Building the game' 'Compilando el juego')" ;;
      "=== Preparing"*)        echo 96; echo "# $(t 'Preparing the options' 'Preparando opciones')" ;;
      "READY:"*)               echo 99; echo "# $(t 'Ready' 'Listo')" ;;
    esac
  done
}

log="${TMPDIR:-/tmp}/cttr-pc-install.log"
if [ "$gui" = 1 ]; then
  do_install 2>&1 | tee "$log" | progress_lines | z --progress --width=560 --percentage=1 \
    --text="$(t 'Starting...' 'Empezando...')" --cancel-label="$(t 'Cancel' 'Cancelar')"
  rc=${PIPESTATUS[0]}; zrc=${PIPESTATUS[3]}
  if [ "$zrc" != 0 ] && [ "$rc" != 0 ]; then
    z --info --width=480 --text="$(t 'Installation cancelled. The next import starts from scratch.' 'Instalación cancelada. La próxima importación empieza de cero.')"
    exit 1
  fi
else
  do_install 2>&1 | tee "$log"
  rc=${PIPESTATUS[0]}
fi
if [ "$rc" != 0 ]; then
  say_error "$(t 'The installation failed. The log is in' 'La instalación falló. El registro está en'): $log

$(grep -m1 '^ERROR' "$log" || tail -n 3 "$log")"
  exit 1
fi

# ---------------------------------------------------------------- what the player gets at the end
update_saves_folder
make_menu_entries
done_text="$(t 'Done. You can play now.
The game is in your applications menu, and your saves are in the Partidas folder.' 'Listo. Ya puedes jugar.
El juego está en tu menú de aplicaciones, y tus partidas en la carpeta Partidas.')"
if [ "$gui" = 1 ]; then
  sc_label="$(t 'Create a desktop shortcut' 'Crear acceso directo en el escritorio')"
  while true; do
    extra=(--extra-button="$sc_label"); [ -e "$(desktop_file)" ] && extra=()
    choice="$(z --question --width=520 --no-markup --text="$done_text" --ok-label="$(t 'PLAY' 'JUGAR')" --cancel-label="$(t 'Close' 'Cerrar')" "${extra[@]}")"
    zr=$?
    if [ "$choice" = "$sc_label" ]; then make_desktop_shortcut; continue; fi
    [ "$zr" = 0 ] && exec bash "$here/play.sh"
    exit 0
  done
else
  echo
  printf '%s\n' "$done_text"
  if [ -t 0 ]; then
    printf '%s [s/N] ' "$(t 'Create a desktop shortcut?' '¿Crear acceso directo en el escritorio?')"; read -r answer
    case "$answer" in s*|S*|y*|Y*) make_desktop_shortcut ;; esac
  fi
  echo "$(t 'Start it with' 'Ábrelo con'): ./linux/play.sh   ($(t 'settings' 'configuración'): ./linux/config.sh)"
fi
