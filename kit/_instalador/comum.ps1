# gw2-facetado: funções usadas pelo instalar.ps1 e pelo desinstalar.ps1.
# Shared helpers for instalar.ps1 / desinstalar.ps1.
#
# O que este código faz / what this code does:
#   - procura a pasta do Guild Wars 2 lendo, sem alterar nada: atalhos do jogo,
#     a lista de programas instalados, lugares comuns e bibliotecas da Steam;
#     se não achar, abre uma janela para você escolher
#   - os caminhos gravados no settings.json são relativos à pasta do jogo
#     ("addons/CustomCursors/cursors/gw2-facetado/..."), então funcionam
#     em qualquer PC, esteja o jogo onde estiver
#   - lê e grava SÓ addons\CustomCursors\settings.json, sempre com backup antes
#   - copia/remove SÓ a pasta addons\CustomCursors\cursors\gw2-facetado
# Nada é baixado, nada é enviado, nada roda como administrador.

$ErrorActionPreference = 'Stop'
$PT = (Get-Culture).Name -like 'pt*'
$PACK_REL = 'addons/CustomCursors/cursors/gw2-facetado'

function T([string]$pt, [string]$en) { if ($PT) { $pt } else { $en } }

function Say([string]$pt, [string]$en, [string]$cor = 'Gray') {
    Write-Host (T $pt $en) -ForegroundColor $cor
}

function Ask-YesNo([string]$pt, [string]$en) {
    if ($script:SemPerguntas) { return $true }
    $r = Read-Host ((T $pt $en) + (T ' (S/N)' ' (Y/N)'))
    return $r -match '^\s*[sSyY]'
}

function Stop-Kit([string]$pt, [string]$en) {
    Say $pt $en 'Red'
    exit 1
}

function Test-GameDir([string]$d) {
    return ($d -and (Test-Path -LiteralPath (Join-Path $d 'Gw2-64.exe')))
}

# Lê atalhos .lnk (só leitura) e devolve a pasta de quem aponta para Gw2-64.exe.
# Reads .lnk shortcuts (read only) and returns the folder of those pointing to Gw2-64.exe.
function Get-ShortcutGameDirs([string[]]$dirs) {
    $sh = New-Object -ComObject WScript.Shell
    foreach ($d in $dirs) {
        if (-not $d -or -not (Test-Path -LiteralPath $d)) { continue }
        foreach ($l in (Get-ChildItem -LiteralPath $d -Recurse -Filter *.lnk -ErrorAction SilentlyContinue)) {
            try { $t = $sh.CreateShortcut($l.FullName).TargetPath } catch { continue }
            if ($t -match '\\Gw2(-64)?\.exe$') { Split-Path $t -Parent }
        }
    }
}

function Get-GameDirCandidates {
    $c = New-Object System.Collections.Generic.List[string]
    # 1. o kit foi extraído dentro da pasta do jogo? / kit extracted inside the game folder?
    $d = $PSScriptRoot
    while ($d) { $c.Add($d); $d = Split-Path $d -Parent }
    # 2. atalhos do jogo: área de trabalho, menu Iniciar, barra de tarefas
    #    game shortcuts: desktop, Start menu, taskbar
    $lnk = @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('CommonDesktopDirectory'),
             [Environment]::GetFolderPath('StartMenu'), [Environment]::GetFolderPath('CommonStartMenu'),
             (Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'))
    foreach ($x in (Get-ShortcutGameDirs $lnk)) { $c.Add($x) }
    # 3. lista de programas instalados do Windows (só leitura) / Windows installed-programs list (read only)
    foreach ($k in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                     'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
                     'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')) {
        foreach ($e in (Get-ChildItem $k -ErrorAction SilentlyContinue)) {
            $p = Get-ItemProperty $e.PSPath -ErrorAction SilentlyContinue
            if ("$($p.DisplayName)" -like 'Guild Wars 2*') {
                if ($p.InstallLocation) { $c.Add($p.InstallLocation.TrimEnd('\')) }
                if ($p.DisplayIcon) { $c.Add((Split-Path ($p.DisplayIcon -replace '"|,\d+$', '') -Parent)) }
            }
        }
    }
    # 4. lugares comuns / common install locations
    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ($root) { $c.Add((Join-Path $root 'Guild Wars 2')) }
    }
    foreach ($drv in (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
        foreach ($sub in @('Guild Wars 2', 'Games\Guild Wars 2', 'Games\GW2\Guild Wars 2', 'Program Files\Guild Wars 2')) {
            $c.Add((Join-Path $drv.Root $sub))
        }
    }
    # 5. bibliotecas da Steam (só leitura) / Steam libraries (read only)
    try {
        $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath
        $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
        $libs = @($steam)
        if (Test-Path -LiteralPath $vdf) {
            foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $libs += $m.Groups[1].Value -replace '\\\\', '\'
            }
        }
        foreach ($l in $libs) { $c.Add((Join-Path $l 'steamapps\common\Guild Wars 2')) }
    } catch { }
    return $c | Where-Object { Test-GameDir $_ } | Select-Object -Unique
}

function Select-GameDir([string]$given) {
    if ($given) {
        if (Test-GameDir $given) { return (Resolve-Path -LiteralPath $given).Path }
        Stop-Kit "Não achei Gw2-64.exe em: $given" "Gw2-64.exe not found in: $given"
    }
    foreach ($d in (Get-GameDirCandidates)) {
        if (Ask-YesNo "Pasta do jogo encontrada: $d`nUsar esta?" "Game folder found: $d`nUse this one?") { return $d }
    }
    if ($script:SemPerguntas) { Stop-Kit 'Pasta do jogo não encontrada.' 'Game folder not found.' }
    Say 'Escolha a pasta do Guild Wars 2 (a que tem Gw2-64.exe).' 'Pick the Guild Wars 2 folder (the one with Gw2-64.exe).' 'Yellow'
    Add-Type -AssemblyName System.Windows.Forms
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = T 'Pasta do Guild Wars 2 (com Gw2-64.exe)' 'Guild Wars 2 folder (with Gw2-64.exe)'
    if ($dlg.ShowDialog() -eq 'OK' -and (Test-GameDir $dlg.SelectedPath)) { return $dlg.SelectedPath }
    Stop-Kit 'Pasta inválida ou cancelada. Nada foi alterado.' 'Invalid folder or cancelled. Nothing was changed.'
}

function Assert-GameClosed {
    if (Get-Process -Name 'Gw2-64', 'Gw2' -ErrorAction SilentlyContinue) {
        Stop-Kit 'Feche o Guild Wars 2 antes. Nada foi alterado.' 'Close Guild Wars 2 first. Nothing was changed.'
    }
}

function Get-SettingsPath([string]$game) {
    $p = Join-Path $game 'addons\CustomCursors\settings.json'
    if (-not (Test-Path -LiteralPath $p)) {
        Stop-Kit ("Não achei addons\CustomCursors\settings.json.`n" +
                  "1) Instale o addon Custom Cursors pela biblioteca do Nexus.`n" +
                  "2) Abra o jogo uma vez e feche. Depois rode o instalador de novo.") `
                 ("addons\CustomCursors\settings.json not found.`n" +
                  "1) Install the Custom Cursors addon from the Nexus library.`n" +
                  "2) Start the game once and close it. Then run the installer again.")
    }
    return $p
}

function Read-Settings([string]$p) {
    try { return (Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json) }
    catch { Stop-Kit "O settings.json não pôde ser lido: $($_.Exception.Message)" "settings.json could not be read: $($_.Exception.Message)" }
}

function Backup-Settings([string]$p) {
    $b = "$p.backup-gw2-facetado-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
    Copy-Item -LiteralPath $p -Destination $b
    return $b
}

function Write-Settings($cfg, [string]$p, [string]$backup) {
    $json = $cfg | ConvertTo-Json -Depth 10
    [IO.File]::WriteAllText($p, $json, (New-Object System.Text.UTF8Encoding $false))  # UTF-8 sem BOM
    try { $null = Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch {
        Copy-Item -LiteralPath $backup -Destination $p -Force
        Stop-Kit 'Falha ao gravar; o backup foi restaurado.' 'Write failed; the backup was restored.'
    }
}

function Set-CursorEntry($entry, [int]$fmt, [string]$path, [int]$size, [int]$hx, [int]$hy) {
    foreach ($kv in @(@('file_format', $fmt), @('file_path', $path), @('height', $size),
                      @('hotspot_x', $hx), @('hotspot_y', $hy), @('width', $size))) {
        if ($entry.PSObject.Properties[$kv[0]]) { $entry.($kv[0]) = $kv[1] }
        else { $entry | Add-Member -NotePropertyName $kv[0] -NotePropertyValue $kv[1] }
    }
}
