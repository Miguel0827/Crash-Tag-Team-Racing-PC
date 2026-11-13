# Crash Tag Team Racing PC - launcher (Windows PowerShell 5.1, WinForms). By NyxBorn.
# Imports the player's own disc image (tools\Instalar.ps1 builds the port) and starts the game with the chosen settings.
# Per game: <Root>\games\<name>\keys.ini (read by ps2run itself) and region.json (written by the installer).
#   -Play: starts the game straight away with the saved settings (the game .exe); the settings window only when nothing is installed
param([string]$Root = '', [switch]$Play)
$ErrorActionPreference = 'Stop'
# The console that runs this script is hidden here (started hidden, Windows would hide the launcher's window too).
Add-Type -Namespace Native -Name Con -MemberDefinition '[DllImport("kernel32.dll")] public static extern System.IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(System.IntPtr h, int c);'
[void][Native.Con]::ShowWindow([Native.Con]::GetConsoleWindow(), 0)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
# The game inherits this: no Windows "has stopped working" box when it crashes; the launcher explains it in its own window.
Add-Type -Namespace Native -Name Err -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetErrorMode(uint mode);'
[void][Native.Err]::SetErrorMode(0x8003)
$Version = 'v1.3.1'   # this package's release (in the footer and in error reports)
$IssuesUrl = 'https://github.com/Miguel0827/Crash-Tag-Team-Racing-PC'

$Here    = Split-Path -Parent $MyInvocation.MyCommand.Path
# the converter and the converted games live in the "engine" folder next to tools\, written without spaces (the 8.3 name)
# because some of the build tools stumble on paths like "C:\Users\First Last\Desktop\..."
if (-not $Root) {
    $Root = Join-Path (Split-Path -Parent $Here) 'engine'
    if (-not (Test-Path $Root)) { New-Item -ItemType Directory -Force $Root | Out-Null }
    $short = (New-Object -ComObject Scripting.FileSystemObject).GetFolder($Root).ShortPath
    if ($short -and $short -notmatch ' ') { $Root = $short }
}
$CfgFile = Join-Path $Root 'cttr-launcher.json'
$GameExe = Join-Path (Split-Path -Parent $Here) 'Crash Tag Team Racing PC.exe'          # the game's program, once installed
$ShortcutFile = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Crash Tag Team Racing.lnk'

# ---------------------------------------------------------------- texts
$Texts = @{
 es = @{ title='Crash Tag Team Racing - PC'; ui='Idioma del launcher y del menú F1'; ver='Versión'; game='Idioma del juego'; video='Imagen'; profile='Perfil gráfico'; scale='Resolución interna';
         look='Estilo de imagen'; vsync='Sincronización vertical'; full='Pantalla completa'; api='API gráfica';
         reshade='Mejora gráfica ReShade'; perf='Corrección de rendimiento de menús'; extras='Extras';
         fps='Doble de FPS (el juego original va a 25-30)'; psp='Desbloquear contenido de PSP (autos, arenas, cooperativo)';
         pad='Mando'; inv='Invertir stick derecho'; play='JUGAR'; import='Importar ISO...'; quit='Salir'; none='Importa tu ISO del juego para empezar';
         eu='Europa (6 idiomas)'; us='USA / Latinoamérica (inglés)'; isofilter='Imagen de disco (*.iso)|*.iso'; installing='Instalando - no cierres esta ventana';
         done='Listo. Ya puedes jugar.'; failed='La instalación falló. Revisa el registro.'; close='Cerrar'; steps=@('Descargando el convertidor','Descargando herramientas (~1 GB)','Aplicando los arreglos','Compilando el convertidor','Reconociendo el disco','Leyendo el disco','Traduciendo el código del juego','Probando el juego','Programas gráficos','Compilando el juego','Preparando opciones','Listo'); elapsed='Tiempo'; cancel='Cancelar'; cancelled='Instalación cancelada. La próxima importación empieza de cero.'; del='Eliminar'; delask='¿Eliminar esta versión?

Sí: se borra el juego convertido y se guardan tus partidas (vuelven si la importas de nuevo).
No: se borra todo, también las partidas.'; err='No se pudo iniciar la instalación:'; invs=@('No','Horizontal','Vertical','Ambos') }
 en = @{ title='Crash Tag Team Racing - PC'; ui='Launcher and F1 menu language'; ver='Version'; game='Game language'; video='Picture'; profile='Graphics profile'; scale='Internal resolution';
         look='Picture look'; vsync='Vertical sync'; full='Full screen'; api='Graphics API';
         reshade='ReShade graphics enhancement'; perf='Menu performance fix'; extras='Extras';
         fps='Double FPS (the original runs at 25-30)'; psp='Unlock PSP content (cars, arenas, co-op)';
         pad='Controller'; inv='Invert right stick'; play='PLAY'; import='Import ISO...'; quit='Quit'; none='Import your game ISO to start';
         eu='Europe (6 languages)'; us='USA / Latin America (English)'; isofilter='Disc image (*.iso)|*.iso'; installing='Installing - do not close this window';
         done='Done. You can play now.'; failed='The installation failed. See the log.'; close='Close'; steps=@('Downloading the converter','Downloading tools (~1 GB)','Applying the fixes','Building the converter','Recognising the disc','Reading the disc','Translating the game code','Test-running the game','Graphics programs','Compiling the game','Preparing options','Done'); elapsed='Time'; cancel='Cancel'; cancelled='Installation cancelled. The next import starts from scratch.'; del='Delete'; delask='Delete this version?

Yes: the converted game is removed and your saves are kept (they come back if you import it again).
No: everything is removed, saves too.'; err='The installation could not start:'; invs=@('No','Left-right','Up-down','Both') }
 fr = @{ title='Crash Tag Team Racing - PC'; ui='Langue du lanceur et du menu F1'; ver='Version'; game='Langue du jeu'; video='Image'; profile='Profil graphique'; scale='Résolution interne';
         look="Style d'image"; vsync='Synchronisation verticale'; full='Plein écran'; api='API graphique';
         reshade='Amélioration graphique ReShade'; perf='Correctif de performance des menus'; extras='Extras';
         fps="FPS doublés (l'original tourne à 25-30)"; psp='Débloquer le contenu PSP (voitures, arènes, coop)';
         pad='Manette'; inv='Inverser le stick droit'; play='JOUER'; import='Importer un ISO...'; quit='Quitter'; none='Importez votre ISO du jeu pour commencer';
         eu='Europe (6 langues)'; us='USA / Amérique latine (anglais)'; isofilter='Image disque (*.iso)|*.iso'; installing='Installation - ne fermez pas cette fenêtre';
         done='Terminé. Vous pouvez jouer.'; failed="L'installation a échoué. Voir le journal."; close='Fermer'; steps=@('Téléchargement du convertisseur','Téléchargement des outils (~1 Go)','Application des correctifs','Compilation du convertisseur','Reconnaissance du disque','Lecture du disque','Traduction du code du jeu','Test du jeu','Programmes graphiques','Compilation du jeu','Préparation des options','Terminé'); elapsed='Temps'; cancel='Annuler'; cancelled="Installation annulée. La prochaine importation repart de zéro."; del='Supprimer'; delask="Supprimer cette version ?

Oui : le jeu converti est effacé et vos sauvegardes sont gardées.
Non : tout est effacé, sauvegardes comprises."; err="Impossible de lancer l'installation :"; invs=@('Non','Horizontal','Vertical','Les deux') }
 de = @{ title='Crash Tag Team Racing - PC'; ui='Sprache von Launcher und F1-Menü'; ver='Version'; game='Spielsprache'; video='Bild'; profile='Grafikprofil'; scale='Interne Auflösung';
         look='Bildstil'; vsync='Vertikale Synchronisation'; full='Vollbild'; api='Grafik-API';
         reshade='ReShade-Grafikverbesserung'; perf='Leistungskorrektur für Menüs'; extras='Extras';
         fps='Doppelte FPS (das Original läuft mit 25-30)'; psp='PSP-Inhalte freischalten (Autos, Arenen, Koop)';
         pad='Controller'; inv='Rechten Stick umkehren'; play='SPIELEN'; import='ISO importieren...'; quit='Beenden'; none='Importiere deine Spiel-ISO, um zu beginnen';
         eu='Europa (6 Sprachen)'; us='USA / Lateinamerika (Englisch)'; isofilter='Disc-Abbild (*.iso)|*.iso'; installing='Installation - Fenster nicht schließen';
         done='Fertig. Du kannst spielen.'; failed='Die Installation ist fehlgeschlagen. Siehe Protokoll.'; close='Schließen'; steps=@('Konverter wird geladen','Werkzeuge werden geladen (~1 GB)','Korrekturen werden angewendet','Konverter wird gebaut','Disc wird erkannt','Disc wird gelesen','Spielcode wird übersetzt','Spiel wird getestet','Grafikprogramme','Spiel wird kompiliert','Optionen werden vorbereitet','Fertig'); elapsed='Zeit'; cancel='Abbrechen'; cancelled='Installation abgebrochen. Der nächste Import beginnt von vorn.'; del='Löschen'; delask='Diese Version löschen?

Ja: das konvertierte Spiel wird entfernt, deine Spielstände bleiben erhalten.
Nein: alles wird gelöscht, auch die Spielstände.'; err='Die Installation konnte nicht starten:'; invs=@('Nein','Horizontal','Vertikal','Beide') }
 it = @{ title='Crash Tag Team Racing - PC'; ui='Lingua del launcher e del menu F1'; ver='Versione'; game='Lingua del gioco'; video='Immagine'; profile='Profilo grafico'; scale='Risoluzione interna';
         look="Stile dell'immagine"; vsync='Sincronizzazione verticale'; full='Schermo intero'; api='API grafica';
         reshade='Miglioramento grafico ReShade'; perf='Correzione prestazioni dei menu'; extras='Extra';
         fps="FPS raddoppiati (l'originale va a 25-30)"; psp='Sblocca contenuti PSP (auto, arene, cooperativa)';
         pad='Controller'; inv='Inverti stick destro'; play='GIOCA'; import='Importa ISO...'; quit='Esci'; none='Importa la tua ISO del gioco per iniziare';
         eu='Europa (6 lingue)'; us='USA / America Latina (inglese)'; isofilter='Immagine disco (*.iso)|*.iso'; installing='Installazione - non chiudere questa finestra';
         done='Fatto. Puoi giocare.'; failed="L'installazione non è riuscita. Vedi il registro."; close='Chiudi'; steps=@('Download del convertitore','Download degli strumenti (~1 GB)','Applicazione delle correzioni','Compilazione del convertitore','Riconoscimento del disco','Lettura del disco','Traduzione del codice del gioco','Prova del gioco','Programmi grafici','Compilazione del gioco','Preparazione delle opzioni','Fatto'); elapsed='Tempo'; cancel='Annulla'; cancelled="Installazione annullata. La prossima importazione riparte da zero."; del='Elimina'; delask="Eliminare questa versione?

Sì: il gioco convertito viene rimosso e i salvataggi restano.
No: viene rimosso tutto, anche i salvataggi."; err="Impossibile avviare l'installazione:"; invs=@('No','Orizzontale','Verticale','Entrambi') }
 pt = @{ title='Crash Tag Team Racing - PC'; ui='Idioma do launcher e do menu F1'; ver='Versão'; game='Idioma do jogo'; video='Imagem'; profile='Perfil gráfico'; scale='Resolução interna';
         look='Estilo de imagem'; vsync='Sincronização vertical'; full='Tela cheia'; api='API gráfica';
         reshade='Melhoria gráfica ReShade'; perf='Correção de desempenho dos menus'; extras='Extras';
         fps='FPS em dobro (o original roda a 25-30)'; psp='Desbloquear conteúdo do PSP (carros, arenas, cooperativo)';
         pad='Controle'; inv='Inverter analógico direito'; play='JOGAR'; import='Importar ISO...'; quit='Sair'; none='Importe a ISO do seu jogo para começar';
         eu='Europa (6 idiomas)'; us='EUA / América Latina (inglês)'; isofilter='Imagem de disco (*.iso)|*.iso'; installing='Instalando - não feche esta janela';
         done='Pronto. Já pode jogar.'; failed='A instalação falhou. Veja o registro.'; close='Fechar'; steps=@('Baixando o conversor','Baixando ferramentas (~1 GB)','Aplicando as correções','Compilando o conversor','Reconhecendo o disco','Lendo o disco','Traduzindo o código do jogo','Testando o jogo','Programas gráficos','Compilando o jogo','Preparando opções','Pronto'); elapsed='Tempo'; cancel='Cancelar'; cancelled='Instalação cancelada. A próxima importação começa do zero.'; del='Excluir'; delask='Excluir esta versão?

Sim: o jogo convertido é apagado e seus saves ficam guardados.
Não: tudo é apagado, inclusive os saves.'; err='Não foi possível iniciar a instalação:'; invs=@('Não','Horizontal','Vertical','Ambos') }
}
# the shortcut button at the end of an installation, and the question before importing a disc
$Extra = @{
 es = @{ sc='Crear acceso directo en el escritorio'; scdone='Acceso directo creado'; owntitle='Recuerda'
         own="Necesitas tu propio disco original del juego."; ok='Entendido'; no='Cancelar' }
 en = @{ sc='Create a desktop shortcut'; scdone='Shortcut created'; owntitle='Remember'
         own="You need your own original disc of the game."; ok='Got it'; no='Cancel' }
 fr = @{ sc='Créer un raccourci sur le bureau'; scdone='Raccourci créé'; owntitle='Rappel'
         own="Il vous faut votre propre disque original du jeu."; ok='Compris'; no='Annuler' }
 de = @{ sc='Desktop-Verknüpfung erstellen'; scdone='Verknüpfung erstellt'; owntitle='Denk daran'
         own="Du brauchst deine eigene Original-Disc des Spiels."; ok='Verstanden'; no='Abbrechen' }
 it = @{ sc='Crea un collegamento sul desktop'; scdone='Collegamento creato'; owntitle='Ricorda'
         own="Ti serve il tuo disco originale del gioco."; ok='Ho capito'; no='Annulla' }
 pt = @{ sc='Criar atalho na área de trabalho'; scdone='Atalho criado'; owntitle='Lembre-se'
         own="Você precisa do seu próprio disco original do jogo."; ok='Entendi'; no='Cancelar' }
}
# colours of NyxBorn's GitHub profile: GitHub's dark background, the purple gradient and its lilac accents
function Rgb([string]$hex) { [Drawing.Color]::FromArgb([Convert]::ToInt32($hex.Substring(0, 2), 16), [Convert]::ToInt32($hex.Substring(2, 2), 16), [Convert]::ToInt32($hex.Substring(4, 2), 16)) }
$Theme = @{ bg = (Rgb '0D1117'); panel = (Rgb '161B22'); line = (Rgb '30363D'); deep = (Rgb '2E1065'); purple = (Rgb 'A855F7')
            hover = (Rgb '9333EA'); lilac = (Rgb 'C084FC'); pale = (Rgb 'E9D5FF'); muted = (Rgb '8B949E'); red = (Rgb 'F87171') }
$UiLangs   = @(@('es','Español'), @('en','English'), @('fr','Français'), @('de','Deutsch'), @('it','Italiano'), @('pt','Português'))
$LangNames = @{ 1='English'; 2='Français'; 3='Español'; 4='Deutsch'; 5='Italiano'; 6='Nederlands' }   # the PS2's system language numbers
$Looks     = @(@('sharp_edges','Sharp + smooth edges'), @('sharp','Sharp'), @('crisp_edges','Crisp + smooth edges'), @('crisp','Crisp'), @('soft_edges','Soft + smooth edges'), @('soft','Soft'))
$InvWords  = @('off','x','y','both')

# ---------------------------------------------------------------- installed games and settings
function Get-Games {
    $list = @()
    $dir = Join-Path $Root 'games'
    if (Test-Path $dir) {
        foreach ($f in Get-ChildItem $dir -Directory) {
            $r = Join-Path $f.FullName 'region.json'
            $exe = Join-Path $Root "build\native-$($f.Name)\ps2run.exe"
            if ((Test-Path $r) -and (Test-Path $exe)) { try { $list += (Get-Content $r -Raw | ConvertFrom-Json) } catch {} }
        }
    }
    , $list
}
function Read-Ini([string]$path) {
    $map = @{}
    if (Test-Path $path) { foreach ($line in [IO.File]::ReadAllLines($path)) { if ($line -match '^\s*([A-Za-z_ ]+?)\s*=\s*(.*?)\s*$') { $map[($Matches[1] -replace '[ _]', '').ToLower()] = $Matches[2] } } }
    $map
}
function Set-IniLines([string]$path, [hashtable]$values) {
    $lines = New-Object System.Collections.Generic.List[string]
    if (Test-Path $path) { [IO.File]::ReadAllLines($path) | ForEach-Object { $lines.Add($_) } }
    foreach ($name in $values.Keys) {
        $key = ($name -replace '[ _]', '').ToLower(); $done = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\s*([A-Za-z_ ]+?)\s*=' -and (($Matches[1] -replace '[ _]', '').ToLower() -eq $key)) { $lines[$i] = "$name = $($values[$name])"; $done = $true; break }
        }
        if (-not $done) { $lines.Add("$name = $($values[$name])") }
    }
    [IO.File]::WriteAllText($path, (($lines -join "`n") + "`n"), (New-Object Text.UTF8Encoding $false))
}
$cfg = [ordered]@{ ui = 'es'; version = ''; game = 3; api = 'vulkan'; reshade = $true; perf = $true; fps = $false; psp = $false; full = $false }
if (Test-Path $CfgFile) { try { $j = Get-Content $CfgFile -Raw | ConvertFrom-Json; foreach ($p in $j.PSObject.Properties) { $cfg[$p.Name] = $p.Value } } catch {} }
$Games = Get-Games

# ---------------------------------------------------------------- this PC
# Its graphics card (the one with the most video memory, a separate card before one built into the processor), processor threads,
# memory and Windows: for the settings of a first start and for error reports. Video memory comes from the display drivers'
# registry keys (Win32_VideoController stops at 4 GB).
function Get-PcInfo {
    $i = [ordered]@{ tier = 'mid'; gpu = ''; vram = 0.0; integrated = $false; intel = $false; cores = [Environment]::ProcessorCount; ram = 0.0; cpu = ''; os = ''; gpus = @() }
    try { $i.ram = [Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1) } catch {}
    try { $i.cpu = ([string](Get-CimInstance Win32_Processor | Select-Object -First 1).Name).Trim() } catch {}
    try { $o = Get-CimInstance Win32_OperatingSystem; $i.os = "$($o.Caption) ($($o.Version))" } catch {}
    $mem = @{}
    try {
        Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction Stop | ForEach-Object {
            try {
                $p = Get-ItemProperty $_.PSPath -ErrorAction Stop
                $q = $p.'HardwareInformation.qwMemorySize'
                if (-not $q) { $q = $p.'HardwareInformation.MemorySize'; if ($q -is [byte[]]) { $q = [BitConverter]::ToUInt32($q, 0) } }
                if ($p.DriverDesc -and $q) { $mem[[string]$p.DriverDesc] = [double]$q }
            } catch {}
        }
    } catch {}
    $best = $null; $bestScore = -1.0
    try {
        foreach ($v in @(Get-CimInstance Win32_VideoController)) {
            $name = [string]$v.Name
            if (-not $name -or $name -match 'Basic Display|Basic Render|Remote|Virtual|Parsec|Meta Virtual|Mirage') { continue }
            $vram = if ($mem.ContainsKey($name)) { $mem[$name] } else { [double]$v.AdapterRAM }
            $integ = ($name -match 'Intel') -or ($name -match 'Radeon\(TM\) Graphics|Radeon Graphics|Vega \d+ Graphics|Radeon \d+M Graphics')
            $i.gpus += "$name (driver $($v.DriverVersion), $([Math]::Round($vram / 1GB, 1)) GB)"
            $score = $vram + $(if ($integ) { 0 } else { 64GB })
            if ($score -gt $bestScore) { $bestScore = $score; $best = @{ name = $name; vram = $vram; integ = $integ } }
        }
    } catch {}
    if ($best) { $i.gpu = $best.name; $i.vram = [Math]::Round($best.vram / 1GB, 1); $i.integrated = $best.integ; $i.intel = $best.name -match 'Intel' }
    # modest: a graphics chip in the processor, a small card, few threads or little memory; powerful: a card with 6 GB or more
    if ($i.integrated -or $i.vram -lt 3 -or $i.cores -lt 4 -or ($i.ram -gt 0 -and $i.ram -lt 7.5)) { $i.tier = 'low' }
    elseif ($i.vram -ge 6 -and $i.cores -ge 6 -and $i.ram -ge 14) { $i.tier = 'high' }
    $i
}
$PcInfo = Get-PcInfo
# per kind of PC: the inner resolution, and the plainest picture (no edge smoothing pass) on a modest one
$ProfileScale = @{ low = 1; mid = 2; high = 4 }   # the inner resolution of each graphics profile
$DefaultScale = $ProfileScale[$PcInfo.tier]
$DefaultLook = $(if ($PcInfo.tier -eq 'low') { 1 } else { 0 })
# A first start (no saved settings yet): full screen, the language of Windows for the launcher, the F1 menu and the game, and
# Direct3D 12 on an Intel graphics chip (their Vulkan drivers are the less reliable ones).
$FirstRun = -not (Test-Path $CfgFile)
if ($FirstRun) {
    $cul = (Get-UICulture).TwoLetterISOLanguageName
    $cfg.ui = $(if (@($UiLangs | ForEach-Object { $_[0] }) -contains $cul) { $cul } else { 'en' })
    $cfg.game = $(switch ($cul) { 'es' { 3 } 'fr' { 2 } 'de' { 4 } 'it' { 5 } 'nl' { 6 } default { 1 } })
    $cfg.full = $true
    $cfg.profile = $PcInfo.tier
    if ($PcInfo.intel -and $PcInfo.integrated) { $cfg.api = 'dx12' }
    $cfg.fps = $PcInfo.tier -ne 'low'   # 50/60 FPS on a medium or powerful PC (it doubles the game's work)
}
function Save-Cfg { [IO.File]::WriteAllText($CfgFile, ($cfg | ConvertTo-Json), (New-Object Text.UTF8Encoding $false)) }

# Starts game $g with the saved settings ($cfg and its keys.ini): the Play button after saving them, and -Play on its own
function Start-Game($g) {
    $gameDir = Join-Path $Root "games\$($g.name)"
    $keys = Join-Path $gameDir 'keys.ini'; $have = Read-Ini $keys; $add = @{}
    if (-not $have.scale) { $add.scale = $DefaultScale }
    if (-not $have.look) { $add.look = $Looks[$DefaultLook][0] }
    if ($add.Count) { Set-IniLines $keys $add }
    Set-IniLines (Join-Path $gameDir 'keys.ini') @{ right_invert = 'x' }   # the right stick's left-right is the wrong way round in this game without it
    # the patches of this run: wide screen always (it is in the converted program), the others as chosen and when the disc has them
    $sets = Join-Path $gameDir 'patchsets'
    $parts = @('ws.txt'); if ($cfg.fps) { $parts += 'fps.txt' }; if ($cfg.psp) { $parts += 'psp.txt' }
    $text = ($parts | ForEach-Object { $f = Join-Path $sets $_; if (Test-Path $f) { [IO.File]::ReadAllText($f).TrimEnd() } } | Where-Object { $_ }) -join "`n"
    [IO.File]::WriteAllText((Join-Path $gameDir 'patches_run.txt'), $text + "`n", (New-Object Text.UTF8Encoding $false))
    $elf = "games/$($g.name)/patched/$($g.elf)"; if (-not (Test-Path (Join-Path $Root $elf))) { $elf = "games/$($g.name)/disc/$($g.elf)" }
    $argv = @($elf, '--disc', "games/$($g.name)/disc.iso", '--window', '--game-dir', "games/$($g.name)", '--memcard', "games/$($g.name)/memcard.ps2", '--patches', "games/$($g.name)/patches_run.txt")
    if ($g.widescreen) { $argv += '--widescreen' }
    if ($cfg.full) { $argv += '--fullscreen' }
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = Join-Path $Root "build\native-$($g.name)\ps2run.exe"; $psi.WorkingDirectory = $Root; $psi.UseShellExecute = $false
    $psi.Arguments = ($argv | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
    $ev = $psi.EnvironmentVariables
    $ev['PS2_LANGUAGE'] = [string]$cfg.game
    $ev['PS2_MENU_LANG'] = $cfg.ui
    $ev['PS2_GPU_BACKEND'] = $cfg.api
    if ($cfg.api -ne 'vulkan' -or -not $cfg.reshade) { $ev['DISABLE_VK_LAYER_reshade_1'] = '1' }
    $ev['PS2_DMA_TIME'] = '120,16'   # the title and menus: GIF transfers take the console's time (always on)
    $icon = Join-Path $Here 'starter\icon.bmp'; if (Test-Path $icon) { $ev['PS2_WINDOW_ICON'] = $icon }   # the Wumpa on the game's window
    $script:GameStarted = Get-Date
    [Diagnostics.Process]::Start($psi)
}
# "Partidas" next to the programs: a link per installed version to the folder that holds its saves (memory card, quick saves, backups),
# and a note on which file is which. A link (junction) needs no administrator; deleting it leaves the saves where they are.
function Update-SavesFolder {
    try {
        $dir = Join-Path (Split-Path -Parent $Here) 'Partidas'
        New-Item -ItemType Directory -Force $dir | Out-Null
        foreach ($g in $Games) {
            $link = Join-Path $dir $(if ($g.region -eq 'eu') { 'Europa' } else { 'USA' })
            $target = (Get-Item (Join-Path $Root "games\$($g.name)")).FullName
            if (-not (Test-Path $link)) { [void](cmd /c mklink /J "`"$link`"" "`"$target`"") }
        }
        $note = Join-Path $dir 'LEEME - README.txt'
        if (-not (Test-Path $note)) {
            [IO.File]::WriteAllText($note, @"
Tus partidas de Crash Tag Team Racing PC (una carpeta por versión: Europa / USA)

  memcard.ps2        la tarjeta de memoria: tus partidas del juego. Copia este archivo para tener una copia de seguridad.
  states\quick_*     los guardados rápidos (F5 guarda, F8 carga)
  memcard.backups\   copias de seguridad automáticas de la tarjeta

Cierra el juego antes de copiar o reemplazar estos archivos.

Your Crash Tag Team Racing PC saves (one folder per version: Europa = Europe / USA)

  memcard.ps2        the memory card: your game saves. Copy this file to back them up.
  states\quick_*     quick saves (F5 saves, F8 loads)
  memcard.backups\   automatic backups of the card

Close the game before copying or replacing these files.
"@, (New-Object Text.UTF8Encoding $true))
        }
    } catch {}
}
# The game's own program (straight into the game) appears next to the Config one only once a version is installed, and goes
# when none is left; it is kept in tools\starter\game.exe until then.
function Update-GameExe {
    try {
        $kept = Join-Path $Here 'starter\game.exe'
        if ($Games.Count -gt 0) {
            if ((Test-Path $kept) -and -not (Test-Path $GameExe)) { Copy-Item $kept $GameExe }
        } elseif (Test-Path $GameExe) {
            Remove-Item $GameExe -Force
            if (Test-Path $ShortcutFile) { Remove-Item $ShortcutFile -Force }
        }
    } catch {}
}
# ---------------------------------------------------------------- when the game closes with an error
$CrashTexts = @{
 es = @{ title = 'Lo sentimos'; head = 'El juego se cerró por un error'; body = "No es culpa tuya. Este informe dice qué pasó y en qué PC: envíalo y lo arreglo en la próxima versión."
         copy = 'Copiar informe'; send = 'Reportar en GitHub'; safe = 'Probar ajustes seguros'; close = 'Cerrar'; copied = 'Copiado'; saved = 'Informe guardado en:'
         safedone = 'Resolución 1x, imagen simple y la otra API gráfica: el juego se abre otra vez con estos ajustes.' }
 en = @{ title = 'Sorry'; head = 'The game closed because of an error'; body = "It is not your fault. This report says what happened and on what PC: send it and I will fix it in the next version."
         copy = 'Copy report'; send = 'Report on GitHub'; safe = 'Try safe settings'; close = 'Close'; copied = 'Copied'; saved = 'Report saved to:'
         safedone = 'Resolution 1x, the plain picture and the other graphics API: the game starts again with these settings.' }
}
# (its own button style: the window can open before the settings window's functions are defined, from the game .exe)
function Crash-Button($b, [bool]$main) {
    $b.FlatStyle = 'Flat'; $b.Cursor = [Windows.Forms.Cursors]::Hand
    if ($main) { $b.BackColor = $Theme.purple; $b.ForeColor = [Drawing.Color]::White; $b.FlatAppearance.BorderSize = 0 }
    else { $b.BackColor = $Theme.panel; $b.ForeColor = $Theme.pale; $b.FlatAppearance.BorderColor = $Theme.line }
}
function Crash-Text { $k = $(if ($cfg.ui -eq 'es') { 'es' } else { 'en' }); $CrashTexts[$k] }
$ExitMeaning = @{ 0xC0000005 = 'access violation'; 0xC0000409 = 'fail-fast / stack buffer overrun (often an uncaught C++ exception)'; 0x20474343 = 'uncaught C++ exception'
                  0xE06D7363 = 'uncaught C++ exception'; 0xC0000135 = 'a DLL is missing'; 0xC000001D = 'illegal instruction (processor too old?)'; 0xC00000FD = 'stack overflow'; 3 = 'abort()' }
# Waits for the game. A crash (exit code not 0), or a log that ends in anything but a window closed or Quit from the F1 menu (or no
# end at all), opens the report window.
function Watch-Game($p, $g) {
    if (-not $p) { return }
    $p.WaitForExit()
    $code = $p.ExitCode
    $logDir = Join-Path $Root "games\$($g.name)\logs"
    $log = Get-ChildItem $logDir -Filter 'ps2run_*.log' -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -ge $script:GameStarted.AddSeconds(-5) } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $lines = @(); if ($log) { try { $lines = @(Get-Content $log.FullName -ErrorAction Stop) } catch {} }
    $stop = ($lines | Where-Object { $_ -match '^\[ee\] stopped after' } | Select-Object -Last 1)
    $reason = if ($stop -match ':\s*(.+)$') { $Matches[1] } else { '' }
    if ($code -eq 0 -and ($reason -match 'window closed|quit from the quick menu' -or -not $log)) { return }
    Show-CrashReport $g $code $reason $lines $log
}
function Show-CrashReport($g, [int]$code, [string]$reason, $lines, $log) {
    $x = Crash-Text
    $hex = '0x{0:X8}' -f $code
    $meaning = if ($ExitMeaning.ContainsKey($code)) { $ExitMeaning[$code] } elseif ($code -eq 0) { 'the game stopped itself' } else { 'unknown' }
    $ini = Read-Ini (Join-Path $Root "games\$($g.name)\keys.ini")
    $tail = @($lines | Where-Object { $_ -notmatch '^\[(fileio|cdvdfsv|iop-io)\]|^\[iop\] (thread|module)' } | Select-Object -Last 40)
    # the graphics card the game ran on, and the error message itself (above the part the last lines show)
    $gpuUsed = @($lines | Where-Object { $_ -match '^\[gpu\] .+ on (Vulkan|Direct3D)' } | Select-Object -First 1 | ForEach-Object { $_ -replace '^\[gpu\]\s*', '' })
    $errs = @(); for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match 'panicked at|^Error in wgpu|[Dd]evice (is )?lost|DXGI_ERROR|VK_ERROR_') {
            $errs += $lines[$i].Trim()
            if ($lines[$i] -match 'panicked at' -and $i + 1 -lt $lines.Count) { $errs += $lines[$i + 1].Trim() }
        }
    }
    $errs = @($errs | Where-Object { $_ } | Select-Object -Unique | Select-Object -First 6)
    $report = @(
        "$($x.head) - $(($Texts['en']).title) $Version", '',
        "Game: $($g.name) ($($g.elf), $($g.region))",
        "Exit code: $hex ($meaning)",
        "Stopped: $(if ($reason) { $reason } else { 'no end line in the log' })",
        "Settings: scale $($ini.scale), look $($ini.look), vsync $($ini.vsync), API $($cfg.api), full screen $($cfg.full)",
        "PC: $($PcInfo.os); $($PcInfo.cpu) ($($PcInfo.cores) threads); $($PcInfo.ram) GB RAM; kind $($PcInfo.tier)",
        "Graphics: $($PcInfo.gpus -join '; ')",
        "GPU used: $(if ($gpuUsed) { $gpuUsed[0] } else { 'not in the log' })",
        "Error: $(if ($errs) { $errs -join ' / ' } else { 'no error message in the log' })",
        "Log: $(if ($log) { $log.FullName } else { 'none' })", '',
        '--- last lines of the log ---') + $tail
    $text = $report -join "`r`n"
    # a copy next to the programs, to attach to a report
    $saved = ''
    try {
        $dir = Join-Path (Split-Path -Parent $Here) 'Informes de error'
        New-Item -ItemType Directory -Force $dir | Out-Null
        $saved = Join-Path $dir ("error-{0:yyyy-MM-dd_HH-mm-ss}.txt" -f (Get-Date))
        [IO.File]::WriteAllText($saved, $text, (New-Object Text.UTF8Encoding $true))
    } catch { $saved = '' }

    $d = New-Object Windows.Forms.Form; $d.Text = $x.title; $d.StartPosition = 'CenterScreen'; $d.FormBorderStyle = 'FixedDialog'; $d.TopMost = $true
    $d.MaximizeBox = $false; $d.MinimizeBox = $false; $d.BackColor = $Theme.bg; $d.Font = New-Object Drawing.Font('Segoe UI', 10); $d.ClientSize = New-Object Drawing.Size(620, 470)
    $ico = Join-Path $Here 'starter\icon.ico'; if (Test-Path $ico) { try { $d.Icon = New-Object Drawing.Icon $ico } catch {} }
    $band = New-Object Windows.Forms.PictureBox; $band.SetBounds(0, 0, 620, 8)
    $bb = New-Object Drawing.Bitmap 620, 8; $bg = [Drawing.Graphics]::FromImage($bb)
    for ($i = 0; $i -lt 620; $i += 8) { $k = [Math]::Floor($i * 8 / 620) / 8; $c = [Drawing.Color]::FromArgb([int]($Theme.deep.R + ($Theme.purple.R - $Theme.deep.R) * $k), [int]($Theme.deep.G + ($Theme.purple.G - $Theme.deep.G) * $k), [int]($Theme.deep.B + ($Theme.purple.B - $Theme.deep.B) * $k)); $bg.FillRectangle((New-Object Drawing.SolidBrush $c), $i, 0, 8, 8) }
    $bg.Dispose(); $band.Image = $bb; $d.Controls.Add($band)
    $h = New-Object Windows.Forms.Label; $h.Text = $x.head; $h.SetBounds(20, 20, 580, 28); $h.Font = New-Object Drawing.Font('Segoe UI Semibold', 13); $h.ForeColor = $Theme.lilac; $d.Controls.Add($h)
    $b = New-Object Windows.Forms.Label; $b.Text = $x.body; $b.SetBounds(20, 52, 580, 44); $b.ForeColor = $Theme.pale; $d.Controls.Add($b)
    $box = New-Object Windows.Forms.TextBox; $box.Multiline = $true; $box.ReadOnly = $true; $box.ScrollBars = 'Both'; $box.WordWrap = $false
    $box.SetBounds(20, 100, 580, 270); $box.BackColor = $Theme.panel; $box.ForeColor = $Theme.pale; $box.BorderStyle = 'FixedSingle'; $box.Font = New-Object Drawing.Font('Consolas', 8.5); $box.Text = $text; $d.Controls.Add($box)
    $sv = New-Object Windows.Forms.Label; $sv.SetBounds(20, 372, 580, 34); $sv.ForeColor = $Theme.muted; $sv.Font = New-Object Drawing.Font('Segoe UI', 8.5)
    if ($saved) { $sv.Text = "$($x.saved) $saved" }; $d.Controls.Add($sv)
    $bCopy = New-Object Windows.Forms.Button; $bCopy.Text = $x.copy; $bCopy.SetBounds(20, 410, 130, 36); Crash-Button $bCopy $false; $d.Controls.Add($bCopy)
    $bSend = New-Object Windows.Forms.Button; $bSend.Text = $x.send; $bSend.SetBounds(158, 410, 160, 36); Crash-Button $bSend $true; $d.Controls.Add($bSend)
    $bSafe = New-Object Windows.Forms.Button; $bSafe.Text = $x.safe; $bSafe.SetBounds(326, 410, 170, 36); Crash-Button $bSafe $false; $d.Controls.Add($bSafe)
    $bClose = New-Object Windows.Forms.Button; $bClose.Text = $x.close; $bClose.SetBounds(504, 410, 96, 36); Crash-Button $bClose $false; $bClose.ForeColor = $Theme.muted; $d.Controls.Add($bClose)
    $bCopy.Add_Click({ [Windows.Forms.Clipboard]::SetText($text); $bCopy.Text = (Crash-Text).copied })
    $bSend.Add_Click({
        # GitHub's new issue page with the report filled in (the log's last lines cut to keep the address short; the saved file has them all)
        $body = ($report | Select-Object -First 14) -join "`n"
        $fence = ([string][char]96) * 3
        $body += "`n`n" + $fence + "`n" + (($tail | Select-Object -Last 25) -join "`n") + "`n" + $fence + "`n"
        $url = "$IssuesUrl/issues/new?title=" + [Uri]::EscapeDataString("Game closed with an error ($hex)") + '&body=' + [Uri]::EscapeDataString($body)
        if ($url.Length -gt 7500) { $url = $url.Substring(0, 7500) }
        Start-Process $url
    })
    $script:retrySafe = $false
    $bSafe.Add_Click({
        $keysFile = Join-Path $Root "games\$($g.name)\keys.ini"
        Set-IniLines $keysFile @{ scale = 1; look = 'sharp' }
        $cfg.api = $(if ($cfg.api -eq 'vulkan') { 'dx12' } else { 'vulkan' }); Save-Cfg
        [void][Windows.Forms.MessageBox]::Show((Crash-Text).safedone, (Crash-Text).title, 'OK', 'Information')
        $script:retrySafe = $true; $d.Close()
    })
    $bClose.Add_Click({ $d.Close() })
    $d.Add_Shown({ $box.SelectionStart = 0; $box.SelectionLength = 0; $bSend.Focus() })
    [void]$d.ShowDialog(); $d.Dispose()
    if ($script:retrySafe) { $p2 = Start-Game $g; Watch-Game $p2 $g }
}
Update-SavesFolder
Update-GameExe
if ($Play -and $Games.Count -gt 0) {
    $g = @($Games | Where-Object { $_.name -eq [string]$cfg.version })[0]
    if (-not $g) { $g = $Games[0] }
    if ($FirstRun) { Save-Cfg }
    $p = Start-Game $g
    Watch-Game $p $g
    exit 0
}

# the game's shortcut on the desktop (the button at the end of an installation)
function Make-Shortcut {
    $s = (New-Object -ComObject WScript.Shell).CreateShortcut($ShortcutFile)
    $s.TargetPath = $GameExe; $s.WorkingDirectory = Split-Path -Parent $GameExe; $s.IconLocation = "$GameExe,0"; $s.Save()
}
function Extra { $Extra[$UiLangs[[Math]::Max(0, $cUi.SelectedIndex)][0]] }
# a flat button in the profile's colours: the main one purple, the others outlined
function Style-Button($b, [bool]$main) {
    $b.FlatStyle = 'Flat'; $b.Cursor = [Windows.Forms.Cursors]::Hand
    if ($main) { $b.BackColor = $Theme.purple; $b.ForeColor = [Drawing.Color]::White; $b.FlatAppearance.BorderSize = 0; $b.FlatAppearance.MouseOverBackColor = $Theme.hover; $b.FlatAppearance.MouseDownBackColor = $Theme.deep }
    else { $b.BackColor = $Theme.panel; $b.ForeColor = $Theme.pale; $b.FlatAppearance.BorderColor = $Theme.line; $b.FlatAppearance.MouseOverBackColor = $Theme.line }
}

# ---------------------------------------------------------------- window
$form = New-Object Windows.Forms.Form
$form.StartPosition = 'CenterScreen'; $form.FormBorderStyle = 'FixedDialog'; $form.MaximizeBox = $false
$form.BackColor = $Theme.bg; $form.ForeColor = [Drawing.Color]::White; $form.Font = New-Object Drawing.Font('Segoe UI', 10)

# text drawn small without smoothing and blown up 1:N, so it comes out as pixels
function Draw-PixelText($g, [string]$text, [string]$family, [float]$size, [int]$n, $color, [int]$cx, [int]$y, $shadow, [int]$maxW = 0) {
    # the biggest size up to $size whose pixels fit in $maxW (the window width less a margin)
    $tmp = New-Object Drawing.Bitmap 1, 1; $tg = [Drawing.Graphics]::FromImage($tmp)
    while ($true) {
        $f = New-Object Drawing.Font($family, $size, [Drawing.FontStyle]::Bold, [Drawing.GraphicsUnit]::Pixel)
        $sz = $tg.MeasureString($text, $f)
        if ($maxW -le 0 -or ($sz.Width + 2) * $n -le $maxW -or $size -le 6) { break }
        $f.Dispose(); $size -= 0.5
    }
    $tg.Dispose(); $tmp.Dispose()
    $w = [int][Math]::Ceiling($sz.Width) + 2; $h = [int][Math]::Ceiling($sz.Height) + 2
    $bmp = New-Object Drawing.Bitmap $w, $h; $bg = [Drawing.Graphics]::FromImage($bmp)
    $bg.TextRenderingHint = [Drawing.Text.TextRenderingHint]::SingleBitPerPixelGridFit
    $bg.DrawString($text, $f, (New-Object Drawing.SolidBrush $color), 1, 1); $bg.Dispose()
    $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor; $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
    $x = $cx - [int]($w * $n / 2)
    if ($shadow) {   # the same letters in the dark purple, one pixel down and right
        $sh = New-Object Drawing.Bitmap $w, $h; $sg = [Drawing.Graphics]::FromImage($sh); $sg.TextRenderingHint = [Drawing.Text.TextRenderingHint]::SingleBitPerPixelGridFit
        $sg.DrawString($text, $f, (New-Object Drawing.SolidBrush $shadow), 1, 1); $sg.Dispose()
        $g.DrawImage($sh, (New-Object Drawing.Rectangle ($x + $n), ($y + $n), ($w * $n), ($h * $n))); $sh.Dispose()
    }
    $g.DrawImage($bmp, (New-Object Drawing.Rectangle $x, $y, ($w * $n), ($h * $n))); $bmp.Dispose(); $f.Dispose()
}
function Mix($a, $b, [double]$t) { [Drawing.Color]::FromArgb([int]($a.R + ($b.R - $a.R) * $t), [int]($a.G + ($b.G - $a.G) * $t), [int]($a.B + ($b.B - $a.B) * $t)) }
# the header: a pixel-art night in the profile's purples (sky in bands, stars, moon, hills and the track), with the title on it
function New-Header([int]$W, [int]$H) {
    $bmp = New-Object Drawing.Bitmap $W, $H; $g = [Drawing.Graphics]::FromImage($bmp)
    $px = 4
    $bands = [int]($H / $px)
    for ($i = 0; $i -lt $bands; $i++) { $c = Mix $Theme.deep $Theme.purple ([Math]::Floor($i * 6 / $bands) / 6); $g.FillRectangle((New-Object Drawing.SolidBrush $c), 0, $i * $px, $W, $px) }
    $rnd = New-Object Random 7
    for ($i = 0; $i -lt 46; $i++) {
        $sx = $rnd.Next(0, $W / $px) * $px; $sy = $rnd.Next(0, ($H - 40) / $px) * $px
        $c = if ($rnd.Next(3) -eq 0) { $Theme.pale } else { [Drawing.Color]::FromArgb(150, 255, 255, 255) }
        $g.FillRectangle((New-Object Drawing.SolidBrush $c), $sx, $sy, $px / 2, $px / 2)
        if ($rnd.Next(9) -eq 0) { foreach ($d in @(@(-2, 0), @(2, 0), @(0, -2), @(0, 2))) { $g.FillRectangle((New-Object Drawing.SolidBrush $Theme.pale), $sx + $d[0], $sy + $d[1], 2, 2) } }
    }
    # the moon: a disc of 4-pixel squares with a few craters
    $mx = $W - 30; $my = 24; $r = 4
    for ($a = -$r; $a -le $r; $a++) { for ($b = -$r; $b -le $r; $b++) { if ($a * $a + $b * $b -le $r * $r + 2) {
        $c = if (($a + $b) % 4 -eq 0 -and $a * $a + $b * $b -lt 10) { $Theme.lilac } else { $Theme.pale }
        $g.FillRectangle((New-Object Drawing.SolidBrush $c), $mx + $a * $px, $my + $b * $px, $px, $px) } } }
    # hills in two shades and the race track along the bottom, in the window's own background colour so they flow into it
    $far = Mix $Theme.deep $Theme.bg 0.35
    for ($x = 0; $x -lt $W; $x += $px) {
        $h1 = [int](14 + 10 * [Math]::Sin($x / 37.0) + 6 * [Math]::Sin($x / 13.0)); $h1 -= $h1 % $px
        $g.FillRectangle((New-Object Drawing.SolidBrush $far), $x, $H - 12 - $h1, $px, $h1 + 12)
        $h2 = [int](8 + 6 * [Math]::Sin(($x + 90) / 23.0)); $h2 -= $h2 % $px
        $g.FillRectangle((New-Object Drawing.SolidBrush $Theme.bg), $x, $H - 8 - $h2, $px, $h2 + 8)
    }
    for ($x = 0; $x -lt $W; $x += 16) { $g.FillRectangle((New-Object Drawing.SolidBrush $(if (($x / 16) % 2) { $Theme.purple } else { $Theme.pale })), $x, $H - 6, 8, 2) }
    Draw-PixelText $g 'CRASH TAG TEAM RACING' 'Arial Black' 13 3 ([Drawing.Color]::White) ([int]($W / 2)) 14 $Theme.deep ($W - 120)
    Draw-PixelText $g 'PC PORT  ·  BY NYXBORN' 'Arial' 9 2 $Theme.pale ([int]($W / 2)) 58 $Theme.deep ($W - 40)
    $g.Dispose(); $bmp
}
$header = New-Object Windows.Forms.PictureBox; $header.SetBounds(0, 0, 520, 104); $header.Image = New-Header 520 104; $form.Controls.Add($header)

$script:y = 116
$labels = @{}
function Add-Label([string]$key) { $l = New-Object Windows.Forms.Label; $l.SetBounds(24, $script:y + 3, 250, 24); $l.ForeColor = $Theme.pale; $form.Controls.Add($l); $script:labels[$key] = $l }
function Add-Combo($items) { $c = New-Object Windows.Forms.ComboBox; $c.DropDownStyle = 'DropDownList'; $c.FlatStyle = 'Flat'; $c.BackColor = $Theme.panel; $c.ForeColor = [Drawing.Color]::White; $c.SetBounds(280, $script:y, 220, 26); foreach ($i in $items) { [void]$c.Items.Add($i) }; $form.Controls.Add($c); $script:y += 32; $c }
function Add-Check([string]$key) { $c = New-Object Windows.Forms.CheckBox; $c.SetBounds(24, $script:y, 480, 26); $c.ForeColor = $Theme.pale; $c.FlatStyle = 'Flat'; $c.FlatAppearance.BorderColor = $Theme.lilac; $c.FlatAppearance.CheckedBackColor = $Theme.deep; $form.Controls.Add($c); $script:labels[$key] = $c; $script:y += 30; $c }
# a section title with a pixel square in front and a thin purple line under it
function Add-Section([string]$key) {
    $sq = New-Object Windows.Forms.Panel; $sq.SetBounds(16, $script:y + 12, 8, 8); $sq.BackColor = $Theme.purple; $form.Controls.Add($sq)
    $l = New-Object Windows.Forms.Label; $l.SetBounds(30, $script:y + 4, 470, 24); $l.Font = New-Object Drawing.Font('Segoe UI Semibold', 11); $l.ForeColor = $Theme.lilac; $form.Controls.Add($l); $script:labels[$key] = $l
    $ln = New-Object Windows.Forms.Panel; $ln.SetBounds(16, $script:y + 28, 488, 2); $ln.BackColor = $Theme.line; $form.Controls.Add($ln)
    $script:y += 34
}

Add-Label 'ui';    $cUi    = Add-Combo ($UiLangs | ForEach-Object { $_[1] })
Add-Label 'ver';   $cVer   = Add-Combo @()
Add-Label 'game';  $cGame  = Add-Combo @()
$script:y += 4
Add-Section 'video'
Add-Label 'profile'; $cProfile = Add-Combo @()
# Graphics profiles: Low (1x, the plain picture: the most stable), Medium (2x), High (the most this game takes well), Custom (what
# the player set by hand). The one this PC calls for is marked recommended and chosen on a first start.
$ProfileKeys = @('low', 'mid', 'high', 'custom')
function Profile-Text {
    $k = $UiLangs[[Math]::Max(0, $cUi.SelectedIndex)][0]
    $all = @{
        es = @{ names = @('Bajo', 'Medio', 'Alto', 'Personalizado'); rec = '(recomendado)'; left = 'Quedan ~{0} min'; soon = 'Queda menos de 1 min' }
        en = @{ names = @('Low', 'Medium', 'High', 'Custom'); rec = '(recommended)'; left = 'About {0} min left'; soon = 'Less than 1 min left' }
        fr = @{ names = @('Bas', 'Moyen', 'Élevé', 'Personnalisé'); rec = '(recommandé)'; left = 'Encore ~{0} min'; soon = 'Moins d''une minute' }
        de = @{ names = @('Niedrig', 'Mittel', 'Hoch', 'Benutzerdefiniert'); rec = '(empfohlen)'; left = 'Noch ~{0} Min.'; soon = 'Weniger als 1 Min.' }
        it = @{ names = @('Basso', 'Medio', 'Alto', 'Personalizzato'); rec = '(consigliato)'; left = 'Ancora ~{0} min'; soon = 'Meno di 1 min' }
        pt = @{ names = @('Baixo', 'Médio', 'Alto', 'Personalizado'); rec = '(recomendado)'; left = 'Faltam ~{0} min'; soon = 'Falta menos de 1 min' }
    }
    $all[$(if ($all.ContainsKey($k)) { $k } else { 'en' })]
}
$script:syncing = $false
function Fill-Profiles {
    $x = Profile-Text; $keep = [Math]::Max(0, $cProfile.SelectedIndex)
    $script:syncing = $true
    $cProfile.Items.Clear()
    for ($i = 0; $i -lt 4; $i++) { $n = $x.names[$i]; if ($ProfileKeys[$i] -eq $PcInfo.tier) { $n += ' ' + $x.rec }; [void]$cProfile.Items.Add($n) }
    $cProfile.SelectedIndex = $keep
    $script:syncing = $false
}
# a profile's settings into the boxes
function Apply-Profile([string]$p) {
    if ($p -eq 'custom') { return }
    $script:syncing = $true
    $cScale.SelectedIndex = $ProfileScale[$p] - 1
    $cLook.SelectedIndex = $(if ($p -eq 'low') { 1 } else { 0 })
    $kVsync.Checked = $true
    $kFps.Checked = ($p -ne 'low') -and $kFps.Enabled   # 50/60 FPS doubles the game's work: not on Low
    $script:syncing = $false
}
# which profile the boxes match now (Custom when none)
function Update-ProfileMatch {
    if ($script:syncing -or -not $cProfile.Items.Count) { return }
    $found = 3
    foreach ($i in 0..2) {
        $p = $ProfileKeys[$i]
        $ok = ($cScale.SelectedIndex -eq $ProfileScale[$p] - 1) -and ($cLook.SelectedIndex -eq $(if ($p -eq 'low') { 1 } else { 0 })) -and $kVsync.Checked
        if ($kFps.Enabled) { $ok = $ok -and ($kFps.Checked -eq ($p -ne 'low')) }
        if ($ok) { $found = $i; break }
    }
    $script:syncing = $true; $cProfile.SelectedIndex = $found; $script:syncing = $false
}
Add-Label 'scale'; $cScale = Add-Combo @('1x (PS2)', '2x', '3x', '4x')
Add-Label 'look';  $cLook  = Add-Combo ($Looks | ForEach-Object { $_[1] })
Add-Label 'api';   $cApi   = Add-Combo @('Vulkan', 'Direct3D 12')
$script:y += 2
$kVsync = Add-Check 'vsync'; $kFull = Add-Check 'full'; $kReshade = Add-Check 'reshade'
# ReShade itself is not part of the package: this button fetches its official setup and opens it on the game's program
$kReshade.Width = 480
$bRs = New-Object Windows.Forms.Button; $bRs.SetBounds(24, $kReshade.Top - 1, 200, 26); $bRs.Font = New-Object Drawing.Font('Segoe UI', 8.5); Style-Button $bRs $false; $form.Controls.Add($bRs)
function Rs-Text {
    $k = $UiLangs[[Math]::Max(0, $cUi.SelectedIndex)][0]
    $all = @{
        es = @{ button = 'Instalar ReShade...'; ask = "Se descargará el instalador oficial de ReShade (reshade.me) y se abrirá ya apuntando a este juego, con Vulkan. Ahí eliges los efectos y confirmas.`n`nReShade no es parte de este proyecto. ¿Continuar?"; fail = 'No se pudo descargar ReShade. Se abrirá su página para que lo descargues tú.'; none = 'Primero importa el juego.' }
        en = @{ button = 'Install ReShade...'; ask = "The official ReShade setup (reshade.me) will be downloaded and opened on this game, with Vulkan. Pick the effects there and confirm.`n`nReShade is not part of this project. Continue?"; fail = 'ReShade could not be downloaded. Its page will open so you can get it yourself.'; none = 'Import the game first.' }
        fr = @{ button = 'Installer ReShade...'; ask = "Le programme d'installation officiel de ReShade (reshade.me) sera téléchargé et ouvert sur ce jeu, avec Vulkan. Choisissez-y les effets et confirmez.`n`nReShade ne fait pas partie de ce projet. Continuer ?"; fail = "ReShade n'a pas pu être téléchargé. Sa page va s'ouvrir pour que vous le téléchargiez."; none = "Importez d'abord le jeu." }
        de = @{ button = 'ReShade installieren...'; ask = "Das offizielle ReShade-Setup (reshade.me) wird heruntergeladen und für dieses Spiel mit Vulkan geöffnet. Dort Effekte wählen und bestätigen.`n`nReShade gehört nicht zu diesem Projekt. Fortfahren?"; fail = 'ReShade konnte nicht heruntergeladen werden. Die Seite wird geöffnet, damit du es selbst lädst.'; none = 'Importiere zuerst das Spiel.' }
        it = @{ button = 'Installa ReShade...'; ask = "Verrà scaricato il programma di installazione ufficiale di ReShade (reshade.me) e aperto su questo gioco, con Vulkan. Scegli lì gli effetti e conferma.`n`nReShade non fa parte di questo progetto. Continuare?"; fail = 'Impossibile scaricare ReShade. Si aprirà la sua pagina per scaricarlo tu.'; none = 'Prima importa il gioco.' }
        pt = @{ button = 'Instalar ReShade...'; ask = "O instalador oficial do ReShade (reshade.me) será baixado e aberto já neste jogo, com Vulkan. Escolha os efeitos lá e confirme.`n`nO ReShade não faz parte deste projeto. Continuar?"; fail = 'Não foi possível baixar o ReShade. A página dele será aberta para você baixar.'; none = 'Importe o jogo primeiro.' }
    }
    $all[$(if ($all.ContainsKey($k)) { $k } else { 'en' })]
}
Add-Section 'extras'
$kFps = Add-Check 'fps'; $kPsp = Add-Check 'psp'
$script:y += 12
$note = New-Object Windows.Forms.Label; $note.SetBounds(16, $script:y - 6, 488, 20); $note.ForeColor = $Theme.lilac; $note.TextAlign = 'MiddleCenter'; $form.Controls.Add($note)
$script:y += 16
$bPlay = New-Object Windows.Forms.Button; $bPlay.SetBounds(16, $script:y, 196, 48); $bPlay.Font = New-Object Drawing.Font('Segoe UI Black', 14); Style-Button $bPlay $true; $form.Controls.Add($bPlay)
$bImport = New-Object Windows.Forms.Button; $bImport.SetBounds(222, $script:y + 8, 120, 32); Style-Button $bImport $false; $form.Controls.Add($bImport)
$bDel = New-Object Windows.Forms.Button; $bDel.SetBounds(350, $script:y + 8, 82, 32); Style-Button $bDel $false; $bDel.ForeColor = $Theme.red; $form.Controls.Add($bDel)
$bQuit = New-Object Windows.Forms.Button; $bQuit.SetBounds(440, $script:y + 8, 64, 32); Style-Button $bQuit $false; $bQuit.ForeColor = $Theme.muted; $form.Controls.Add($bQuit)
$script:y += 60
# footer: a pixel strip in the purple gradient, and the author with a link to the GitHub profile
$strip = New-Object Windows.Forms.PictureBox; $strip.SetBounds(0, $script:y, 520, 4)
$sb = New-Object Drawing.Bitmap 520, 4; $sg = [Drawing.Graphics]::FromImage($sb)
for ($x = 0; $x -lt 520; $x += 8) { $sg.FillRectangle((New-Object Drawing.SolidBrush (Mix $Theme.deep $Theme.purple ([Math]::Floor($x * 8 / 520) / 8))), $x, 0, 8, 4) }
$sg.Dispose(); $strip.Image = $sb; $form.Controls.Add($strip)
$by = New-Object Windows.Forms.LinkLabel; $by.Text = "By NyxBorn  ·  github.com/Miguel0827  ·  $Version"; $by.Font = New-Object Drawing.Font('Segoe UI Semibold', 9)
$by.LinkArea = New-Object Windows.Forms.LinkArea(15, 21); $by.ForeColor = $Theme.lilac; $by.LinkColor = $Theme.muted; $by.ActiveLinkColor = $Theme.pale; $by.VisitedLinkColor = $Theme.muted; $by.LinkBehavior = 'HoverUnderline'
$by.AutoSize = $false; $by.TextAlign = 'MiddleCenter'; $by.SetBounds(0, $script:y + 8, 520, 20); $form.Controls.Add($by)
$by.Add_LinkClicked({ Start-Process 'https://github.com/Miguel0827' })
$form.ClientSize = New-Object Drawing.Size(520, ($script:y + 34))
$form.AcceptButton = $bPlay; $form.CancelButton = $bQuit
$form.Add_Shown({ $form.ActiveControl = $(if ($bPlay.Enabled) { $bPlay } else { $bImport }) })   # no list highlighted in blue on opening
# where everything was put, for Relayout: a hidden row (version, game language) gives its room to what is below it
$baseTop = @{}; foreach ($c in $form.Controls) { $baseTop[$c] = $c.Top }
$baseHeight = $form.ClientSize.Height
$verTop = $cVer.Top; $gameTop = $cGame.Top
$reshadeTop = $kReshade.Top
$script:showVer = $true; $script:showGame = $true
# version / game language rows (32 high) and the ReShade line (30 high, Vulkan only)
function Relayout([bool]$showVer = $script:showVer, [bool]$showGame = $script:showGame) {
    $script:showVer = $showVer; $script:showGame = $showGame
    $showReshade = $cApi.SelectedIndex -eq 0
    foreach ($c in @($cVer, $labels['ver'])) { $c.Visible = $showVer }
    foreach ($c in @($cGame, $labels['game'])) { $c.Visible = $showGame }
    # ReShade installed for this game (its setup leaves ReShade.ini, or its DLL, next to the game's program): the on/off box; else
# the Install button
    $hasRs = $false; $cg = Current-Game
    if ($cg) {
        $bin = Join-Path $Root "build\native-$($cg.name)"
        $hasRs = (Test-Path (Join-Path $bin 'ReShade.ini')) -or (Test-Path (Join-Path $bin 'ReShade64.dll')) -or (Test-Path (Join-Path $bin 'dxgi.dll'))
        # or ReShade's Vulkan layer, installed for the whole PC, with this game's program in its list of programs
        if (-not $hasRs) {
            try {
                $exeFull = (Get-Item (Join-Path $bin 'ps2run.exe') -ErrorAction Stop).FullName
                foreach ($k in 'HKLM:\SOFTWARE\Khronos\Vulkan\ImplicitLayers', 'HKCU:\SOFTWARE\Khronos\Vulkan\ImplicitLayers') {
                    if (-not (Test-Path $k)) { continue }
                    foreach ($json in @((Get-Item $k).Property | Where-Object { $_ -match 'ReShade' })) {
                        $apps = Join-Path (Split-Path -Parent $json) 'ReShadeApps.ini'
                        if (Test-Path $apps) {
                            $list = ((Get-Content $apps -Raw) -replace '(?m)^Apps=', '') -split '[,\r\n]+' | Where-Object { $_ }
                            if ($list | Where-Object { $_.Trim() -ieq $exeFull }) { $hasRs = $true }
                        }
                    }
                }
            } catch {}
        }
    }
    $kReshade.Visible = $showReshade -and $hasRs; $bRs.Visible = $showReshade -and -not $hasRs
    $gone = @(); if (-not $showVer) { $gone += , @($verTop, 32) }; if (-not $showGame) { $gone += , @($gameTop, 32) }; if (-not $showReshade) { $gone += , @($reshadeTop, 30) }
    $total = 0; foreach ($g in $gone) { $total += $g[1] }
    foreach ($c in $form.Controls) { $shift = 0; foreach ($g in $gone) { if ($baseTop[$c] -gt $g[0] + 4) { $shift += $g[1] } }; $c.Top = $baseTop[$c] - $shift }
    $form.ClientSize = New-Object Drawing.Size(520, ($baseHeight - $total))
}

function Lang { $Texts[$UiLangs[[Math]::Max(0, $cUi.SelectedIndex)][0]] }
function Current-Game { if ($Games.Count -eq 0 -or $cVer.SelectedIndex -lt 0) { return $null }; $Games[$cVer.SelectedIndex] }

function Fill-Versions {
    $t = Lang; $keep = $cVer.SelectedIndex
    $cVer.Items.Clear()
    foreach ($g in $Games) { [void]$cVer.Items.Add($(if ($g.region -eq 'eu') { $t.eu } else { $t.us })) }
    if ($Games.Count -gt 0) {
        $want = [Math]::Max(0, [Array]::IndexOf(@($Games | ForEach-Object { $_.name }), [string]$cfg.version))
        $cVer.SelectedIndex = $(if ($keep -ge 0 -and $keep -lt $Games.Count) { $keep } else { $want })
    }
}
function Load-Game {
    $g = Current-Game
    $has = $null -ne $g
    foreach ($c in @($cVer, $cGame, $cProfile, $cScale, $cLook, $cApi, $kVsync, $kFull, $kReshade, $kFps, $kPsp, $bPlay)) { $c.Enabled = $has }
    $bDel.Visible = $has
    # the button to press stands out: Import while nothing is installed, PLAY once something is
    Style-Button $bPlay $has; Style-Button $bImport (-not $has)
    $note.Text = $(if ($has) { '' } else { (Lang).none })
    if (-not $has) { Relayout $false $false }
    if (-not $has) { return }
    $cGame.Items.Clear(); foreach ($n in $g.languages) { [void]$cGame.Items.Add($LangNames[[int]$n]) }
    $cGame.SelectedIndex = [Math]::Max(0, [Array]::IndexOf(@($g.languages | ForEach-Object { [int]$_ }), [int]$cfg.game))
    # only what there is to choose: the version row with two versions imported, the language row with a disc that has several
    Relayout ($Games.Count -gt 1) (@($g.languages).Count -gt 1)

    $ini = Read-Ini (Join-Path $Root "games\$($g.name)\keys.ini")
    $sc = $DefaultScale; if ($ini.scale -match '^[1-4]$') { $sc = [int]$ini.scale }; $cScale.SelectedIndex = $sc - 1
    $lk = $DefaultLook; if ($ini.look) { $i = [Array]::IndexOf(@($Looks | ForEach-Object { $_[0] -replace '_', '' }), ($ini.look -replace '[ _]', '').ToLower()); if ($i -ge 0) { $lk = $i } }; $cLook.SelectedIndex = $lk
    $kVsync.Checked = $(if ($ini.vsync) { $ini.vsync -match '^(on|1|yes)$' } else { $true })
    $kFps.Enabled = (Get-Item (Join-Path $Root "games\$($g.name)\patchsets\fps.txt") -ErrorAction SilentlyContinue).Length -gt 0
    $kPsp.Enabled = (Get-Item (Join-Path $Root "games\$($g.name)\patchsets\psp.txt") -ErrorAction SilentlyContinue).Length -gt 0
    $kReshade.Enabled = $cApi.SelectedIndex -eq 0; $bRs.Enabled = $kReshade.Enabled
    Update-ProfileMatch
}
function Apply-Texts {
    $t = Lang
    $form.Text = $t.title
    foreach ($k in $labels.Keys) { if ($t.ContainsKey($k)) { $labels[$k].Text = $t[$k] } }
    $bPlay.Text = $t.play; $bRs.Text = (Rs-Text).button; Fill-Profiles; Update-ProfileMatch; $bImport.Text = $t.import; $bDel.Text = $t.del; $bQuit.Text = $t.quit
    Fill-Versions
    if (-not (Current-Game)) { $note.Text = $t.none }
}

# the reminder before importing (the game is the player's: an ISO of their own disc), in the launcher's colours
function Show-Reminder {
    $x = Extra
    $d = New-Object Windows.Forms.Form; $d.Text = $x.owntitle; $d.StartPosition = 'CenterParent'; $d.FormBorderStyle = 'FixedDialog'
    $d.MaximizeBox = $false; $d.MinimizeBox = $false; $d.ShowInTaskbar = $false; $d.BackColor = $Theme.bg; $d.Font = New-Object Drawing.Font('Segoe UI', 10)
    $d.ClientSize = New-Object Drawing.Size(420, 170)
    $band = New-Object Windows.Forms.PictureBox; $band.SetBounds(0, 0, 420, 8)
    $bb = New-Object Drawing.Bitmap 420, 8; $bg = [Drawing.Graphics]::FromImage($bb)
    for ($i = 0; $i -lt 420; $i += 8) { $bg.FillRectangle((New-Object Drawing.SolidBrush (Mix $Theme.deep $Theme.purple ([Math]::Floor($i * 8 / 420) / 8))), $i, 0, 8, 8) }
    $bg.Dispose(); $band.Image = $bb; $d.Controls.Add($band)
    $head = New-Object Windows.Forms.Label; $head.Text = $x.owntitle; $head.SetBounds(20, 20, 380, 26); $head.Font = New-Object Drawing.Font('Segoe UI Semibold', 12); $head.ForeColor = $Theme.lilac; $d.Controls.Add($head)
    $msg = New-Object Windows.Forms.Label; $msg.Text = $x.own; $msg.SetBounds(20, 50, 380, 56); $msg.ForeColor = $Theme.pale; $d.Controls.Add($msg)
    $ok = New-Object Windows.Forms.Button; $ok.Text = $x.ok; $ok.SetBounds(196, 120, 120, 34); Style-Button $ok $true; $ok.DialogResult = 'OK'; $d.Controls.Add($ok)
    $no = New-Object Windows.Forms.Button; $no.Text = $x.no; $no.SetBounds(324, 120, 80, 34); Style-Button $no $false; $no.ForeColor = $Theme.muted; $no.DialogResult = 'Cancel'; $d.Controls.Add($no)
    $d.AcceptButton = $ok; $d.CancelButton = $no
    $r = $d.ShowDialog($form); $d.Dispose()
    $r -eq 'OK'
}

# ---------------------------------------------------------------- importing a disc (runs tools\Instalar.ps1 and shows its output)
function Import-Iso {
    $t = Lang
    $log = Join-Path $env:TEMP 'cttr-pc-install.log'
    # one installation at a time: one that is already running (started from this or another launcher window) is shown, not started again
    $p = $null
    $lock = Join-Path $Root 'install.lock'
    if (Test-Path $lock) {
        $lockPid = 0; [void][int]::TryParse(((Get-Content $lock -ErrorAction SilentlyContinue) -join '').Trim(), [ref]$lockPid)
        $p = Get-Process -Id $lockPid -ErrorAction SilentlyContinue
        if ($p -and $p.ProcessName -notmatch 'powershell') { $p = $null }
        if ($p) { $started = $p.StartTime } else { Remove-Item $lock -ErrorAction SilentlyContinue }   # left by an installation that was stopped
    }
    if (-not $p) {
        # the game is the player's: the ISO has to come from their own disc
        if (-not (Show-Reminder)) { return }
        $dlg = New-Object Windows.Forms.OpenFileDialog; $dlg.Filter = $t.isofilter
        if ($dlg.ShowDialog($form) -ne 'OK') { return }
        Remove-Item $log -ErrorAction SilentlyContinue
        $installer = Join-Path $Here 'Instalar.ps1'
        $cmd = "& '$($installer.Replace("'", "''"))' -Iso '$($dlg.FileName.Replace("'", "''"))' -Root '$($Root.Replace("'", "''"))' *> '$($log.Replace("'", "''"))'; exit `$LASTEXITCODE"
        # started on its own (not as a child of this window), so closing the launcher or anything around it never stops an installation
        $line = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand ' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
        try {
            $made = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $line; CurrentDirectory = $Root } -ErrorAction Stop
            if ($made.ReturnValue -ne 0) { throw "Win32_Process.Create = $($made.ReturnValue)" }
            $p = Get-Process -Id $made.ProcessId -ErrorAction Stop
        } catch {
            [void][Windows.Forms.MessageBox]::Show("$($t.err)`n`n$($_.Exception.Message)", $t.title, 'OK', 'Error')
            return
        }
        $started = Get-Date
    }

    $w = New-Object Windows.Forms.Form; $w.Text = $t.installing; $w.StartPosition = 'CenterParent'; $w.ClientSize = New-Object Drawing.Size(720, 440)
    $w.BackColor = $Theme.bg; $w.ForeColor = [Drawing.Color]::White; $w.ControlBox = $false; $w.Font = New-Object Drawing.Font('Segoe UI', 10)
    $stage = New-Object Windows.Forms.Label; $stage.SetBounds(12, 12, 560, 26); $stage.Font = New-Object Drawing.Font('Segoe UI Semibold', 12); $stage.ForeColor = $Theme.lilac; $w.Controls.Add($stage)
    $clock = New-Object Windows.Forms.Label; $clock.SetBounds(580, 14, 128, 24); $clock.TextAlign = 'MiddleRight'; $clock.ForeColor = $Theme.muted; $w.Controls.Add($clock)
$est = New-Object Windows.Forms.Label; $est.SetBounds(250, 14, 330, 24); $est.TextAlign = 'MiddleRight'; $est.ForeColor = $Theme.lilac; $w.Controls.Add($est)
# seconds from each mark (below) to the next on a fast PC; marks 0 and 1 are downloads
$refSec = @(4, 45, 2, 20, 3, 2, 3, 10, 80, 10, 90, 4, 0)
$prior = @{ low = 4.0; mid = 2.0; high = 1.0 }[$PcInfo.tier]
$script:seen = @{}
    # the progress bar as a row of pixel blocks in the purple gradient (Windows' own bar is green and cannot be recoloured)
    $bar = New-Object Windows.Forms.PictureBox; $bar.SetBounds(12, 44, 696, 26); $bar.BackColor = $Theme.panel; $w.Controls.Add($bar)
    $script:barVal = 0
    $bar.Add_Paint({ param($s, $e)
        $blocks = 58; $bw = 12; $filled = [int]($blocks * $script:barVal / 100)
        for ($i = 0; $i -lt $blocks; $i++) {
            $c = if ($i -lt $filled) { Mix $Theme.deep $Theme.purple ($i / [double]$blocks) } else { $Theme.line }
            $e.Graphics.FillRectangle((New-Object Drawing.SolidBrush $c), 2 + $i * $bw, 4, $bw - 2, 18)
        } })
    $box = New-Object Windows.Forms.TextBox; $box.Multiline = $true; $box.ReadOnly = $true; $box.ScrollBars = 'Vertical'; $box.SetBounds(12, 82, 696, 306); $box.BorderStyle = 'FixedSingle'
    $box.BackColor = $Theme.panel; $box.ForeColor = $Theme.pale; $box.Font = New-Object Drawing.Font('Consolas', 9); $w.Controls.Add($box)
    $ok = New-Object Windows.Forms.Button; $ok.Text = $t.close; $ok.SetBounds(588, 396, 120, 36); $ok.Visible = $false; Style-Button $ok $true
    $ok.Font = New-Object Drawing.Font('Segoe UI Semibold', 10); $w.Controls.Add($ok)
    $ok.Add_Click({ $w.Close() })
    # once it is installed: the game's shortcut on the desktop, made only when the player presses it
    $sc = New-Object Windows.Forms.Button; $sc.SetBounds(12, 396, 300, 36); $sc.Visible = $false; Style-Button $sc $false; $sc.ForeColor = $Theme.lilac; $sc.FlatAppearance.BorderColor = $Theme.purple; $w.Controls.Add($sc)
    $sc.Text = (Extra).sc
    $sc.Add_Click({ try { Make-Shortcut; $sc.Text = [char]0x2713 + ' ' + (Extra).scdone; $sc.Enabled = $false } catch { [void][Windows.Forms.MessageBox]::Show($_.Exception.Message, $t.title, 'OK', 'Error') } })
    # Cancel: the installer and everything it started stop; the next import of that version cleans up what was half made
    $stop = New-Object Windows.Forms.Button; $stop.Text = $t.cancel; $stop.SetBounds(12, 396, 120, 36); Style-Button $stop $false; $stop.ForeColor = $Theme.muted; $w.Controls.Add($stop)
    $script:cancelled = $false
    $stop.Add_Click({ $script:cancelled = $true; $stop.Enabled = $false; Start-Process taskkill -ArgumentList '/T', '/F', '/PID', $p.Id -WindowStyle Hidden -Wait })
    # what the installer prints, in order, and where the bar is when it appears (the conversion's own six steps are most of the time)
    $marks = @(@('^=== Descargando ps2', 2, 0), @('^=== Herramientas', 6, 1), @('^=== Aplicando', 16, 2), @('^=== Compilando el convertidor', 18, 3),
               @('^=== Reconociendo', 30, 4), @('^== \[1/6\]', 34, 5), @('^== \[2/6\]', 37, 5), @('^== \[3/6\]', 40, 6), @('^== \[4/6\]', 50, 7),
               @('^== \[5/6\]', 66, 8), @('^== \[6/6\]', 70, 9), @('^=== Preparando', 96, 10), @('^LISTO', 100, 11))
    # when it began (the clock); an installation found running keeps its own start time
    $script:startedAt = [DateTime]::Now
    try { if ($started) { $script:startedAt = [DateTime]$started } } catch {}
    $stage.Text = $t.steps[0]
    $timer = New-Object Windows.Forms.Timer; $timer.Interval = 1000
    $timer.Add_Tick({
        $clock.Text = '{0} {1:mm\:ss}' -f $t.elapsed, ([DateTime]::Now - $script:startedAt)
        if (Test-Path $log) {
            try {
                $all = Get-Content $log -ErrorAction Stop
                $box.Text = (($all | Select-Object -Last 40) -join "`r`n"); $box.SelectionStart = $box.Text.Length; $box.ScrollToCaret()
                $pct = 1; $step = 0
                foreach ($m in $marks) { if ($all -match $m[0]) { $pct = $m[1]; $step = $m[2] } }
                # inside the long steps the bar creeps on, so it never looks stuck (never past the next mark)
                $next = 100; foreach ($m in $marks) { if ($m[1] -gt $pct) { $next = $m[1]; break } }
                if ($script:creep -lt $next - 1 -and $script:creep -ge $pct) { $script:creep += 0.15 } else { $script:creep = $pct }
                $script:barVal = [Math]::Min(100, [int][Math]::Max($pct, [Math]::Min($next - 1, $script:creep))); $bar.Invalidate()
                $stage.Text = $t.steps[$step]
                # when each mark first showed up (an installation found running: from now on)
                for ($k = 0; $k -lt $marks.Count; $k++) { if (-not $script:seen.ContainsKey($k) -and ($all -match $marks[$k][0])) { $script:seen[$k] = [DateTime]::Now } }
                $done = @($script:seen.Keys | Sort-Object)
                if ($done.Count -and -not $script:seen.ContainsKey($marks.Count - 1)) {
                    $act = @{ net = 0.0; cpu = 0.0 }; $ref = @{ net = 0.0; cpu = 0.0 }
                    for ($j = 0; $j -lt $done.Count - 1; $j++) {
                        $a = $done[$j]; $b = $done[$j + 1]; $kind = $(if ($a -le 1) { 'net' } else { 'cpu' })
                        $act[$kind] += ($script:seen[$b] - $script:seen[$a]).TotalSeconds
                        for ($q = $a; $q -lt $b; $q++) { $ref[$kind] += $refSec[$q] }
                    }
                    $rCpu = $(if ($ref.cpu -ge 20) { [Math]::Max(0.3, $act.cpu / $ref.cpu) } else { $prior })
                    $rNet = $(if ($ref.net -ge 20) { [Math]::Max(0.3, $act.net / $ref.net) } else { 1.0 })
                    $cur = $done[-1]
                    $left = [Math]::Max(5, $refSec[$cur] * $(if ($cur -le 1) { $rNet } else { $rCpu }) - ([DateTime]::Now - $script:seen[$cur]).TotalSeconds)
                    for ($q = $cur + 1; $q -lt $refSec.Count; $q++) { if ($q -eq 1 -and $cur -ge 1) { continue }; $left += $refSec[$q] * $(if ($q -le 1) { $rNet } else { $rCpu }) }
                    $x = Profile-Text
                    $est.Text = $(if ($left -lt 60) { $x.soon } else { $x.left -f [Math]::Ceiling($left / 60) })
                } else { $est.Text = '' }
            } catch {}
        }
        if ($p.HasExited) {
            $timer.Stop(); $ok.Visible = $true; $stop.Visible = $false; $ok.Focus(); $w.ControlBox = $true
            if ($script:cancelled) { $w.Text = $t.cancelled; $stage.Text = $t.cancelled; $stage.ForeColor = [Drawing.Color]::Silver }
            elseif (Select-String -Path $log -Pattern '^LISTO' -Quiet) {
                $w.Text = $t.done; $stage.Text = $t.done; $script:barVal = 100; $bar.Invalidate()
                if (Test-Path $GameExe) { $sc.Visible = $true; if (Test-Path $ShortcutFile) { $sc.Text = [char]0x2713 + ' ' + (Extra).scdone; $sc.Enabled = $false } }
            }
            else { $w.Text = $t.failed; $stage.Text = $t.failed; $stage.ForeColor = $Theme.red }
        }
    })
    $script:creep = 0
    $timer.Start()
    [void]$w.ShowDialog($form)
    $script:Games = Get-Games
    $Games = $script:Games; Update-SavesFolder; Update-GameExe
    Fill-Versions; Load-Game
}

# ---------------------------------------------------------------- start values and events
$cUi.SelectedIndex = [Math]::Max(0, [Array]::IndexOf(@($UiLangs | ForEach-Object { $_[0] }), [string]$cfg.ui))
$cApi.SelectedIndex = $(if ($cfg.api -eq 'dx12') { 1 } else { 0 })
$kFull.Checked = [bool]$cfg.full; $kReshade.Checked = [bool]$cfg.reshade; $kFps.Checked = [bool]$cfg.fps; $kPsp.Checked = [bool]$cfg.psp
Apply-Texts; Load-Game
Update-ProfileMatch
$cUi.Add_SelectedIndexChanged({ Apply-Texts })
$cVer.Add_SelectedIndexChanged({ Load-Game })
$cApi.Add_SelectedIndexChanged({ Relayout })
$bQuit.Add_Click({ $form.Close() })
$bImport.Add_Click({ try { Import-Iso } catch { [void][Windows.Forms.MessageBox]::Show("$((Lang).err)`n`n$($_.Exception.Message)", (Lang).title, 'OK', 'Error') } })
$bDel.Add_Click({
    $g = Current-Game; if (-not $g) { return }
    $t = Lang
    $answer = [Windows.Forms.MessageBox]::Show($t.delask, "$($t.del): $($cVer.SelectedItem)", 'YesNoCancel', 'Warning')
    if ($answer -eq 'Cancel') { return }
    $keepSaves = $answer -eq 'Yes'
    $gameDir = Join-Path $Root "games\$($g.name)"
    $backup = Join-Path $Root "saves-backup\$($g.name)"
    if (-not $keepSaves) { Remove-Item $backup -Recurse -Force -ErrorAction SilentlyContinue }
    if ($keepSaves) { New-Item -ItemType Directory -Force $backup | Out-Null }
    if ($keepSaves -and (Test-Path $gameDir)) { Get-ChildItem $gameDir -Force | Where-Object { $_.Name -match '^(memcard\.ps2.*|keys\.ini|states|reports)$' } | ForEach-Object { Copy-Item $_.FullName $backup -Recurse -Force } }
    foreach ($d in @($gameDir, (Join-Path $Root "build\native-$($g.name)"), (Join-Path $Root "generated\$($g.name)"))) { if (Test-Path $d) { Remove-Item $d -Recurse -Force -ErrorAction SilentlyContinue } }
    $script:Games = Get-Games
    $Games = $script:Games; Update-GameExe
    $cVer.SelectedIndex = -1
    Fill-Versions; Load-Game
})

$bPlay.Add_Click({
    $g = Current-Game; if (-not $g) { return }
    $gameDir = Join-Path $Root "games\$($g.name)"
    Set-IniLines (Join-Path $gameDir 'keys.ini') @{ scale = ($cScale.SelectedIndex + 1); look = $Looks[$cLook.SelectedIndex][0]; vsync = $(if ($kVsync.Checked) { 'on' } else { 'off' }) }
    $cfg.ui = $UiLangs[$cUi.SelectedIndex][0]; $cfg.version = $g.name; $cfg.profile = $ProfileKeys[[Math]::Max(0, $cProfile.SelectedIndex)]
    if ($cGame.SelectedIndex -ge 0) { $cfg.game = [int]@($g.languages)[$cGame.SelectedIndex] }
    $cfg.api = $(if ($cApi.SelectedIndex -eq 1) { 'dx12' } else { 'vulkan' })
    $cfg.reshade = $kReshade.Checked; $cfg.fps = $kFps.Checked; $cfg.psp = $kPsp.Checked; $cfg.full = $kFull.Checked
    [IO.File]::WriteAllText($CfgFile, ($cfg | ConvertTo-Json), (New-Object Text.UTF8Encoding $false))
    $form.Hide()
    $p = Start-Game $g
    Watch-Game $p $g
    $form.Close()
})

if ($FirstRun -and (Current-Game)) {
    $kind = @{ low = @('PC modesto', 'modest PC'); mid = @('PC medio', 'medium PC'); high = @('PC potente', 'powerful PC') }[$PcInfo.tier]
    $note.Text = $(if ($cfg.ui -eq 'es') { "Ajustes elegidos para tu PC: $($kind[0]) ($($DefaultScale)x)" } else { "Settings chosen for your PC: $($kind[1]) ($($DefaultScale)x)" })
}
$cProfile.Add_SelectedIndexChanged({ if (-not $script:syncing -and $cProfile.SelectedIndex -ge 0) { Apply-Profile $ProfileKeys[$cProfile.SelectedIndex] } })
foreach ($c in @($cScale, $cLook)) { $c.Add_SelectedIndexChanged({ Update-ProfileMatch }) }
$kVsync.Add_CheckedChanged({ Update-ProfileMatch })
$kFps.Add_CheckedChanged({ Update-ProfileMatch })
$form.Add_Activated({ if ($form.Visible) { Relayout } })
$bRs.Add_Click({
    $x = Rs-Text; $g = Current-Game
    if (-not $g) { [void][Windows.Forms.MessageBox]::Show($x.none, 'ReShade', 'OK', 'Information'); return }
    if ([Windows.Forms.MessageBox]::Show($x.ask, 'ReShade', 'YesNo', 'Question') -ne 'Yes') { return }
    $exe = (Get-Item (Join-Path $Root "build\native-$($g.name)\ps2run.exe")).FullName
    $form.Cursor = [Windows.Forms.Cursors]::WaitCursor
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        # the newest setup named on the official page (not the add-on one)
        $page = (Invoke-WebRequest -UseBasicParsing 'https://reshade.me/' -TimeoutSec 20).Content
        $m = [regex]::Match($page, 'downloads/(ReShade_Setup_[0-9.]+\.exe)')
        if (-not $m.Success) { throw 'no setup link on reshade.me' }
        $setup = Join-Path $env:TEMP $m.Groups[1].Value
        if (-not (Test-Path $setup) -or (Get-Item $setup).Length -lt 1MB) { Invoke-WebRequest -UseBasicParsing ("https://reshade.me/downloads/" + $m.Groups[1].Value) -OutFile $setup -TimeoutSec 120 }
        if ((Get-Item $setup).Length -lt 1MB) { throw 'the download is too small' }
        Start-Process -FilePath $setup -ArgumentList @("`"$exe`"", '--api', 'vulkan')
        $kReshade.Checked = $true
    } catch {
        [void][Windows.Forms.MessageBox]::Show($x.fail, 'ReShade', 'OK', 'Warning')
        Start-Process 'https://reshade.me/'
    } finally { $form.Cursor = [Windows.Forms.Cursors]::Default }
})
[void]$form.ShowDialog()
