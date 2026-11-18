# gw2-facetado: desinstalador de linha de comando (a janela, janela.ps1, faz o mesmo).
# Volta ao padrão do jogo SÓ os cursores que apontam para a pasta gw2-facetado
# (outros cursores que você configurou ficam como estão) e, se pedir, apaga a pasta.
# Resets ONLY cursors pointing to the gw2-facetado folder, then optionally deletes it.
#
#   desinstalar.ps1 [-PastaJogo "D:\Guild Wars 2"] [-ApagarPasta] [-SemPerguntas]
param(
    [string]$PastaJogo = '',
    [switch]$ApagarPasta,
    [switch]$SemPerguntas
)
. (Join-Path $PSScriptRoot 'comum.ps1')

try {
    $game = $PastaJogo
    if (-not $game) {
        $game = @(Get-GameDirCandidates) | Select-Object -First 1
        if (-not $game) { Stop-Kit 'Pasta do jogo não encontrada. Use -PastaJogo.' 'Game folder not found. Use -PastaJogo.' }
    }
    Say "Pasta do jogo: $game" "Game folder: $game"
    if (-not $SemPerguntas) {
        $r = Read-Host (T 'Desinstalar? (S/N)' 'Uninstall? (Y/N)')
        if ($r -notmatch '^\s*[sSyY]') { Stop-Kit 'Cancelado. Nada foi alterado.' 'Cancelled. Nothing was changed.' }
    }
    $null = Uninstall-Pack $game $ApagarPasta.IsPresent
} catch {
    Say $_.Exception.Message $_.Exception.Message 'Red'
    exit 1
}
