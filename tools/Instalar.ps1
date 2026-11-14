# Crash Tag Team Racing PC - installer: prepares the converter (ps2-native-recomp + this project's fixes) and turns the
# player's own disc image into the native PC program. Nothing of the game is in this project; it all comes from the ISO.
#   Instalar.ps1 -Iso "C:\path\Crash Tag Team Racing.iso" [-Root C:\PS2Native]
param([Parameter(Mandatory = $true)][string]$Iso, [string]$Root = '')
$ErrorActionPreference = 'Stop'
# any failure ends with a line the launcher shows (and no LISTO line)
trap { Write-Host ''; Write-Host "ERROR: $($_.Exception.Message)"; if ($Lock) { Remove-Item $Lock -ErrorAction SilentlyContinue }; exit 1 }
$Here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$Package = Split-Path -Parent $Here
if (-not $Root) { $Root = Join-Path $Package 'engine' }
New-Item -ItemType Directory -Force $Root | Out-Null
$short = (New-Object -ComObject Scripting.FileSystemObject).GetFolder($Root).ShortPath   # no spaces for the build tools
if ($short -and $short -notmatch ' ') { $Root = $short }
$Commit  = '5d1ebbcf133cb3c31df75a294dbe38e30734c1ce'   # the ps2-native-recomp version the fixes are made for
$Patch   = Join-Path $Package 'patches\cttr-fixes.patch'
$Marker  = Join-Path $Root '.cttr-fixes-applied'

function Step([string]$text) { Write-Host ''; Write-Host "=== $text ===" }
function PosixPath([string]$p) { $p.Replace('\', '/') }
# Runs a program. What it writes to stderr (warnings such as "vu0 ... using interpreter") is only shown: under 'Stop' Windows
# PowerShell turns every stderr line of a program into an error that ends the script. Its exit code decides (in $LASTEXITCODE).
function Run {
    $ErrorActionPreference = 'Continue'
    $exe, $rest = $args
    & $exe @rest 2>&1 | ForEach-Object { if ($_ -is [System.Management.Automation.ErrorRecord]) { Write-Host $_.Exception.Message } else { Write-Host $_ } }
}

if (-not (Test-Path $Iso)) { throw "No existe la ISO: $Iso" }
# one installation at a time: the launcher looks at this file (the process id of the installation running now)
$Lock = Join-Path $Root 'install.lock'
Set-Content -Path $Lock -Value $PID -Encoding ascii

# ---------------------------------------------------------------- 1. the converter
# The marker names the converter version and this package's fixes. Fixes from an older package (an update extracted over it)
# mean the converter's original files are fetched again over the old ones and the new fixes applied to them.
$PatchId = "$Commit " + (Get-FileHash $Patch -Algorithm SHA256).Hash.Substring(0, 16)
$applied = if (Test-Path $Marker) { ((Get-Content $Marker -Raw) -as [string]).Trim() } else { '' }
$stale = [bool]$applied -and $applied -ne $PatchId
if ($stale -or -not (Test-Path (Join-Path $Root 'scripts\port.sh'))) {   # an empty engine folder, or older fixes to replace
    Step "Descargando ps2-native-recomp ($($Commit.Substring(0, 12)))"
    $tmp = Join-Path $env:TEMP "cttr-pc-$([guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Force $tmp | Out-Null
    # this project's own copy (fork) first, the original repository if the copy cannot be reached
    $got = $false
    foreach ($owner in @('Miguel0827', 'exoteric33')) {
        try { Invoke-WebRequest -UseBasicParsing "https://github.com/$owner/ps2-native-recomp/archive/$Commit.zip" -OutFile "$tmp\src.zip"; $got = $true; break }
        catch { Write-Host "no se pudo descargar de $owner, probando el otro repositorio..." }
    }
    if (-not $got) { throw 'No se pudo descargar ps2-native-recomp (¿sin internet?).' }
    Expand-Archive "$tmp\src.zip" "$tmp\x" -Force
    New-Item -ItemType Directory -Force $Root | Out-Null
    Copy-Item "$tmp\x\ps2-native-recomp-$Commit\*" $Root -Recurse -Force
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    # what the old converter compiled: its runtime again from scratch (a newer one has other source files), and each game's build
    # set-up made again (its program and ReShade's files stay, so the game keeps showing until it is imported again)
    Get-ChildItem (Join-Path $Root 'build') -Directory -Filter 'runtime-*' -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
    Get-ChildItem (Join-Path $Root 'build') -Directory -Filter 'native-*' -ErrorAction SilentlyContinue | ForEach-Object {
        Get-ChildItem $_.FullName -Force | Where-Object { $_.Name -in 'CMakeCache.txt', 'CMakeFiles', 'build.ninja', '.ninja_deps', '.ninja_log', 'cmake_install.cmake' } | Remove-Item -Recurse -Force
    }
}
Set-Location $Root

if (-not (Test-Path (Join-Path $Root 'tools\portable\env.ps1'))) {
    Step 'Herramientas portables (compilador, cmake, python, bash)'
    Run "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'scripts\portable.ps1') -ForApp
    if ($LASTEXITCODE -ne 0) { throw "portable.ps1 falló ($LASTEXITCODE)" }
}
$isoPath = $Iso; $rootPath = $Root   # env.ps1 overwrites some variables of the caller
. (Join-Path $Root 'tools\portable\env.ps1') -Quiet
$Iso = $isoPath; $Root = $rootPath
Set-Location $Root
$bash = Join-Path $Root 'tools\portable\mingit\usr\bin\bash.exe'
$git  = (Get-ChildItem (Join-Path $Root 'tools\portable\mingit') -Recurse -Filter git.exe | Select-Object -First 1).FullName

if ($stale -or -not (Test-Path $Marker)) {
    Step 'Aplicando los arreglos de Crash Tag Team Racing PC al convertidor'
    Run $git apply --ignore-whitespace -p1 $Patch
    if ($LASTEXITCODE -ne 0) { throw 'No se pudieron aplicar los arreglos (¿otra versión de ps2-native-recomp?)' }
    Set-Content -Path $Marker -Value $PatchId -Encoding ascii
}

Step 'Compilando el convertidor (setup.sh)'
Run $bash (PosixPath (Join-Path $Root 'scripts\setup.sh')) --native-only
if ($LASTEXITCODE -ne 0) { throw "setup.sh falló ($LASTEXITCODE)" }

# ---------------------------------------------------------------- 2. which version is the disc
Step 'Reconociendo la versión del disco'
$probe = Join-Path $Root 'games\_probe'
Remove-Item $probe -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $probe | Out-Null
$fetch = & { $ErrorActionPreference = 'Continue'; & python -I (Join-Path $Root 'scripts\pnach.py') fetch (PosixPath $Iso) --out (PosixPath $probe) 2>&1 | ForEach-Object { "$_" } } | Out-String
Write-Host $fetch
$elfName = if ($fetch -match 'program:\s+([A-Z]{4}_\d{3}\.\d{2})') { $Matches[1] } else { '' }
switch -regex ($elfName) {
    '^SLES_534\.39$' { $name = 'cttr_eu'; $region = 'eu'; break }
    '^SLUS_211\.91$' { $name = 'cttr_us'; $region = 'us'; break }
    default { throw "Este disco no es una versión soportada de Crash Tag Team Racing (programa: '$elfName'). Soportadas: Europa SLES-53439, USA SLUS-21191." }
}
$pnach = Get-ChildItem $probe -Filter *.pnach | Select-Object -First 1
if (-not $pnach) { throw 'No se pudo descargar el archivo de parches de PCSX2 (¿sin internet?).' }
$patchDir = Join-Path $Root "games\patches_$region"
New-Item -ItemType Directory -Force $patchDir | Out-Null
Copy-Item $pnach.FullName $patchDir -Force
$pnachFile = Join-Path $patchDir $pnach.Name
Remove-Item $probe -Recurse -Force -ErrorAction SilentlyContinue

# the sections of the patch file: wide screen, more frames, PSP extras
$sections = Select-String -Path $pnachFile -Pattern '^\[(.+)\]\s*$' | ForEach-Object { $_.Matches[0].Groups[1].Value }
$wsSection  = $sections | Where-Object { $_ -match 'Widescreen' } | Select-Object -First 1
$fpsSection = $sections | Where-Object { $_ -match 'FPS' } | Select-Object -First 1
$pspSection = $sections | Where-Object { $_ -match 'PSP' } | Select-Object -First 1
Write-Host "versión: $region ($elfName); parches: [$wsSection] [$fpsSection] [$pspSection]"

# ---------------------------------------------------------------- 3. the port
# Each import starts clean: what an earlier import of this version left (finished, or stopped half way) goes, except the player's
# saves and settings. Without region.json the launcher does not list the version until this import has finished.
$gameDir = Join-Path $Root "games\$name"
$saved = Join-Path $env:TEMP "cttr-pc-saves-$name"
Remove-Item $saved -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path $gameDir) {
    Step "Limpiando una instalación anterior de $name (se conservan partidas y configuración)"
    New-Item -ItemType Directory -Force $saved | Out-Null
    Get-ChildItem $gameDir -Force | Where-Object { $_.Name -match '^(memcard\.ps2.*|keys\.ini|states|reports)$' } | ForEach-Object { Copy-Item $_.FullName $saved -Recurse -Force }
    Remove-Item $gameDir -Recurse -Force
}
foreach ($old in @((Join-Path $Root "build\native-$name"), (Join-Path $Root "generated\$name"))) { if (Test-Path $old) { Remove-Item $old -Recurse -Force } }
New-Item -ItemType Directory -Force $gameDir | Out-Null
if (Test-Path $saved) { Get-ChildItem $saved -Force | ForEach-Object { Copy-Item $_.FullName $gameDir -Recurse -Force }; Remove-Item $saved -Recurse -Force }
$backup = Join-Path $Root "saves-backup\$name"   # what the launcher's Delete kept
if (Test-Path $backup) { Get-ChildItem $backup -Force | ForEach-Object { Copy-Item $_.FullName $gameDir -Recurse -Force }; Remove-Item $backup -Recurse -Force }
Step "Convirtiendo el juego ($name) - tarda varios minutos"
$env:PS2_GPU_LOW_POWER = '0'   # the conversion's test runs on the fast graphics card (port.sh would pick the power-saving one)
$portArgs = @((PosixPath (Join-Path $Root 'scripts\port.sh')), $name, (PosixPath $Iso), '--native-only')
if ($wsSection) { $portArgs += @('--pnach', (PosixPath $pnachFile), '--pnach-section', $wsSection) }
Run $bash @portArgs
if ($LASTEXITCODE -ne 0) { throw "port.sh falló ($LASTEXITCODE)" }
# The game reads its disc from games\<name>\disc.iso. port.sh puts a hard link to the ISO there, which only works on the same
# drive: an ISO on another drive (or one a hard link cannot reach) is copied instead.
$discIso = Join-Path $gameDir 'disc.iso'
if (-not (Test-Path $discIso)) {
    try { New-Item -ItemType HardLink -Path $discIso -Target $Iso -ErrorAction Stop | Out-Null }
    catch { Step 'Copiando la ISO junto al juego (está en otra unidad)'; Copy-Item -LiteralPath $Iso -Destination $discIso -Force }
}

# ---------------------------------------------------------------- 4. what the launcher needs
Step 'Preparando las opciones del launcher'
$game = $gameDir
$sets = Join-Path $game 'patchsets'
New-Item -ItemType Directory -Force $sets | Out-Null
$elf = Join-Path $game "disc\$elfName"
foreach ($pair in @(@('ws', $wsSection), @('fps', $fpsSection), @('psp', $pspSection))) {
    $out = Join-Path $sets "$($pair[0]).txt"
    if (-not $pair[1]) { [IO.File]::WriteAllText($out, ''); continue }
    $tmpElf = Join-Path $sets "tmp.elf"
    Run python -I (Join-Path $Root 'scripts\pnach.py') apply (PosixPath $elf) (PosixPath $tmpElf) (PosixPath $out) --section $pair[1] (PosixPath $pnachFile)
    Remove-Item $tmpElf -ErrorAction SilentlyContinue
}
$info = [ordered]@{ name = $name; region = $region; elf = $elfName; widescreen = [bool]$wsSection
                    languages = $(if ($region -eq 'eu') { @(3, 1, 2, 4, 5, 6) } else { @(1) }) }
[IO.File]::WriteAllText((Join-Path $game 'region.json'), ($info | ConvertTo-Json), (New-Object Text.UTF8Encoding $false))
Write-Host ''
Remove-Item $Lock -ErrorAction SilentlyContinue
Write-Host "LISTO: $name instalado. Abre el juego desde el launcher."

