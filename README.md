# Crash Tag Team Racing PC

> [!WARNING]
> **`multiplayer` branch: unfinished work in progress.** It may not work and can change at any time. Please do not report problems from this branch. To play, use the latest [official release](https://github.com/Miguel0827/Crash-Tag-Team-Racing-PC/releases/latest).
>
> **Rama `multiplayer`: en desarrollo y sin terminar.** Puede no funcionar y cambiar en cualquier momento. No reportes errores de esta rama. Para jugar, usa la última [versión oficial](https://github.com/Miguel0827/Crash-Tag-Team-Racing-PC/releases/latest).

**By NyxBorn**

<p>
<a href="https://recomplauncher.com/game/crash-tag-team-racing-pc"><picture><source media="(prefers-color-scheme: dark)" srcset="https://recomplauncher.com/assets/press/launcher/badge-light.svg"><img src="https://recomplauncher.com/assets/press/launcher/badge-dark.svg" alt="Get it on RecompLauncher" height="56"></picture></a>
<a href="https://recompstore.com/dev/miguel0827"><picture><source media="(prefers-color-scheme: dark)" srcset="https://recompstore.com/assets/press/verified-light.svg"><img src="https://recompstore.com/assets/press/verified-dark.svg" alt="Verified developer on RecompStore" height="56"></picture></a>
</p>

**[Download the latest version](https://github.com/Miguel0827/Crash-Tag-Team-Racing-PC/releases/latest)** · [Report a problem](https://github.com/Miguel0827/Crash-Tag-Team-Racing-PC/issues/new/choose)

Native PC port of *Crash Tag Team Racing* (PlayStation 2) built with [ps2-native-recomp](https://github.com/exoteric33/ps2-native-recomp): the game's own code is translated to C++ and compiled for Windows **on your PC, from your own disc**. This project contains **no game code, no game data and no disc images**.

*Port nativo para PC de Crash Tag Team Racing (PS2). El juego se convierte en tu PC a partir de tu propia copia. Este proyecto no contiene nada del juego.* (Español abajo.)

## What you need

- Windows 10/11, 64-bit, and an internet connection for the first install (about 1 GB of tools is downloaded).
- An ISO you made from **your own** Crash Tag Team Racing disc. Supported:
  - **Europe / Australia** — SLES-53439 (English, French, German, Spanish, Italian, Dutch)
  - **USA / Latin America** — SLUS-21191 (English)
- A graphics card with Vulkan or Direct3D 12.

## Use

1. Download the zip from the [latest release](https://github.com/Miguel0827/Crash-Tag-Team-Racing-PC/releases/latest) and extract it to a short folder **without spaces and outside OneDrive**, for example `C:\Games\CTTR`.
2. Double-click **`Crash Tag Team Racing PC Port.bat`**.
3. Click **Import ISO...** and choose your ISO. The installer downloads the converter, applies this project's fixes and converts the game. It takes several minutes the first time.
4. Choose your settings and press **PLAY**. The launcher remembers them.

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

Your saves are in `engine\games\cttr_eu\memcard.ps2` (Europe) or `engine\games\cttr_us\memcard.ps2` (USA). Importing the ISO again keeps them, and the launcher's **Delete** button asks whether to keep them.

## Troubleshooting

- **"Este disco no es una versión soportada"** (this disc is not a supported version): only the Europe/Australia (SLES-53439) and USA/Latin America (SLUS-21191) discs are supported.
- **"No se pudo descargar el archivo de parches de PCSX2"** (could not download the PCSX2 patch file): the first install needs an internet connection.
- **The installation fails while building**: some of the build tools do not handle spaces in the folder path. Move this folder to a short path without spaces and outside OneDrive (for example `C:\Games\CTTR`) and import the ISO again. Each import starts clean and keeps your saves.
- **The game is slow or the picture tears**: lower **Internal resolution**, switch **Vertical sync**, or try the other **Graphics API** (Vulkan / Direct3D 12).
- **Double FPS or PSP content is greyed out**: the PCSX2 patch file for your disc version has no such patch.
- **Installer log**: `%TEMP%\cttr-pc-install.log`. Attach it when you report a problem.

## Do not share

Do not share ISOs, the converted program (`ps2run.exe` and the generated C++), or saves. They contain the game, which belongs to its owners.

## Reporting problems

Only the **official releases** are supported: the [Releases](https://github.com/Miguel0827/Crash-Tag-Team-Racing-PC/releases) page and RecompLauncher. Other branches (such as `multiplayer`) are unfinished work in progress: please do not report problems from them.

[Open a bug report](https://github.com/Miguel0827/Crash-Tag-Team-Racing-PC/issues/new/choose) and say which disc version you have and what graphics card you use. If the installation failed, attach `%TEMP%\cttr-pc-install.log`.

## Credits and licences

- [ps2-native-recomp](https://github.com/exoteric33/ps2-native-recomp) © Samir Nuri and exoteric33, MIT licence. The fixes in `patches/` are under the same licence.
- Launcher, installer and fixes: **NyxBorn**, MIT licence (`LICENSE`).
- Crash Tag Team Racing © Activision / Radical Entertainment. This is an unofficial fan project, not affiliated with or endorsed by them.

---

## Español

1. Descarga el zip de la [última versión](https://github.com/Miguel0827/Crash-Tag-Team-Racing-PC/releases/latest) y descomprímelo en una carpeta corta, **sin espacios y fuera de OneDrive**, por ejemplo `C:\Juegos\CTTR`.
2. Abre **`Crash Tag Team Racing PC Port.bat`**.
3. Pulsa **Importar ISO...** y elige la ISO de **tu propio disco** (Europa SLES-53439 o USA/Latinoamérica SLUS-21191). La primera vez tarda varios minutos: descarga el convertidor, aplica los arreglos de este proyecto y convierte el juego.
4. Elige la configuración y pulsa **JUGAR**.

En el juego, **F1** abre el menú rápido. La versión europea trae español; la de USA solo inglés.

Todo queda en esta carpeta: el instalador crea **`engine`** con el convertidor, sus herramientas y tus juegos convertidos, partidas y configuración. Bórrala antes de compartir o subir la carpeta. Tus partidas están en `engine\games\cttr_eu\memcard.ps2` (Europa) o `engine\games\cttr_us\memcard.ps2` (USA).

**Si algo falla:** si la instalación falla al compilar, mueve la carpeta a una ruta corta sin espacios y vuelve a importar la ISO (tus partidas se conservan). Si el juego va lento, baja la **Resolución interna** o prueba la otra **API gráfica**. El registro de la instalación está en `%TEMP%\cttr-pc-install.log`.

No compartas ISOs ni el juego convertido: contienen el juego, que es de sus dueños.

Solo se aceptan reportes de errores de las **versiones oficiales** (página de [Releases](https://github.com/Miguel0827/Crash-Tag-Team-Racing-PC/releases) y RecompLauncher). Las demás ramas, como `multiplayer`, están en desarrollo y sin terminar: no reportes errores de ellas.

---

<div align="center">

### Support my work · Apoya mi trabajo 💜

This port is free and always will be. If you want to support my work as a developer, you can sponsor me on GitHub.
It's completely optional: it doesn't unlock anything and it doesn't pay for the game. You always need your own disc.

*Este port es gratis y siempre lo será. Si quieres apoyar mi trabajo como desarrollador, puedes patrocinarme en GitHub.
Es totalmente opcional: no desbloquea nada y no paga el juego. Siempre necesitas tu propio disco.*

<a href="https://github.com/sponsors/Miguel0827"><img src="https://img.shields.io/badge/Sponsor-NyxBorn-a855f7?style=for-the-badge&logo=githubsponsors&logoColor=white" alt="Sponsor NyxBorn on GitHub"></a>

</div>
