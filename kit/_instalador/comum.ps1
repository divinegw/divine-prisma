# gw2-facetado: funções usadas pela janela (janela.ps1) e pelos scripts de linha de comando.
# Shared helpers for janela.ps1 / instalar.ps1 / desinstalar.ps1.
#
# O que este código faz / what this code does:
#   - procura a pasta do Guild Wars 2 lendo, sem alterar nada: atalhos do jogo,
#     a lista de programas instalados, lugares comuns e bibliotecas da Steam
#   - os caminhos gravados no settings.json são relativos à pasta do jogo
#     ("addons/CustomCursors/cursors/gw2-facetado/..."), então funcionam
#     em qualquer PC, esteja o jogo onde estiver
#   - lê e grava SÓ addons\CustomCursors\settings.json, sempre com backup antes
#     (se o arquivo ainda não existe, cria um novo)
#   - copia/remove SÓ a pasta addons\CustomCursors\cursors\gw2-facetado
# Nada é baixado, nada é enviado, nada roda como administrador.

$ErrorActionPreference = 'Stop'
$PT = (Get-Culture).Name -like 'pt*'
$PACK_REL = 'addons/CustomCursors/cursors/gw2-facetado'
$KIT_DIR = Split-Path $PSScriptRoot -Parent
$PACK_SRC = Join-Path $KIT_DIR 'gw2-facetado'
$CORES = @('roxo', 'ciano', 'dourado', 'prata', 'rosa', 'verde', 'vermelho')
$TAMANHOS = @(32, 48, 64, 96, 128)
# Sem halo (contraste Desligado) o desenho ocupa o quadro todo; com halo (Baixo/Alto)
# ocupa ~80% dele. Para o cursor ter o mesmo tamanho na tela nos três modos, os
# cursores do modo Desligado usam 80% do tamanho escolhido.
# Without halo the drawing fills the whole frame; with halo it fills ~80%.
$ESCALA_SEM_HALO = 0.8

# Saída: a janela troca $script:Saida por uma função que escreve na caixa de texto.
# Output: the window swaps $script:Saida for one that writes into its log box.
$script:Saida = { param($texto, $cor) Write-Host $texto -ForegroundColor $cor }

function T([string]$pt, [string]$en) { if ($PT) { $pt } else { $en } }

function Say([string]$pt, [string]$en, [string]$cor = 'Gray') {
    & $script:Saida (T $pt $en) $cor
}

# Erro que interrompe a operação; quem chama decide se fecha (linha de comando) ou mostra (janela).
# Error that stops the operation; the caller decides to exit (command line) or show it (window).
function Stop-Kit([string]$pt, [string]$en) {
    throw [System.InvalidOperationException]::new((T $pt $en))
}

function Test-GameDir([string]$d) {
    # caminho meio digitado ou inválido não é erro, só "não é a pasta do jogo"
    # a half-typed or invalid path is not an error, just "not the game folder"
    if (-not $d) { return $false }
    try { return [IO.File]::Exists([IO.Path]::Combine($d, 'Gw2-64.exe')) } catch { return $false }
}

# Lê atalhos .lnk (só leitura) e devolve a pasta de quem aponta para Gw2-64.exe.
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
    # 2. jogo aberto agora / game running right now
    foreach ($p in (Get-Process -Name 'Gw2-64' -ErrorAction SilentlyContinue)) {
        try { $c.Add((Split-Path $p.Path -Parent)) } catch { }
    }
    # 3. atalhos do jogo: área de trabalho, menu Iniciar, barra de tarefas
    $lnk = @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('CommonDesktopDirectory'),
             [Environment]::GetFolderPath('StartMenu'), [Environment]::GetFolderPath('CommonStartMenu'),
             (Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'))
    foreach ($x in (Get-ShortcutGameDirs $lnk)) { $c.Add($x) }
    # 4. lista de programas instalados do Windows (só leitura)
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
    # 5. lugares comuns
    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ($root) { $c.Add((Join-Path $root 'Guild Wars 2')) }
    }
    foreach ($drv in (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
        foreach ($sub in @('Guild Wars 2', 'Games\Guild Wars 2', 'Games\GW2\Guild Wars 2', 'Program Files\Guild Wars 2')) {
            $c.Add((Join-Path $drv.Root $sub))
        }
    }
    # 6. bibliotecas da Steam (só leitura)
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
    return @($c | Where-Object { Test-GameDir $_ } | ForEach-Object { (Resolve-Path -LiteralPath $_).Path.TrimEnd('\') } | Select-Object -Unique)
}

function Test-GameRunning {
    return [bool](Get-Process -Name 'Gw2-64', 'Gw2' -ErrorAction SilentlyContinue)
}

function Assert-GameClosed {
    if (Test-GameRunning) { Stop-Kit 'Feche o Guild Wars 2 antes. Nada foi alterado.' 'Close Guild Wars 2 first. Nothing was changed.' }
}

# O que já está instalado na pasta do jogo / what is already installed in the game folder
function Get-GameStatus([string]$game) {
    $addons = Join-Path $game 'addons'
    [pscustomobject]@{
        Nexus         = (Test-Path -LiteralPath (Join-Path $addons 'Nexus')) -or (Test-Path -LiteralPath (Join-Path $game 'd3d11.dll'))
        CustomCursors = [bool](Get-ChildItem -LiteralPath $addons -Filter 'customcursors*.dll' -ErrorAction SilentlyContinue)
        Settings      = Test-Path -LiteralPath (Join-Path $addons 'CustomCursors\settings.json')
        Pack          = Test-Path -LiteralPath (Join-Path $addons 'CustomCursors\cursors\gw2-facetado')
    }
}

function Get-SettingsPath([string]$game) {
    return (Join-Path $game 'addons\CustomCursors\settings.json')
}

# settings.json vazio no formato do Custom Cursors (o addon só cria o dele ao fechar o jogo).
# Empty Custom Cursors settings.json (the addon only writes its own when the game closes).
function New-Settings {
    [pscustomobject][ordered]@{
        cursors         = @()
        general         = [pscustomobject][ordered]@{ enable_combat_cursor = $false; enable_hotspot_preview = $false
                                                      enable_nexus_cursor = $false; link_width_height_inputs = $true
                                                      toggle_debug_window = $false }
        hidden_cursors  = @()
        special_cursors = @(foreach ($i in 10, 11) {
            [pscustomobject][ordered]@{ cursor_id = $i; file_format = 0; file_path = ''; height = 0; hotspot_x = 0; hotspot_y = 0; width = 0 }
        })
    }
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
    $null = New-Item -ItemType Directory -Force -Path (Split-Path $p -Parent)
    [IO.File]::WriteAllText($p, $json, (New-Object System.Text.UTF8Encoding $false))  # UTF-8 sem BOM
    try { $null = Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch {
        if ($backup) { Copy-Item -LiteralPath $backup -Destination $p -Force }
        Stop-Kit 'Falha ao gravar o settings.json; o backup foi restaurado.' 'Writing settings.json failed; the backup was restored.'
    }
}

function Set-CursorEntry($entry, [int]$fmt, [string]$path, [int]$size, [int]$hx, [int]$hy) {
    foreach ($kv in @(@('file_format', $fmt), @('file_path', $path), @('height', $size),
                      @('hotspot_x', $hx), @('hotspot_y', $hy), @('width', $size))) {
        if ($entry.PSObject.Properties[$kv[0]]) { $entry.($kv[0]) = $kv[1] }
        else { $entry | Add-Member -NotePropertyName $kv[0] -NotePropertyValue $kv[1] }
    }
}

# Lista do que vai para o settings.json / list of what goes into settings.json
#   $Cor          uma de $CORES
#   $Tamanho      tamanho do cursor COM halo (contraste Baixo/Alto); sem halo usa 80% disso
#   $AliadoVerde  seta de aliado (NPC amigo) verde em vez da cor escolhida
function Get-InstallPlan([string]$Cor, [int]$Tamanho, [bool]$AliadoVerde) {
    $hot = Get-Content -LiteralPath (Join-Path $PACK_SRC 'hotspots.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $mapa = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'mapa.json') -Raw -Encoding UTF8 | ConvertFrom-Json).cursores
    $aliado = if ($AliadoVerde) { 'verde' } else { $Cor }
    foreach ($m in $mapa) {
        $variante = $m.variante -replace '^cor', $Cor -replace '^aliado', $aliado
        $rel = "$($m.tipo)/gw2-$($m.tipo)-$variante-$Tamanho.png"
        $h = $hot.$rel
        if (-not $h) { Stop-Kit "Arquivo faltando no kit: $rel" "File missing from kit: $rel" }
        $lado = $Tamanho
        if ($m.modo -eq 'desligado') { $lado = [int][math]::Round($Tamanho * $ESCALA_SEM_HALO) }
        # o addon redimensiona o PNG mas não o ponto de clique: escala aqui
        # the addon resizes the PNG but not the hotspot: scale it here
        $k = $lado / $Tamanho
        [pscustomobject]@{
            id = [int64]$m.id; rel = $rel; lado = $lado; modo = $m.modo; nota = $m.nota
            hx = [int][math]::Round($h.hotspot[0] * $k); hy = [int][math]::Round($h.hotspot[1] * $k)
        }
    }
}

function Install-Pack([string]$game, [string]$Cor, [int]$Tamanho, [bool]$AliadoVerde) {
    if (-not (Test-Path -LiteralPath (Join-Path $PACK_SRC 'hotspots.json'))) {
        Stop-Kit 'A pasta _arquivos\gw2-facetado está faltando. Extraia o ZIP inteiro antes de instalar.' 'The _arquivos\gw2-facetado folder is missing. Extract the whole ZIP before installing.'
    }
    if (-not (Test-GameDir $game)) { Stop-Kit "Não achei Gw2-64.exe em: $game" "Gw2-64.exe not found in: $game" }
    Assert-GameClosed
    $st = Get-GameStatus $game
    if (-not $st.CustomCursors) {
        Stop-Kit ("O addon Custom Cursors não está instalado nessa pasta.`n" +
                  "1) Instale o Nexus (raidcore.gg/Nexus).`n2) Abra o jogo, aperte Ctrl+O, vá em Addons > Library e instale 'Custom Cursors'.`n3) Feche o jogo e instale este pack.") `
                 ("The Custom Cursors addon is not installed in that folder.`n" +
                  "1) Install Nexus (raidcore.gg/Nexus).`n2) Start the game, press Ctrl+O, go to Addons > Library and install 'Custom Cursors'.`n3) Close the game and install this pack.")
    }

    $plano = @(Get-InstallPlan $Cor $Tamanho $AliadoVerde)
    $settings = Get-SettingsPath $game
    $backup = $null
    if ($st.Settings) {
        $cfg = Read-Settings $settings
        $backup = Backup-Settings $settings
        Say "Backup: $backup" "Backup: $backup" 'DarkGray'
    } else {
        Say 'O Custom Cursors ainda não tinha settings.json: criando um novo.' 'Custom Cursors had no settings.json yet: creating a new one.' 'DarkGray'
        $cfg = New-Settings
    }

    # copia o pacote arquivo por arquivo, por cima do que já existir
    $dest = Join-Path $game ($PACK_REL -replace '/', '\')
    try {
        foreach ($f in (Get-ChildItem -LiteralPath $PACK_SRC -Recurse -File)) {
            $alvo = Join-Path $dest $f.FullName.Substring($PACK_SRC.Length).TrimStart('\')
            $null = New-Item -ItemType Directory -Force -Path (Split-Path $alvo -Parent)
            Copy-Item -LiteralPath $f.FullName -Destination $alvo -Force
        }
    } catch {
        Stop-Kit "Não consegui copiar os arquivos: $($_.Exception.Message)`nO settings.json não foi alterado." "Could not copy the files: $($_.Exception.Message)`nsettings.json was not changed."
    }

    # atualiza só as entradas do mapa / update only the mapped entries
    $lista = New-Object System.Collections.ArrayList
    foreach ($c in @($cfg.cursors)) { if ($c) { [void]$lista.Add($c) } }
    foreach ($p in $plano) {
        $e = $lista | Where-Object { [int64]$_.cursor_id -eq $p.id } | Select-Object -First 1
        if (-not $e) { $e = [pscustomobject]@{ cursor_id = $p.id }; [void]$lista.Add($e) }
        Set-CursorEntry $e 1 "$PACK_REL/$($p.rel)" $p.lado $p.hx $p.hy
    }
    $cfg.cursors = @($lista | Sort-Object { [int64]$_.cursor_id })
    Write-Settings $cfg $settings $backup

    $sem = ($plano | Where-Object modo -eq 'desligado' | Select-Object -First 1).lado
    Say ("Instalado: $Cor, $Tamanho px com halo / $sem px sem halo, $($plano.Count) cursores." +
         $(if ($AliadoVerde) { ' Seta de aliado: verde.' } else { '' })) `
        ("Installed: $Cor, $Tamanho px with halo / $sem px without, $($plano.Count) cursors." +
         $(if ($AliadoVerde) { ' Ally arrow: green.' } else { '' })) 'Green'
    return $plano
}

function Uninstall-Pack([string]$game, [bool]$ApagarPasta) {
    if (-not (Test-GameDir $game)) { Stop-Kit "Não achei Gw2-64.exe em: $game" "Gw2-64.exe not found in: $game" }
    Assert-GameClosed
    $settings = Get-SettingsPath $game
    $pasta = Join-Path $game ($PACK_REL -replace '/', '\')
    $n = 0
    if (Test-Path -LiteralPath $settings) {
        $cfg = Read-Settings $settings
        $nossos = @()
        foreach ($secao in @('cursors', 'special_cursors')) {
            if ($cfg.PSObject.Properties[$secao]) {
                $nossos += @($cfg.$secao) | Where-Object { "$($_.file_path)" -like "$PACK_REL/*" }
            }
        }
        $n = $nossos.Count
        if ($n -gt 0) {
            $backup = Backup-Settings $settings
            Say "Backup: $backup" "Backup: $backup" 'DarkGray'
            foreach ($e in $nossos) { Set-CursorEntry $e 0 '' 0 0 0 }
            Write-Settings $cfg $settings $backup
        }
    }
    Say "$n cursores voltaram ao padrão do jogo." "$n cursors reset to the game default." 'Green'
    if ($ApagarPasta -and (Test-Path -LiteralPath $pasta)) {
        try { Remove-Item -LiteralPath $pasta -Recurse -Force; Say "Pasta apagada: $pasta" "Folder deleted: $pasta" 'Green' }
        catch { Say "Não deu para apagar a pasta (está aberta em algum programa?). Apague à mão: $pasta" "Could not delete the folder (open in another program?). Delete it by hand: $pasta" 'Yellow' }
    }
    return $n
}
