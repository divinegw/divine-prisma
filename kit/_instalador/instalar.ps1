# Divine Prisma: instalador de linha de comando (a janela, janela.ps1, faz o mesmo).
# Divine Prisma: command-line installer (the window, janela.ps1, does the same).
#
#   instalar.ps1 -Cor rosa [-Tamanho 48] [-AliadoVerde] [-PastaJogo "D:\Guild Wars 2"] [-SemPerguntas]
#
# Tamanho = cursor com halo (contraste Baixo/Alto); sem halo (Desligado) usa 80% disso.
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('roxo', 'ciano', 'dourado', 'prata', 'rosa', 'verde', 'vermelho')]
    [string]$Cor,
    [ValidateSet(32, 48, 64, 96, 128)]
    [int]$Tamanho = 48,
    [switch]$AliadoVerde,
    [switch]$Forcar,          # instala mesmo sem detectar o Custom Cursors / install even if Custom Cursors isn't detected
    [string]$PastaJogo = '',
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
        $r = Read-Host (T 'Instalar? (S/N)' 'Install? (Y/N)')
        if ($r -notmatch '^\s*[sSyY]') { Stop-Kit 'Cancelado. Nada foi alterado.' 'Cancelled. Nothing was changed.' }
    }
    $null = Install-Pack $game $Cor $Tamanho $AliadoVerde.IsPresent $Forcar.IsPresent
} catch {
    Say $_.Exception.Message $_.Exception.Message 'Red'
    exit 1
}
