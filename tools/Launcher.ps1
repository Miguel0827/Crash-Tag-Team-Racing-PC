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
 es = @{ title='Crash Tag Team Racing - PC'; ui='Idioma del launcher y del menú F1'; ver='Versión'; game='Idioma del juego'; video='Imagen'; scale='Resolución interna';
         look='Estilo de imagen'; vsync='Sincronización vertical'; full='Pantalla completa'; api='API gráfica';
         reshade='Mejora gráfica ReShade'; perf='Corrección de rendimiento de menús'; extras='Extras';
         fps='Doble de FPS (el juego original va a 25-30)'; psp='Desbloquear contenido de PSP (autos, arenas, cooperativo)';
         pad='Mando'; inv='Invertir stick derecho'; play='JUGAR'; import='Importar ISO...'; quit='Salir'; none='Importa tu ISO del juego para empezar';
         eu='Europa (6 idiomas)'; us='USA / Latinoamérica (inglés)'; isofilter='Imagen de disco (*.iso)|*.iso'; installing='Instalando - no cierres esta ventana';
         done='Listo. Ya puedes jugar.'; failed='La instalación falló. Revisa el registro.'; close='Cerrar'; steps=@('Descargando el convertidor','Descargando herramientas (~1 GB)','Aplicando los arreglos','Compilando el convertidor','Reconociendo el disco','Leyendo el disco','Traduciendo el código del juego','Probando el juego','Programas gráficos','Compilando el juego','Preparando opciones','Listo'); elapsed='Tiempo'; cancel='Cancelar'; cancelled='Instalación cancelada. La próxima importación empieza de cero.'; del='Eliminar'; delask='¿Eliminar esta versión?

Sí: se borra el juego convertido y se guardan tus partidas (vuelven si la importas de nuevo).
No: se borra todo, también las partidas.'; err='No se pudo iniciar la instalación:'; invs=@('No','Horizontal','Vertical','Ambos') }
 en = @{ title='Crash Tag Team Racing - PC'; ui='Launcher and F1 menu language'; ver='Version'; game='Game language'; video='Picture'; scale='Internal resolution';
         look='Picture look'; vsync='Vertical sync'; full='Full screen'; api='Graphics API';
         reshade='ReShade graphics enhancement'; perf='Menu performance fix'; extras='Extras';
         fps='Double FPS (the original runs at 25-30)'; psp='Unlock PSP content (cars, arenas, co-op)';
         pad='Controller'; inv='Invert right stick'; play='PLAY'; import='Import ISO...'; quit='Quit'; none='Import your game ISO to start';
         eu='Europe (6 languages)'; us='USA / Latin America (English)'; isofilter='Disc image (*.iso)|*.iso'; installing='Installing - do not close this window';
         done='Done. You can play now.'; failed='The installation failed. See the log.'; close='Close'; steps=@('Downloading the converter','Downloading tools (~1 GB)','Applying the fixes','Building the converter','Recognising the disc','Reading the disc','Translating the game code','Test-running the game','Graphics programs','Compiling the game','Preparing options','Done'); elapsed='Time'; cancel='Cancel'; cancelled='Installation cancelled. The next import starts from scratch.'; del='Delete'; delask='Delete this version?

Yes: the converted game is removed and your saves are kept (they come back if you import it again).
No: everything is removed, saves too.'; err='The installation could not start:'; invs=@('No','Left-right','Up-down','Both') }
 fr = @{ title='Crash Tag Team Racing - PC'; ui='Langue du lanceur et du menu F1'; ver='Version'; game='Langue du jeu'; video='Image'; scale='Résolution interne';
         look="Style d'image"; vsync='Synchronisation verticale'; full='Plein écran'; api='API graphique';
         reshade='Amélioration graphique ReShade'; perf='Correctif de performance des menus'; extras='Extras';
         fps="FPS doublés (l'original tourne à 25-30)"; psp='Débloquer le contenu PSP (voitures, arènes, coop)';
         pad='Manette'; inv='Inverser le stick droit'; play='JOUER'; import='Importer un ISO...'; quit='Quitter'; none='Importez votre ISO du jeu pour commencer';
         eu='Europe (6 langues)'; us='USA / Amérique latine (anglais)'; isofilter='Image disque (*.iso)|*.iso'; installing='Installation - ne fermez pas cette fenêtre';
         done='Terminé. Vous pouvez jouer.'; failed="L'installation a échoué. Voir le journal."; close='Fermer'; steps=@('Téléchargement du convertisseur','Téléchargement des outils (~1 Go)','Application des correctifs','Compilation du convertisseur','Reconnaissance du disque','Lecture du disque','Traduction du code du jeu','Test du jeu','Programmes graphiques','Compilation du jeu','Préparation des options','Terminé'); elapsed='Temps'; cancel='Annuler'; cancelled="Installation annulée. La prochaine importation repart de zéro."; del='Supprimer'; delask="Supprimer cette version ?

Oui : le jeu converti est effacé et vos sauvegardes sont gardées.
Non : tout est effacé, sauvegardes comprises."; err="Impossible de lancer l'installation :"; invs=@('Non','Horizontal','Vertical','Les deux') }
 de = @{ title='Crash Tag Team Racing - PC'; ui='Sprache von Launcher und F1-Menü'; ver='Version'; game='Spielsprache'; video='Bild'; scale='Interne Auflösung';
         look='Bildstil'; vsync='Vertikale Synchronisation'; full='Vollbild'; api='Grafik-API';
         reshade='ReShade-Grafikverbesserung'; perf='Leistungskorrektur für Menüs'; extras='Extras';
         fps='Doppelte FPS (das Original läuft mit 25-30)'; psp='PSP-Inhalte freischalten (Autos, Arenen, Koop)';
         pad='Controller'; inv='Rechten Stick umkehren'; play='SPIELEN'; import='ISO importieren...'; quit='Beenden'; none='Importiere deine Spiel-ISO, um zu beginnen';
         eu='Europa (6 Sprachen)'; us='USA / Lateinamerika (Englisch)'; isofilter='Disc-Abbild (*.iso)|*.iso'; installing='Installation - Fenster nicht schließen';
         done='Fertig. Du kannst spielen.'; failed='Die Installation ist fehlgeschlagen. Siehe Protokoll.'; close='Schließen'; steps=@('Konverter wird geladen','Werkzeuge werden geladen (~1 GB)','Korrekturen werden angewendet','Konverter wird gebaut','Disc wird erkannt','Disc wird gelesen','Spielcode wird übersetzt','Spiel wird getestet','Grafikprogramme','Spiel wird kompiliert','Optionen werden vorbereitet','Fertig'); elapsed='Zeit'; cancel='Abbrechen'; cancelled='Installation abgebrochen. Der nächste Import beginnt von vorn.'; del='Löschen'; delask='Diese Version löschen?

Ja: das konvertierte Spiel wird entfernt, deine Spielstände bleiben erhalten.
Nein: alles wird gelöscht, auch die Spielstände.'; err='Die Installation konnte nicht starten:'; invs=@('Nein','Horizontal','Vertikal','Beide') }
 it = @{ title='Crash Tag Team Racing - PC'; ui='Lingua del launcher e del menu F1'; ver='Versione'; game='Lingua del gioco'; video='Immagine'; scale='Risoluzione interna';
         look="Stile dell'immagine"; vsync='Sincronizzazione verticale'; full='Schermo intero'; api='API grafica';
         reshade='Miglioramento grafico ReShade'; perf='Correzione prestazioni dei menu'; extras='Extra';
         fps="FPS raddoppiati (l'originale va a 25-30)"; psp='Sblocca contenuti PSP (auto, arene, cooperativa)';
         pad='Controller'; inv='Inverti stick destro'; play='GIOCA'; import='Importa ISO...'; quit='Esci'; none='Importa la tua ISO del gioco per iniziare';
         eu='Europa (6 lingue)'; us='USA / America Latina (inglese)'; isofilter='Immagine disco (*.iso)|*.iso'; installing='Installazione - non chiudere questa finestra';
         done='Fatto. Puoi giocare.'; failed="L'installazione non è riuscita. Vedi il registro."; close='Chiudi'; steps=@('Download del convertitore','Download degli strumenti (~1 GB)','Applicazione delle correzioni','Compilazione del convertitore','Riconoscimento del disco','Lettura del disco','Traduzione del codice del gioco','Prova del gioco','Programmi grafici','Compilazione del gioco','Preparazione delle opzioni','Fatto'); elapsed='Tempo'; cancel='Annulla'; cancelled="Installazione annullata. La prossima importazione riparte da zero."; del='Elimina'; delask="Eliminare questa versione?

Sì: il gioco convertito viene rimosso e i salvataggi restano.
No: viene rimosso tutto, anche i salvataggi."; err="Impossibile avviare l'installazione:"; invs=@('No','Orizzontale','Verticale','Entrambi') }
 pt = @{ title='Crash Tag Team Racing - PC'; ui='Idioma do launcher e do menu F1'; ver='Versão'; game='Idioma do jogo'; video='Imagem'; scale='Resolução interna';
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

# Starts game $g with the saved settings ($cfg and its keys.ini): the Play button after saving them, and -Play on its own
function Start-Game($g) {
    $gameDir = Join-Path $Root "games\$($g.name)"
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
    [void][Diagnostics.Process]::Start($psi)
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
Update-SavesFolder
Update-GameExe
if ($Play -and $Games.Count -gt 0) {
    $g = @($Games | Where-Object { $_.name -eq [string]$cfg.version })[0]
    if (-not $g) { $g = $Games[0] }
    Start-Game $g
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
Add-Label 'scale'; $cScale = Add-Combo @('1x (PS2)', '2x', '3x', '4x')
Add-Label 'look';  $cLook  = Add-Combo ($Looks | ForEach-Object { $_[1] })
Add-Label 'api';   $cApi   = Add-Combo @('Vulkan', 'Direct3D 12')
$script:y += 2
$kVsync = Add-Check 'vsync'; $kFull = Add-Check 'full'; $kReshade = Add-Check 'reshade'
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
$Version = 'v1.1.0'   # this package's release (v1.0.0 was the first)
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
    $kReshade.Visible = $showReshade
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
    foreach ($c in @($cVer, $cGame, $cScale, $cLook, $cApi, $kVsync, $kFull, $kReshade, $kFps, $kPsp, $bPlay)) { $c.Enabled = $has }
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
    $sc = 2; if ($ini.scale -match '^[1-4]$') { $sc = [int]$ini.scale }; $cScale.SelectedIndex = $sc - 1
    $lk = 0; if ($ini.look) { $i = [Array]::IndexOf(@($Looks | ForEach-Object { $_[0] -replace '_', '' }), ($ini.look -replace '[ _]', '').ToLower()); if ($i -ge 0) { $lk = $i } }; $cLook.SelectedIndex = $lk
    $kVsync.Checked = $(if ($ini.vsync) { $ini.vsync -match '^(on|1|yes)$' } else { $true })
    $kFps.Enabled = (Get-Item (Join-Path $Root "games\$($g.name)\patchsets\fps.txt") -ErrorAction SilentlyContinue).Length -gt 0
    $kPsp.Enabled = (Get-Item (Join-Path $Root "games\$($g.name)\patchsets\psp.txt") -ErrorAction SilentlyContinue).Length -gt 0
    $kReshade.Enabled = $cApi.SelectedIndex -eq 0
}
function Apply-Texts {
    $t = Lang
    $form.Text = $t.title
    foreach ($k in $labels.Keys) { if ($t.ContainsKey($k)) { $labels[$k].Text = $t[$k] } }
    $bPlay.Text = $t.play; $bImport.Text = $t.import; $bDel.Text = $t.del; $bQuit.Text = $t.quit
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
    $cfg.ui = $UiLangs[$cUi.SelectedIndex][0]; $cfg.version = $g.name
    if ($cGame.SelectedIndex -ge 0) { $cfg.game = [int]@($g.languages)[$cGame.SelectedIndex] }
    $cfg.api = $(if ($cApi.SelectedIndex -eq 1) { 'dx12' } else { 'vulkan' })
    $cfg.reshade = $kReshade.Checked; $cfg.fps = $kFps.Checked; $cfg.psp = $kPsp.Checked; $cfg.full = $kFull.Checked
    [IO.File]::WriteAllText($CfgFile, ($cfg | ConvertTo-Json), (New-Object Text.UTF8Encoding $false))
    Start-Game $g
    $form.Close()
})

[void]$form.ShowDialog()
