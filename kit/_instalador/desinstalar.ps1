# gw2-facetado: desinstalador. / uninstaller.
#
# Volta ao padrão do jogo SÓ os cursores que apontam para a pasta gw2-facetado
# (outros cursores que você configurou ficam como estão) e, se você quiser,
# apaga a pasta addons\CustomCursors\cursors\gw2-facetado.
# Resets ONLY cursors pointing to the gw2-facetado folder, then optionally deletes it.
param(
    [string]$PastaJogo = '',
    [switch]$SemPerguntas,
    [switch]$ManterPasta
)
. (Join-Path $PSScriptRoot 'comum.ps1')

Say "`n=== gw2-facetado: desinstalar ===`n" "`n=== gw2-facetado: uninstall ===`n" 'Cyan'

$game = Select-GameDir $PastaJogo
Assert-GameClosed
$settings = Get-SettingsPath $game
$cfg = Read-Settings $settings

$nossos = @()
foreach ($secao in @('cursors', 'special_cursors')) {
    if ($cfg.PSObject.Properties[$secao]) {
        $nossos += @($cfg.$secao) | Where-Object { "$($_.file_path)" -like "$PACK_REL/*" }
    }
}
$pasta = Join-Path $game ($PACK_REL -replace '/', '\')

Say "Cursores do gw2-facetado em uso: $($nossos.Count)" "gw2-facetado cursors in use: $($nossos.Count)"
if ($nossos.Count -eq 0 -and -not (Test-Path -LiteralPath $pasta)) {
    Say 'Nada para desinstalar.' 'Nothing to uninstall.' 'Green'
    exit 0
}
if (-not (Ask-YesNo 'Voltar esses cursores ao padrão do jogo?' 'Reset these cursors to the game default?')) {
    Stop-Kit 'Cancelado. Nada foi alterado.' 'Cancelled. Nothing was changed.'
}

if ($nossos.Count -gt 0) {
    $backup = Backup-Settings $settings
    Say "Backup: $backup" "Backup: $backup" 'DarkGray'
    foreach ($e in $nossos) { Set-CursorEntry $e 0 '' 0 0 0 }
    Write-Settings $cfg $settings $backup
}

if (-not $ManterPasta -and (Test-Path -LiteralPath $pasta)) {
    if (Ask-YesNo "Apagar também a pasta $pasta ?" "Also delete the folder $pasta ?") {
        try { Remove-Item -LiteralPath $pasta -Recurse -Force }
        catch { Say "Não deu para apagar a pasta (está aberta em algum programa?). Apague à mão: $pasta" "Could not delete the folder (open in another program?). Delete it by hand: $pasta" 'Yellow' }
    }
}
Say "`nPronto." "`nDone." 'Green'
