# Divine Prisma: janela do instalador (aberta pelo Instalar.bat).
# Divine Prisma: installer window (opened by Instalar.bat).
# Toda a parte que mexe em arquivos está em comum.ps1 (Install-Pack / Uninstall-Pack).
# Visual: paleta escura do Codex DIVINE (site da guilda): marinho, ouro e prata; controles em divine-ui.cs.
. (Join-Path $PSScriptRoot 'comum.ps1')
$ErrorActionPreference = 'Continue'

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -TypeDefinition ([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'divine-ui.cs'))) `
         -ReferencedAssemblies System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Nome público do pack (troque aqui para renomear a janela) / public pack name
$NOME_PACK = 'Divine Prisma'

$NOMES = [ordered]@{ roxo = (T 'Roxo' 'Purple'); ciano = (T 'Ciano' 'Cyan'); dourado = (T 'Dourado' 'Gold')
                     prata = (T 'Prata' 'Silver'); rosa = (T 'Rosa' 'Pink'); verde = (T 'Verde' 'Green')
                     vermelho = (T 'Vermelho' 'Red') }
# brilho da faixa do topo na cor escolhida / header glow per colour
$BRILHO = @{ roxo = '#8b5cf6'; ciano = '#22c3e6'; dourado = '#e2b254'; prata = '#c9ccd1'
             rosa = '#f0509b'; verde = '#6ad13a'; vermelho = '#e5534b' }
$P = [Divine.Pal]

# ---------------------------------------------------------------- fontes
# Bahnschrift condensada faz o papel da Mona Sans condensada do site (vem no Windows 10+).
$INSTALADAS = @{}
foreach ($f in (New-Object System.Drawing.Text.InstalledFontCollection).Families) { $INSTALADAS[$f.Name] = $true }
function New-Fonte([string[]]$familias, [float]$px, [string]$estilo = 'Regular') {
    foreach ($n in $familias) {
        if ($INSTALADAS[$n]) { return New-Object System.Drawing.Font($n, $px, [System.Drawing.FontStyle]$estilo, [System.Drawing.GraphicsUnit]::Pixel) }
    }
    return New-Object System.Drawing.Font('Segoe UI', $px, [System.Drawing.FontStyle]$estilo, [System.Drawing.GraphicsUnit]::Pixel)
}
$F_TITULO = New-Fonte @('Bahnschrift SemiBold Condensed', 'Segoe UI Semibold') 40
$F_SECAO = New-Fonte @('Bahnschrift SemiBold Condensed', 'Segoe UI Semibold') 19
$F_TXT = New-Fonte @('Segoe UI') 14
$F_TXT_B = New-Fonte @('Segoe UI Semibold', 'Segoe UI') 14
$F_BOTAO = New-Fonte @('Segoe UI Semibold', 'Segoe UI') 15
$F_MONO = New-Fonte @('Cascadia Mono', 'Consolas') 12
$F_MONO_P = New-Fonte @('Cascadia Mono', 'Consolas') 11

# PNG sem travar o arquivo / load a PNG without locking the file
function Get-Imagem([string]$p) {
    if (-not (Test-Path -LiteralPath $p)) { return $null }
    $ms = New-Object System.IO.MemoryStream (, [IO.File]::ReadAllBytes($p))
    return [System.Drawing.Image]::FromStream($ms)
}
function Get-Png([string]$tipo, [string]$variante, [int]$tam) {
    return Get-Imagem (Join-Path $PACK_SRC "$tipo\gw2-$tipo-$variante-$tam.png")
}

function New-Label($texto, $x, $y, $w, $h, $cor = $P::Soft, $f = $F_TXT) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $texto; $l.Location = "$x,$y"; $l.Size = "$w,$h"; $l.ForeColor = $cor; $l.Font = $f
    $l.BackColor = $P::Bg; $l.UseMnemonic = $false
    return $l
}

function New-Botao($texto, $x, $y, $w, $h, $tipo = 'Secondary') {
    $b = New-Object Divine.DvButton
    $b.Text = $texto; $b.Location = "$x,$y"; $b.Size = "$w,$h"; $b.Font = $F_BOTAO; $b.Kind = $tipo
    return $b
}

# título de passo: número em ouro + nome em caixa alta (como os capítulos dos guias)
function Add-Secao($num, $texto, $x, $y, $w = 400) {
    $form.Controls.Add((New-Label $num $x $y 30 26 $P::GoldText $F_SECAO))
    $form.Controls.Add((New-Label $texto.ToUpper() ($x + 28) $y $w 26 $P::Text $F_SECAO))
}

# ---------------------------------------------------------------- janela
$W = 780
$form = New-Object System.Windows.Forms.Form
$form.Text = "$NOME_PACK · " + (T 'instalador' 'installer')
$form.ClientSize = "$W,716"; $form.StartPosition = 'CenterScreen'; $form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false; $form.BackColor = $P::Bg; $form.ForeColor = $P::Text; $form.Font = $F_TXT
$emblema = Get-Imagem (Join-Path $PSScriptRoot 'emblema.png')
if ($emblema) { try { $form.Icon = [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap $emblema, 32, 32).GetHicon()) } catch { } }
$form.Add_HandleCreated({ [Divine.Gfx]::DarkTitleBar($form.Handle, $P::Bg) })

# ---------------------------------------------------------------- topo
$topo = New-Object Divine.DvHeader
$topo.Location = '0,0'; $topo.Size = "$W,136"
$topo.Emblem = $emblema
$topo.Title = $NOME_PACK.ToUpper()
$topo.Subtitle = T 'Cursores prismáticos para Guild Wars 2 · addon Custom Cursors (Nexus)' 'Prismatic cursors for Guild Wars 2 · Custom Cursors addon (Nexus)'
$topo.Note = T 'Feche o jogo antes de instalar.' 'Close the game before installing.'
$topo.TitleFont = $F_TITULO; $topo.SubFont = $F_TXT; $topo.NoteFont = $F_TXT_B
$form.Controls.Add($topo)

$M = 28            # margem / margin
$L = $W - 2 * $M   # largura útil / usable width

# ---------------------------------------------------------------- 1. pasta do jogo
Add-Secao '01' (T 'Pasta do Guild Wars 2' 'Guild Wars 2 folder') $M 152
$campo = New-Object Divine.DvCard
$campo.Location = "$M,182"; $campo.Size = "$($L - 136),40"; $campo.BackColor = $P::Surface; $campo.Border = $P::LineStrong
$tbPasta = New-Object System.Windows.Forms.TextBox
$tbPasta.BorderStyle = 'None'; $tbPasta.BackColor = $P::Surface; $tbPasta.ForeColor = $P::Text; $tbPasta.Font = $F_TXT
$tbPasta.Location = '14,11'; $tbPasta.Size = "$($L - 136 - 60),20"
$campo.Controls.Add($tbPasta)
# outras pastas achadas: setinha que abre a lista / other folders found: chevron that opens the list
$btLista = New-Object Divine.DvButton
$btLista.Kind = 'Ghost'; $btLista.Text = [string][char]0x25BE; $btLista.Font = $F_TXT; $btLista.Radius = 6
$btLista.Location = "$($L - 136 - 38),6"; $btLista.Size = '30,28'; $btLista.Visible = $false
$campo.Controls.Add($btLista)
$mnPastas = New-Object System.Windows.Forms.ContextMenuStrip
$mnPastas.BackColor = $P::Surface2; $mnPastas.ForeColor = $P::Text; $mnPastas.ShowImageMargin = $false; $mnPastas.Font = $F_TXT
$btLista.Add_Click({ $mnPastas.Show($campo, 0, $campo.Height + 2) })
$form.Controls.Add($campo)
$btProcurar = New-Botao (T 'Procurar...' 'Browse...') ($W - $M - 126) 182 126 40
$form.Controls.Add($btProcurar)
$stPasta = New-Object Divine.DvStatus
$stPasta.Location = "$M,230"; $stPasta.Size = "$L,20"; $stPasta.Font = $F_TXT; $stPasta.BackColor = $P::Bg
$form.Controls.Add($stPasta)

# ---------------------------------------------------------------- 2. cor
Add-Secao '02' (T 'Cor' 'Colour') $M 264
$script:Cor = 'dourado'
$botoesCor = @{}
$x = $M
foreach ($c in $NOMES.Keys) {
    # seta + mão de cada cor num fundo transparente / arrow + hand of each colour
    $bmp = New-Object System.Drawing.Bitmap 84, 44
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = 'HighQualityBicubic'
    foreach ($par in @(@('seta', 0), @('mao-aberta', 40))) {
        $im = Get-Png $par[0] "$c-brilho" 48
        if ($im) { $g.DrawImage($im, $par[1], 0, 44, 44); $im.Dispose() }
    }
    $g.Dispose()
    $rb = New-Object Divine.DvButton
    $rb.Kind = 'Option'; $rb.Group = 'cor'; $rb.Picture = $bmp; $rb.Text = $NOMES[$c]; $rb.Tag = $c
    $rb.Font = $F_TXT; $rb.Location = "$x,294"; $rb.Size = '98,86'
    $rb.Add_CheckedChanged({ if ($this.Checked) { $script:Cor = $this.Tag; Update-Previa } })
    $form.Controls.Add($rb); $botoesCor[$c] = $rb
    $x += 104
}

# ---------------------------------------------------------------- 3. tamanho
Add-Secao '03' (T 'Tamanho' 'Size') $M 398
$script:Tamanho = 48
$x = $M
foreach ($t in $TAMANHOS) {
    $rb = New-Object Divine.DvButton
    $rb.Kind = 'Option'; $rb.Group = 'tam'; $rb.Text = "$t px"; $rb.Tag = $t; $rb.Font = $F_MONO
    $rb.Location = "$x,428"; $rb.Size = '62,36'
    $form.Controls.Add($rb)
    if ($t -eq 48) { $rb.Checked = $true }
    $rb.Add_CheckedChanged({ if ($this.Checked) { $script:Tamanho = [int]$this.Tag; Update-Previa } })
    $x += 67
}
$form.Controls.Add((New-Label (T '48 px é o padrão. Telas grandes ou interface maior: 64 px.' '48 px is the default. Big screens or larger UI: 64 px.') $M 472 370 22 $P::Mute))
$tgAliado = New-Object Divine.DvToggle
$tgAliado.Location = "$M,502"; $tgAliado.Size = '340,44'; $tgAliado.Font = $F_TXT; $tgAliado.BackColor = $P::Bg
$tgAliado.Text = T 'Seta de aliado (NPC amigo) em verde, como no jogo.' 'Ally arrow (friendly NPC) in green, like the game.'
$tgAliado.Add_CheckedChanged({ Update-Previa })
$form.Controls.Add($tgAliado)

# prévia em tamanho real / real-size preview
$PX = 404; $PW = $W - $M - $PX
$lbPrevia = New-Label '' $PX 404 $PW 20 $P::Mute $F_MONO_P
$form.Controls.Add($lbPrevia)
$pvPrevia = New-Object Divine.DvImage
$pvPrevia.Location = "$PX,428"; $pvPrevia.Size = "$PW,118"
$form.Controls.Add($pvPrevia)
$ROTULOS = @((T 'SETA' 'ARROW'), (T 'MÃO' 'HAND'), (T 'FALA' 'TALK'), (T 'ALIADO' 'ALLY'), (T 'INIMIGO' 'ENEMY'))
function Update-Previa {
    $t = $script:Tamanho; $c = $script:Cor
    $aliado = if ($tgAliado.Checked) { 'verde' } else { $c }
    $w = $pvPrevia.Width; $h = $pvPrevia.Height
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    [Divine.Gfx]::Smooth($g)
    # chão de jogo em ardósia azulada, para julgar o contraste / slate "game ground"
    $fundo = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle 0, 0, $w, $h),
             [System.Drawing.ColorTranslator]::FromHtml('#33465e'), [System.Drawing.ColorTranslator]::FromHtml('#1b2433'), 90)
    $g.FillRectangle($fundo, 0, 0, $w, $h); $fundo.Dispose()
    $lado = [math]::Min($t, 76)
    $slot = $w / 5
    $itens = @(@('seta', "$c-brilho"), @('mao-aberta', "$c-brilho"), @('fala', "$c-brilho"), @('seta', "$aliado-brilho"), @('seta', 'vermelho-brilho'))
    $pincel = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(170, 228, 230, 236))
    $fmt = New-Object System.Drawing.StringFormat; $fmt.Alignment = 'Center'
    for ($i = 0; $i -lt 5; $i++) {
        $im = Get-Png $itens[$i][0] $itens[$i][1] $t
        if ($im) { $g.DrawImage($im, [float]($slot * $i + ($slot - $lado) / 2), [float](8 + (80 - $lado) / 2), [float]$lado, [float]$lado); $im.Dispose() }
        $rc = New-Object System.Drawing.RectangleF ([float]($slot * $i)), ([float]($h - 22)), ([float]$slot), ([float]16)
        $g.DrawString($ROTULOS[$i], $F_MONO_P, $pincel, $rc, $fmt)
    }
    $pincel.Dispose(); $g.Dispose()
    $pvPrevia.Image = $bmp
    $lbPrevia.Text = if ($t -gt 76) { T "PRÉVIA REDUZIDA · NO JOGO: $t PX" "SCALED-DOWN PREVIEW · IN GAME: $t PX" } else { T 'PRÉVIA · TAMANHO REAL' 'PREVIEW · ACTUAL SIZE' }

    # topo: a seta escolhida, grande, com o brilho da cor / header showcase
    $topo.Glow = [System.Drawing.ColorTranslator]::FromHtml($BRILHO[$c])
    $topo.SetShowcase((Get-Png 'seta' "$c-brilho" 128))
}

# ---------------------------------------------------------------- botões e registro
$btInstalar = New-Botao (T 'Instalar' 'Install') $M 562 236 46 'Primary'
$form.Controls.Add($btInstalar)
$btDesinstalar = New-Botao (T 'Desinstalar' 'Uninstall') ($M + 246) 562 150 46
$form.Controls.Add($btDesinstalar)
$btFechar = New-Botao (T 'Fechar' 'Close') ($W - $M - 110) 562 110 46 'Ghost'
$btFechar.Add_Click({ $form.Close() })
$form.Controls.Add($btFechar)

$cdLog = New-Object Divine.DvCard
$cdLog.Location = "$M,622"; $cdLog.Size = "$L,80"; $cdLog.BackColor = $P::Surface; $cdLog.Border = $P::Line
$tbLog = New-Object System.Windows.Forms.RichTextBox
$tbLog.Location = '14,9'; $tbLog.Size = "$($L - 22),62"; $tbLog.ReadOnly = $true; $tbLog.TabStop = $false
$tbLog.BackColor = $P::Surface; $tbLog.ForeColor = $P::Mute; $tbLog.BorderStyle = 'None'; $tbLog.Font = $F_MONO
$tbLog.ScrollBars = 'Vertical'
$cdLog.Controls.Add($tbLog)
$form.Controls.Add($cdLog)

$CORES_LOG = @{ Green = $P::Success; Red = $P::Danger; Yellow = $P::GoldText; DarkGray = $P::Mute; Gray = $P::Soft; Cyan = [System.Drawing.ColorTranslator]::FromHtml('#a0b6ef') }
$script:Saida = {
    param($texto, $cor)
    $tbLog.SelectionStart = $tbLog.TextLength
    $tbLog.SelectionColor = if ($CORES_LOG[$cor]) { $CORES_LOG[$cor] } else { $P::Soft }
    $tbLog.AppendText("$texto`r`n"); $tbLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# ---------------------------------------------------------------- caixa de aviso no mesmo visual
# Dialog in the same look. $botoes: lista de @(valor, texto, tipo). Devolve o valor clicado.
function Show-Aviso([string]$titulo, [string]$texto, [object[]]$botoes, [string]$tom = 'ouro') {
    $dl = New-Object System.Windows.Forms.Form
    $dl.Text = $NOME_PACK; $dl.FormBorderStyle = 'FixedDialog'; $dl.StartPosition = 'CenterParent'
    $dl.MaximizeBox = $false; $dl.MinimizeBox = $false; $dl.ShowInTaskbar = $false
    $dl.BackColor = $P::Bg; $dl.Font = $F_TXT; $dl.Icon = $form.Icon
    $dl.Add_HandleCreated({ [Divine.Gfx]::DarkTitleBar($this.Handle, $P::Bg) })
    # a caixa cresce para caber os botões / the box widens to fit the buttons
    $somaBotoes = 0
    foreach ($b in $botoes) { $somaBotoes += [math]::Max(110, [System.Windows.Forms.TextRenderer]::MeasureText($b[1], $F_BOTAO).Width + 36) + 10 }
    # inteiro: "430.5,28" vira tamanho errado no Windows em português (vírgula decimal)
    $dw = [int][math]::Ceiling([math]::Max(480, $somaBotoes + 46))
    $corTit = if ($tom -eq 'erro') { $P::Danger } else { $P::GoldText }
    $dl.Controls.Add((New-Label $titulo.ToUpper() 28 24 ($dw - 56) 28 $corTit $F_SECAO))
    # o próprio rótulo mede a altura (MeasureText quebra a linha um pouco diferente)
    # the label measures its own height (MeasureText wraps slightly differently)
    $lb = New-Label $texto 28 60 ($dw - 56) 20 $P::Soft
    $lb.MaximumSize = New-Object System.Drawing.Size ($dw - 56), 0
    $lb.AutoSize = $true
    $dl.Controls.Add($lb)
    $alt = $lb.PreferredHeight
    $y = 60 + $alt + 24
    $x = $dw - 28
    $dl.Tag = $null
    $principal = $null
    for ($i = $botoes.Count - 1; $i -ge 0; $i--) {
        $b = $botoes[$i]
        $bw = [int][math]::Max(110, [System.Windows.Forms.TextRenderer]::MeasureText($b[1], $F_BOTAO).Width + 36)
        $x -= $bw
        $bt = New-Botao $b[1] $x $y $bw 40 $b[2]
        $bt.Tag = $b[0]
        $bt.Add_Click({ $this.FindForm().Tag = $this.Tag; $this.FindForm().Close() })
        $dl.Controls.Add($bt)
        if ($b[2] -eq 'Primary') { $principal = $bt }
        $x -= 10
    }
    $dl.ClientSize = "$dw,$($y + 40 + 24)"
    if ($principal) { $dl.ActiveControl = $principal }
    [void]$dl.ShowDialog($form)
    $r = $dl.Tag; $dl.Dispose()
    return $r
}

# ---------------------------------------------------------------- estado / status
function Get-Pasta { $tbPasta.Text.Trim().Trim('"') }

function Update-Status {
    $d = Get-Pasta
    $stPasta.Clear()
    if (-not (Test-GameDir $d)) {
        $stPasta.Add((T 'Gw2-64.exe não está nessa pasta. Use "Procurar..." e escolha a pasta do jogo.' 'Gw2-64.exe is not in that folder. Use "Browse..." and pick the game folder.'), $P::Danger)
        $btInstalar.Enabled = $false; $btDesinstalar.Enabled = $false
        return
    }
    $s = Get-GameStatus $d
    # o texto diz o estado; a cor do ponto só reforça / the text carries the state, the dot only reinforces it
    if ($s.Nexus) { $stPasta.Add((T 'Nexus encontrado' 'Nexus found'), $P::Success) }
    else { $stPasta.Add((T 'Nexus não encontrado' 'Nexus not found'), $P::Danger) }
    if ($s.CustomCursors) { $stPasta.Add((T 'Custom Cursors encontrado' 'Custom Cursors found'), $P::Success) }
    else { $stPasta.Add((T 'Custom Cursors não encontrado' 'Custom Cursors not found'), $P::Danger) }
    if (Test-GameRunning) { $stPasta.Add((T 'O jogo está aberto: feche antes de instalar' 'The game is running: close it before installing'), $P::Danger) }
    elseif ($s.Pack) { $stPasta.Add((T 'Já instalado: instale de novo para trocar cor ou tamanho' 'Already installed: install again to switch colour or size'), $P::Gold) }
    $btInstalar.Enabled = $true; $btDesinstalar.Enabled = $s.Pack -or $s.Settings
}
$tbPasta.Add_TextChanged({ Update-Status })

$btProcurar.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = T 'Pasta do Guild Wars 2 (a que tem Gw2-64.exe)' 'Guild Wars 2 folder (the one with Gw2-64.exe)'
    if ($dlg.ShowDialog($form) -eq 'OK') { $tbPasta.Text = $dlg.SelectedPath }
})

function Invoke-Seguro([scriptblock]$acao) {
    $form.UseWaitCursor = $true; $btInstalar.Enabled = $false; $btDesinstalar.Enabled = $false
    try { & $acao }
    catch {
        Say $_.Exception.Message $_.Exception.Message 'Red'
        [void](Show-Aviso (T 'Não deu certo' 'That did not work') $_.Exception.Message @(, @('ok', (T 'Fechar' 'Close'), 'Primary')) 'erro')
    }
    finally { $form.UseWaitCursor = $false; Update-Status }
}

$btInstalar.Add_Click({
    Invoke-Seguro {
        $d = Get-Pasta
        $tbLog.Clear()
        $forcar = $false
        if (-not (Get-GameStatus $d).CustomCursors) {
            $r = Show-Aviso (T 'Custom Cursors não encontrado' 'Custom Cursors not found') `
                (T "Não achei o addon Custom Cursors nessa pasta.`n`nSe você já instalou pelo Nexus (Ctrl+O > Addons > Library), pode instalar mesmo assim. Se ainda não instalou, instale o addon primeiro e depois volte aqui." "Could not find the Custom Cursors addon in that folder.`n`nIf you already installed it from Nexus (Ctrl+O > Addons > Library), you can install anyway. If you haven't, install the addon first and then come back here.") `
                @(@('nao', (T 'Cancelar' 'Cancel'), 'Ghost'), @('sim', (T 'Instalar mesmo assim' 'Install anyway'), 'Primary'))
            if ($r -ne 'sim') { return }
            $forcar = $true
        }
        Say "Instalando em: $d" "Installing into: $d" 'Cyan'
        $null = Install-Pack $d $script:Cor $script:Tamanho $tgAliado.Checked $forcar
        [void](Show-Aviso (T 'Cursores instalados' 'Cursors installed') `
            (T "Abra o jogo para ver.`n`nO tamanho vale para os três modos de Contraste do cursor (Opções > Geral > Acessibilidade). Para trocar cor ou tamanho, instale de novo." "Start the game to see them.`n`nThe size applies to all three Cursor contrast modes (Options > General > Accessibility). To switch colour or size, install again.") `
            @(, @('ok', (T 'Fechar' 'Close'), 'Primary')))
    }
})

$btDesinstalar.Add_Click({
    $r = Show-Aviso (T "Desinstalar o ${NOME_PACK}?" "Uninstall ${NOME_PACK}?") `
        (T "Os cursores do $NOME_PACK voltam ao padrão do jogo. Cursores de outros packs que você configurou não mudam.`n`nA pasta do pack pode ficar (para reinstalar depois) ou ser apagada." "The $NOME_PACK cursors go back to the game default. Cursors from other packs you set up don't change.`n`nThe pack folder can stay (to reinstall later) or be deleted.") `
        @(@('cancelar', (T 'Cancelar' 'Cancel'), 'Ghost'), @('so', (T 'Manter a pasta' 'Keep the folder'), 'Secondary'), @('tudo', (T 'Apagar a pasta' 'Delete the folder'), 'Primary'))
    if ($r -ne 'so' -and $r -ne 'tudo') { return }
    Invoke-Seguro {
        $tbLog.Clear()
        $null = Uninstall-Pack (Get-Pasta) ($r -eq 'tudo')
    }
})

# ---------------------------------------------------------------- início
$form.Add_Shown({
    $form.Refresh()
    Say 'Procurando a pasta do jogo...' 'Looking for the game folder...' 'DarkGray'
    $achadas = @(Get-GameDirCandidates)
    foreach ($a in $achadas) {
        $it = $mnPastas.Items.Add($a); $it.ForeColor = $P::Text
        $it.Add_Click({ $tbPasta.Text = $this.Text })
    }
    $btLista.Visible = $achadas.Count -gt 1
    if ($achadas.Count) {
        $tbPasta.Text = $achadas[0]
        Say "Pasta encontrada: $($achadas[0])" "Folder found: $($achadas[0])" 'Green'
        # já instalado? pré-seleciona a cor atual / already installed? preselect the current colour
        try {
            $cfg = Read-Settings (Get-SettingsPath $achadas[0])
            $atual = @($cfg.cursors) | Where-Object { $_.cursor_id -eq 3482162487 -or $_.cursor_id -eq 2876413485 } |
                     Where-Object { "$($_.file_path)" -match 'gw2-seta-([a-z]+)(-brilho)?-(\d+)\.png' } | Select-Object -First 1
            if ($atual -and "$($atual.file_path)" -match 'gw2-seta-([a-z]+)(-brilho)?-\d+\.png' -and $botoesCor[$Matches[1]]) {
                $botoesCor[$Matches[1]].Checked = $true
            }
        } catch { }
    } else {
        Update-Status
        Say 'Não achei a pasta sozinho. Clique em "Procurar..." e escolha a pasta que tem Gw2-64.exe.' 'Could not find it on my own. Click "Browse..." and pick the folder with Gw2-64.exe.' 'Yellow'
    }
    if (-not ($botoesCor.Values | Where-Object Checked)) { $botoesCor['dourado'].Checked = $true }
    Update-Previa
    $btInstalar.Focus()
})

[void]$form.ShowDialog()
