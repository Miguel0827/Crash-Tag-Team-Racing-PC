# Crash Tag Team Racing PC - launcher (Windows PowerShell 5.1, WinForms). By NyxBorn.
# Imports the player's own disc image (tools\Instalar.ps1 builds the port) and starts the game with the chosen settings.
# Per game: <Root>\games\<name>\keys.ini (read by ps2run itself) and region.json (written by the installer).
param([string]$Root = '')
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

# ---------------------------------------------------------------- window
$form = New-Object Windows.Forms.Form
$form.StartPosition = 'CenterScreen'; $form.FormBorderStyle = 'FixedDialog'; $form.MaximizeBox = $false
$form.BackColor = [Drawing.Color]::FromArgb(24, 26, 34); $form.ForeColor = [Drawing.Color]::White; $form.Font = New-Object Drawing.Font('Segoe UI', 10)
$header = New-Object Windows.Forms.Label
$header.Text = 'CRASH TAG TEAM RACING'; $header.Font = New-Object Drawing.Font('Segoe UI Black', 20); $header.ForeColor = [Drawing.Color]::FromArgb(255, 160, 40)
$header.AutoSize = $false; $header.TextAlign = 'MiddleCenter'; $header.SetBounds(0, 10, 520, 44); $form.Controls.Add($header)
$sub = New-Object Windows.Forms.Label
$sub.Text = 'PC  ·  ps2-native-recomp'; $sub.ForeColor = [Drawing.Color]::Silver; $sub.AutoSize = $false; $sub.TextAlign = 'MiddleCenter'; $sub.SetBounds(0, 52, 520, 22); $form.Controls.Add($sub)

$script:y = 86
$labels = @{}
function Add-Label([string]$key) { $l = New-Object Windows.Forms.Label; $l.SetBounds(24, $script:y + 3, 250, 24); $l.ForeColor = [Drawing.Color]::Gainsboro; $form.Controls.Add($l); $script:labels[$key] = $l }
function Add-Combo($items) { $c = New-Object Windows.Forms.ComboBox; $c.DropDownStyle = 'DropDownList'; $c.SetBounds(280, $script:y, 220, 26); foreach ($i in $items) { [void]$c.Items.Add($i) }; $form.Controls.Add($c); $script:y += 32; $c }
function Add-Check([string]$key) { $c = New-Object Windows.Forms.CheckBox; $c.SetBounds(24, $script:y, 480, 26); $c.ForeColor = [Drawing.Color]::White; $form.Controls.Add($c); $script:labels[$key] = $c; $script:y += 30; $c }
function Add-Section([string]$key) { $l = New-Object Windows.Forms.Label; $l.SetBounds(16, $script:y + 4, 480, 24); $l.Font = New-Object Drawing.Font('Segoe UI Semibold', 11); $l.ForeColor = [Drawing.Color]::FromArgb(255, 190, 90); $form.Controls.Add($l); $script:labels[$key] = $l; $script:y += 30 }

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
Add-Section 'pad'
Add-Label 'inv';   $cInv   = Add-Combo @('-', '-', '-', '-')
$script:y += 12
$note = New-Object Windows.Forms.Label; $note.SetBounds(16, $script:y - 6, 488, 20); $note.ForeColor = [Drawing.Color]::FromArgb(255, 190, 90); $note.TextAlign = 'MiddleCenter'; $form.Controls.Add($note)
$script:y += 16
$bPlay = New-Object Windows.Forms.Button; $bPlay.SetBounds(16, $script:y, 196, 48); $bPlay.Font = New-Object Drawing.Font('Segoe UI Black', 14)
$bPlay.BackColor = [Drawing.Color]::FromArgb(255, 150, 30); $bPlay.ForeColor = [Drawing.Color]::Black; $bPlay.FlatStyle = 'Flat'; $form.Controls.Add($bPlay)
$bImport = New-Object Windows.Forms.Button; $bImport.SetBounds(222, $script:y + 8, 120, 32); $bImport.FlatStyle = 'Flat'; $bImport.ForeColor = [Drawing.Color]::White; $form.Controls.Add($bImport)
$bDel = New-Object Windows.Forms.Button; $bDel.SetBounds(350, $script:y + 8, 82, 32); $bDel.FlatStyle = 'Flat'; $bDel.ForeColor = [Drawing.Color]::FromArgb(255, 120, 100); $form.Controls.Add($bDel)
$bQuit = New-Object Windows.Forms.Button; $bQuit.SetBounds(440, $script:y + 8, 64, 32); $bQuit.FlatStyle = 'Flat'; $bQuit.ForeColor = [Drawing.Color]::Silver; $form.Controls.Add($bQuit)
$script:y += 60
$by = New-Object Windows.Forms.Label; $by.Text = 'By NyxBorn'; $by.Font = New-Object Drawing.Font('Segoe UI Semibold', 9); $by.ForeColor = [Drawing.Color]::FromArgb(150, 150, 170)
$by.AutoSize = $false; $by.TextAlign = 'MiddleCenter'; $by.SetBounds(0, $script:y, 520, 20); $form.Controls.Add($by)
$form.ClientSize = New-Object Drawing.Size(520, ($script:y + 28))
$form.AcceptButton = $bPlay; $form.CancelButton = $bQuit
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
    foreach ($c in @($cVer, $cGame, $cScale, $cLook, $cApi, $kVsync, $kFull, $kReshade, $kFps, $kPsp, $cInv, $bPlay)) { $c.Enabled = $has }
    $bDel.Visible = $has
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
    $inv = 0; if ($ini.rightinvert) { $inv = [Math]::Max(0, [Array]::IndexOf($InvWords, $ini.rightinvert.ToLower())) }; $cInv.SelectedIndex = $inv
    $kFps.Enabled = (Get-Item (Join-Path $Root "games\$($g.name)\patchsets\fps.txt") -ErrorAction SilentlyContinue).Length -gt 0
    $kPsp.Enabled = (Get-Item (Join-Path $Root "games\$($g.name)\patchsets\psp.txt") -ErrorAction SilentlyContinue).Length -gt 0
    $kReshade.Enabled = $cApi.SelectedIndex -eq 0
}
function Apply-Texts {
    $t = Lang
    $form.Text = $t.title
    foreach ($k in $labels.Keys) { if ($t.ContainsKey($k)) { $labels[$k].Text = $t[$k] } }
    $bPlay.Text = $t.play; $bImport.Text = $t.import; $bDel.Text = $t.del; $bQuit.Text = $t.quit
    $sel = $cInv.SelectedIndex; $cInv.Items.Clear(); foreach ($w in $t.invs) { [void]$cInv.Items.Add($w) }; $cInv.SelectedIndex = [Math]::Max(0, $sel)
    Fill-Versions
    if (-not (Current-Game)) { $note.Text = $t.none }
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
    $w.BackColor = [Drawing.Color]::FromArgb(24, 26, 34); $w.ForeColor = [Drawing.Color]::White; $w.ControlBox = $false; $w.Font = New-Object Drawing.Font('Segoe UI', 10)
    $stage = New-Object Windows.Forms.Label; $stage.SetBounds(12, 12, 560, 26); $stage.Font = New-Object Drawing.Font('Segoe UI Semibold', 12); $stage.ForeColor = [Drawing.Color]::FromArgb(255, 190, 90); $w.Controls.Add($stage)
    $clock = New-Object Windows.Forms.Label; $clock.SetBounds(580, 14, 128, 24); $clock.TextAlign = 'MiddleRight'; $clock.ForeColor = [Drawing.Color]::Silver; $w.Controls.Add($clock)
    $bar = New-Object Windows.Forms.ProgressBar; $bar.SetBounds(12, 44, 696, 26); $bar.Minimum = 0; $bar.Maximum = 100; $bar.Style = 'Continuous'; $w.Controls.Add($bar)
    $box = New-Object Windows.Forms.TextBox; $box.Multiline = $true; $box.ReadOnly = $true; $box.ScrollBars = 'Vertical'; $box.SetBounds(12, 82, 696, 306)
    $box.BackColor = [Drawing.Color]::Black; $box.ForeColor = [Drawing.Color]::LightGreen; $box.Font = New-Object Drawing.Font('Consolas', 9); $w.Controls.Add($box)
    $ok = New-Object Windows.Forms.Button; $ok.Text = $t.close; $ok.SetBounds(588, 396, 120, 36); $ok.Visible = $false; $ok.FlatStyle = 'Flat'
    $ok.BackColor = [Drawing.Color]::FromArgb(255, 150, 30); $ok.ForeColor = [Drawing.Color]::Black; $ok.Font = New-Object Drawing.Font('Segoe UI Semibold', 10); $w.Controls.Add($ok)
    $ok.Add_Click({ $w.Close() })
    # Cancel: the installer and everything it started stop; the next import of that version cleans up what was half made
    $stop = New-Object Windows.Forms.Button; $stop.Text = $t.cancel; $stop.SetBounds(12, 396, 120, 36); $stop.FlatStyle = 'Flat'; $stop.ForeColor = [Drawing.Color]::Silver; $w.Controls.Add($stop)
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
                $bar.Value = [Math]::Min(100, [int][Math]::Max($pct, [Math]::Min($next - 1, $script:creep)))
                $stage.Text = $t.steps[$step]
            } catch {}
        }
        if ($p.HasExited) {
            $timer.Stop(); $ok.Visible = $true; $stop.Visible = $false; $ok.Focus(); $w.ControlBox = $true
            if ($script:cancelled) { $w.Text = $t.cancelled; $stage.Text = $t.cancelled; $stage.ForeColor = [Drawing.Color]::Silver }
            elseif (Select-String -Path $log -Pattern '^LISTO' -Quiet) { $w.Text = $t.done; $stage.Text = $t.done; $bar.Value = 100 }
            else { $w.Text = $t.failed; $stage.Text = $t.failed; $stage.ForeColor = [Drawing.Color]::Tomato }
        }
    })
    $script:creep = 0
    $timer.Start()
    [void]$w.ShowDialog($form)
    $script:Games = Get-Games
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
    $cVer.SelectedIndex = -1
    Fill-Versions; Load-Game
})

$bPlay.Add_Click({
    $g = Current-Game; if (-not $g) { return }
    $gameDir = Join-Path $Root "games\$($g.name)"
    Set-IniLines (Join-Path $gameDir 'keys.ini') @{ scale = ($cScale.SelectedIndex + 1); look = $Looks[$cLook.SelectedIndex][0]; vsync = $(if ($kVsync.Checked) { 'on' } else { 'off' }); right_invert = $InvWords[$cInv.SelectedIndex] }
    $cfg.ui = $UiLangs[$cUi.SelectedIndex][0]; $cfg.version = $g.name
    if ($cGame.SelectedIndex -ge 0) { $cfg.game = [int]@($g.languages)[$cGame.SelectedIndex] }
    $cfg.api = $(if ($cApi.SelectedIndex -eq 1) { 'dx12' } else { 'vulkan' })
    $cfg.reshade = $kReshade.Checked; $cfg.fps = $kFps.Checked; $cfg.psp = $kPsp.Checked; $cfg.full = $kFull.Checked
    [IO.File]::WriteAllText($CfgFile, ($cfg | ConvertTo-Json), (New-Object Text.UTF8Encoding $false))
    # the patches of this run: wide screen always (it is in the converted program), the others as chosen
    $sets = Join-Path $gameDir 'patchsets'
    $parts = @('ws.txt'); if ($kFps.Checked -and $kFps.Enabled) { $parts += 'fps.txt' }; if ($kPsp.Checked -and $kPsp.Enabled) { $parts += 'psp.txt' }
    $text = ($parts | ForEach-Object { $f = Join-Path $sets $_; if (Test-Path $f) { [IO.File]::ReadAllText($f).TrimEnd() } } | Where-Object { $_ }) -join "`n"
    [IO.File]::WriteAllText((Join-Path $gameDir 'patches_run.txt'), $text + "`n", (New-Object Text.UTF8Encoding $false))
    $elf = "games/$($g.name)/patched/$($g.elf)"; if (-not (Test-Path (Join-Path $Root $elf))) { $elf = "games/$($g.name)/disc/$($g.elf)" }
    $argv = @($elf, '--disc', "games/$($g.name)/disc.iso", '--window', '--game-dir', "games/$($g.name)", '--memcard', "games/$($g.name)/memcard.ps2", '--patches', "games/$($g.name)/patches_run.txt")
    if ($g.widescreen) { $argv += '--widescreen' }
    if ($kFull.Checked) { $argv += '--fullscreen' }
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = Join-Path $Root "build\native-$($g.name)\ps2run.exe"; $psi.WorkingDirectory = $Root; $psi.UseShellExecute = $false
    $psi.Arguments = ($argv | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
    $ev = $psi.EnvironmentVariables
    $ev['PS2_LANGUAGE'] = [string]$cfg.game
    $ev['PS2_MENU_LANG'] = $cfg.ui
    $ev['PS2_GPU_BACKEND'] = $cfg.api
    if ($cfg.api -ne 'vulkan' -or -not $kReshade.Checked) { $ev['DISABLE_VK_LAYER_reshade_1'] = '1' }
    $ev['PS2_DMA_TIME'] = '120,16'   # the title and menus: GIF transfers take the console's time (always on)
    [void][Diagnostics.Process]::Start($psi)
    $form.Close()
})

[void]$form.ShowDialog()
