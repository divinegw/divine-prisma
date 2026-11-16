# gw2-facetado: instalador para o addon Custom Cursors (Nexus).
# gw2-facetado: installer for the Custom Cursors addon (Nexus).
#
# Passos / steps:
#   1. acha a pasta do jogo e confere que o jogo está fechado
#   2. mostra o que vai mudar e pede confirmação
#   3. faz backup do settings.json
#   4. copia a pasta gw2-facetado para addons\CustomCursors\cursors\
#   5. aponta os cursores listados em mapa.json para os PNGs da cor escolhida
#      (só essas entradas mudam; o resto do settings.json fica como estava)
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('roxo', 'ciano', 'dourado', 'prata', 'rosa', 'verde', 'vermelho')]
    [string]$Cor,
    [ValidateSet(0, 32, 48, 64, 96, 128)]
    [int]$Tamanho = 0,
    [string]$PastaJogo = '',
    [switch]$SemPerguntas
)
. (Join-Path $PSScriptRoot 'comum.ps1')

$kit = Split-Path $PSScriptRoot -Parent
$packSrc = Join-Path $kit 'gw2-facetado'
if (-not (Test-Path -LiteralPath (Join-Path $packSrc 'hotspots.json'))) {
    Stop-Kit 'A pasta gw2-facetado do kit está faltando. Extraia o ZIP inteiro.' 'The kit''s gw2-facetado folder is missing. Extract the whole ZIP.'
}

Say "`n=== gw2-facetado: $Cor ===`n" "`n=== gw2-facetado: $Cor ===`n" 'Cyan'

$game = Select-GameDir $PastaJogo
Assert-GameClosed
$settings = Get-SettingsPath $game
$cfg = Read-Settings $settings

if ($Tamanho -eq 0) {
    $Tamanho = 48
    if (-not $SemPerguntas) {
        $r = Read-Host (T 'Tamanho em pixels: 32, 48, 64, 96 ou 128 (Enter = 48)' 'Size in pixels: 32, 48, 64, 96 or 128 (Enter = 48)')
        if ($r -match '^\s*(32|48|64|96|128)\s*$') { $Tamanho = [int]$Matches[1] }
    }
}

$hot = Get-Content -LiteralPath (Join-Path $packSrc 'hotspots.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$mapa = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'mapa.json') -Raw -Encoding UTF8 | ConvertFrom-Json).cursores

# monta a lista de mudanças / build the change list
$plano = foreach ($m in $mapa) {
    $variante = $m.variante -replace '^cor', $Cor
    $rel = "$($m.tipo)/gw2-$($m.tipo)-$variante-$Tamanho.png"
    $h = $hot.$rel
    if (-not $h) { Stop-Kit "Arquivo faltando no kit: $rel" "File missing from kit: $rel" }
    [pscustomobject]@{ id = [int64]$m.id; rel = $rel; hx = [int]$h.hotspot[0]; hy = [int]$h.hotspot[1]; nota = $m.nota }
}

Say "`nPasta do jogo: $game" "`nGame folder: $game"
Say "Cursores que vão mudar ($Tamanho px):" "Cursors that will change ($Tamanho px):"
foreach ($p in $plano) { Write-Host ("  {0,-11} {1,-48} {2}" -f $p.id, $p.rel, $p.nota) }
Say "`nOs outros cursores e as outras opções do addon não mudam." "`nOther cursors and addon options stay as they are."
if (-not (Ask-YesNo 'Instalar?' 'Install?')) { Stop-Kit 'Cancelado. Nada foi alterado.' 'Cancelled. Nothing was changed.' }

$backup = Backup-Settings $settings
Say "Backup: $backup" "Backup: $backup" 'DarkGray'

# copia o pacote arquivo por arquivo, por cima do que já existir (não apaga a pasta,
# que pode estar aberta no Explorer) / copy the pack file by file, overwriting
$dest = Join-Path $game ($PACK_REL -replace '/', '\')
try {
    foreach ($f in (Get-ChildItem -LiteralPath $packSrc -Recurse -File)) {
        $alvo = Join-Path $dest $f.FullName.Substring($packSrc.Length).TrimStart('\')
        $null = New-Item -ItemType Directory -Force -Path (Split-Path $alvo -Parent)
        Copy-Item -LiteralPath $f.FullName -Destination $alvo -Force
    }
} catch {
    Stop-Kit "Não consegui copiar os arquivos: $($_.Exception.Message)`nO settings.json não foi alterado." "Could not copy the files: $($_.Exception.Message)`nsettings.json was not changed."
}

# atualiza só as entradas do mapa / update only the mapped entries
$lista = New-Object System.Collections.ArrayList
foreach ($c in @($cfg.cursors)) { [void]$lista.Add($c) }
foreach ($p in $plano) {
    $e = $lista | Where-Object { [int64]$_.cursor_id -eq $p.id } | Select-Object -First 1
    if (-not $e) {
        # o addon ainda não viu esse cursor: cria a entrada / not seen by the addon yet: add it
        $e = [pscustomobject]@{ cursor_id = $p.id }
        [void]$lista.Add($e)
    }
    Set-CursorEntry $e 1 "$PACK_REL/$($p.rel)" $Tamanho $p.hx $p.hy
}
$cfg.cursors = @($lista | Sort-Object { [int64]$_.cursor_id })
Write-Settings $cfg $settings $backup

Say "`nPronto! Abra o jogo para ver os cursores." "`nDone! Start the game to see the cursors." 'Green'
Say 'Para desfazer: Desinstalar.bat' 'To undo: Desinstalar.bat (uninstall)' 'DarkGray'
