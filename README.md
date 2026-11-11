# Crash Tag Team Racing PC

**By NyxBorn**

Native PC port of *Crash Tag Team Racing* (PlayStation 2) built with [ps2-native-recomp](https://github.com/exoteric33/ps2-native-recomp): the game's own code is translated to C++ and compiled for Windows **on your PC, from your own disc**. This project contains **no game code, no game data and no disc images**.

*Port nativo para PC de Crash Tag Team Racing (PS2). El juego se convierte en tu PC a partir de tu propia copia. Este proyecto no contiene nada del juego.* (Español abajo.)

## What you need

- Windows 10/11, 64-bit, and an internet connection for the first install (about 1 GB of tools is downloaded).
- An ISO you made from **your own** Crash Tag Team Racing disc. Supported:
  - **Europe / Australia** — SLES-53439 (English, French, German, Spanish, Italian, Dutch)
  - **USA / Latin America** — SLUS-21191 (English)
- A graphics card with Vulkan or Direct3D 12.

## Use

1. Double-click **`Crash Tag Team Racing PC Port.bat`**.
2. Click **Import ISO...** and choose your ISO. The installer downloads the converter, applies this project's fixes and converts the game. It takes several minutes the first time.
3. Choose your settings and press **PLAY**. The launcher remembers them.

In the game, **F1** opens the quick menu (resolution, picture, vertical sync, camera, keys, quick save/load).

## What this project adds

Fixes to ps2-native-recomp (`patches/cttr-fixes.patch`, made for commit `b1af7232b320`):

- **Freeze after the intro film fixed**: a lost wake-up in the drawing queue on Windows (and messages too large for the queue are split).
- **Vector unit programs no longer recompiled thousands of times**: the game rewrites the LOI constants inside its VU1 microcode every frame; they are now read at run time and ignored when a program is recognised. CPU use drops from ~95 % to normal.
- **Title screen and menus 9x lighter** (`PS2_DMA_TIME`): GIF transfers take the time the console would take (PATH3 waits behind VIF1's geometry), so the game no longer draws the same scene 18 times per frame.
- **Quick menu (F1)** in English and Spanish (accented letters added to the font), **vertical sync** option, **invert right stick** option.

The launcher (`tools/Launcher.ps1`) and installer (`tools/Instalar.ps1`) are in English, Spanish, French, German, Italian and Portuguese.

Optional patches from the PCSX2 community (downloaded during install from [PCSX2/pcsx2_patches](https://github.com/PCSX2/pcsx2_patches), not included here): 16:9 widescreen (Arapapa, nemesis2000, PeterDelta), 50/60 FPS (PeterDelta / asasega), PSP content unlock (CRASHARKI).

**ReShade** (optional, Vulkan) is not included: install it yourself from [reshade.me](https://reshade.me) for `ps2run.exe` if you want SMAA or sharpening.

## Where things go

Everything stays in this folder: the installer creates **`engine/`** next to `tools/` with the converter, its tools (~1 GB) and your converted games, saves and settings. `engine/` is listed in `.gitignore`; delete it before sharing or uploading this folder.

## Do not share

Do not share ISOs, the converted program (`ps2run.exe` and the generated C++), or saves. They contain the game, which belongs to its owners.

## Credits and licences

- [ps2-native-recomp](https://github.com/exoteric33/ps2-native-recomp) © Samir Nuri and exoteric33, MIT licence. The fixes in `patches/` are under the same licence.
- Launcher, installer and fixes: **NyxBorn**, MIT licence (`LICENSE`).
- Crash Tag Team Racing © Activision / Radical Entertainment. This is an unofficial fan project, not affiliated with or endorsed by them.

---

## Español

1. Abre **`Crash Tag Team Racing PC Port.bat`**.
2. Pulsa **Importar ISO...** y elige la ISO de **tu propio disco** (Europa SLES-53439 o USA/Latinoamérica SLUS-21191). La primera vez tarda varios minutos: descarga el convertidor, aplica los arreglos de este proyecto y convierte el juego.
3. Elige la configuración y pulsa **JUGAR**.

En el juego, **F1** abre el menú rápido. La versión europea trae español; la de USA solo inglés.

Todo queda en esta carpeta: el instalador crea **`engine`** con el convertidor, sus herramientas y tus juegos convertidos, partidas y configuración. Bórrala antes de compartir o subir la carpeta.

No compartas ISOs ni el juego convertido: contienen el juego, que es de sus dueños.
