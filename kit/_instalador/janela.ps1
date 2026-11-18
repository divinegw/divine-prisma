# gw2-facetado: janela do instalador (aberta pelo Instalar.bat).
# gw2-facetado: installer window (opened by Instalar.bat).
# Toda a parte que mexe em arquivos está em comum.ps1 (Install-Pack / Uninstall-Pack).
. (Join-Path $PSScriptRoot 'comum.ps1')
$ErrorActionPreference = 'Continue'

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$NOMES = [ordered]@{ roxo = (T 'Roxo' 'Purple'); ciano = (T 'Ciano' 'Cyan'); dourado = (T 'Dourado' 'Gold')
                     prata = (T 'Prata' 'Silver'); rosa = (T 'Rosa' 'Pink'); verde = (T 'Verde' 'Green')
                     vermelho = (T 'Vermelho' 'Red') }
$C_FUNDO = [System.Drawing.Color]::FromArgb(30, 33, 38)
$C_PAINEL = [System.Drawing.Color]::FromArgb(44, 49, 57)
$C_TXT = [System.Drawing.Color]::FromArgb(236, 236, 236)
$C_SUB = [System.Drawing.Color]::FromArgb(160, 166, 174)
$C_OK = [System.Drawing.Color]::FromArgb(120, 200, 120)
$C_RUIM = [System.Drawing.Color]::FromArgb(235, 110, 100)
$fonte = New-Object System.Drawing.Font('Segoe UI', 9.5)
$fonteB = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)

# PNG sem travar o arquivo / load a PNG without locking the file
function Get-Png([string]$tipo, [string]$variante, [int]$tam) {
    $p = Join-Path $PACK_SRC "$tipo\gw2-$tipo-$variante-$tam.png"
    if (-not (Test-Path -LiteralPath $p)) { return $null }
    $ms = New-Object System.IO.MemoryStream (, [IO.File]::ReadAllBytes($p))
    return [System.Drawing.Image]::FromStream($ms)
}

function New-Label($texto, $x, $y, $w, $h, $cor = $C_TXT, $f = $fonte) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $texto; $l.Location = "$x,$y"; $l.Size = "$w,$h"; $l.ForeColor = $cor; $l.Font = $f
    $l.BackColor = [System.Drawing.Color]::Transparent
    return $l
}

function New-Button($texto, $x, $y, $w, $h) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $texto; $b.Location = "$x,$y"; $b.Size = "$w,$h"; $b.Font = $fonte
    $b.FlatStyle = 'Flat'; $b.ForeColor = $C_TXT; $b.BackColor = $C_PAINEL
    $b.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(90, 98, 110)
    return $b
}

$form = New-Object System.Windows.Forms.Form
$form.Text = T 'gw2-facetado — instalar cursores' 'gw2-facetado — install cursors'
$form.ClientSize = '720,640'; $form.StartPosition = 'CenterScreen'; $form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false; $form.BackColor = $C_FUNDO; $form.Font = $fonte
$ico = Join-Path $PACK_SRC 'seta\gw2-seta-dourado-brilho-32.png'
if (Test-Path -LiteralPath $ico) { try { $form.Icon = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap](Get-Png 'seta' 'dourado-brilho' 32)).GetHicon()) } catch { } }

$form.Controls.Add((New-Label 'gw2-facetado' 20 12 400 30 $C_TXT (New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold))))
$form.Controls.Add((New-Label (T 'Cursores facetados para o addon Custom Cursors (Nexus). Feche o jogo antes de instalar.' 'Faceted cursors for the Custom Cursors addon (Nexus). Close the game before installing.') 22 44 680 20 $C_SUB))

# ---------------------------------------------------------------- 1. pasta do jogo
$form.Controls.Add((New-Label (T '1. Pasta do Guild Wars 2' '1. Guild Wars 2 folder') 20 76 400 22 $C_TXT $fonteB))
$cbPasta = New-Object System.Windows.Forms.ComboBox
$cbPasta.Location = '22,100'; $cbPasta.Size = '560,24'; $cbPasta.DropDownStyle = 'DropDown'
$cbPasta.BackColor = $C_PAINEL; $cbPasta.ForeColor = $C_TXT; $cbPasta.FlatStyle = 'Flat'
$form.Controls.Add($cbPasta)
$btProcurar = New-Button (T 'Procurar...' 'Browse...') 592 99 108 26
$form.Controls.Add($btProcurar)
$lbStatus = New-Label '' 22 130 680 20 $C_SUB
$form.Controls.Add($lbStatus)

# ---------------------------------------------------------------- 2. cor
$form.Controls.Add((New-Label (T '2. Cor' '2. Colour') 20 162 400 22 $C_TXT $fonteB))
$script:Cor = 'dourado'
$botoesCor = @{}
# cada grupo de botões de rádio precisa do próprio painel / each radio group needs its own panel
$pnCores = New-Object System.Windows.Forms.Panel
$pnCores.Location = '22,186'; $pnCores.Size = '680,84'; $pnCores.BackColor = $C_FUNDO
$form.Controls.Add($pnCores)
$x = 0
foreach ($c in $NOMES.Keys) {
    $bmp = New-Object System.Drawing.Bitmap 84, 52
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear($C_PAINEL)
    foreach ($par in @(@('seta', 4), @('mao-aberta', 40))) {
        $im = Get-Png $par[0] "$c-brilho" 48
        if ($im) { $g.DrawImage($im, $par[1], 2, 40, 40) }
    }
    $g.Dispose()
    $rb = New-Object System.Windows.Forms.RadioButton
    $rb.Appearance = 'Button'; $rb.Location = "$x,0"; $rb.Size = '92,82'
    $rb.Image = $bmp; $rb.ImageAlign = 'TopCenter'; $rb.Text = $NOMES[$c]; $rb.TextAlign = 'BottomCenter'
    $rb.FlatStyle = 'Flat'; $rb.BackColor = $C_PAINEL; $rb.ForeColor = $C_TXT; $rb.Tag = $c
    $rb.FlatAppearance.CheckedBackColor = [System.Drawing.Color]::FromArgb(78, 88, 104)
    $rb.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(70, 76, 86)
    $rb.Add_CheckedChanged({ if ($this.Checked) { $script:Cor = $this.Tag; Update-Previa } })
    $pnCores.Controls.Add($rb); $botoesCor[$c] = $rb
    $x += 97
}

# ---------------------------------------------------------------- 3. tamanho
$form.Controls.Add((New-Label (T '3. Tamanho' '3. Size') 20 282 400 22 $C_TXT $fonteB))
$script:Tamanho = 48
$pnTam = New-Object System.Windows.Forms.Panel
$pnTam.Location = '22,306'; $pnTam.Size = '340,30'; $pnTam.BackColor = $C_FUNDO
$form.Controls.Add($pnTam)
$x = 0
foreach ($t in $TAMANHOS) {
    $rb = New-Object System.Windows.Forms.RadioButton
    $rb.Appearance = 'Button'; $rb.Location = "$x,0"; $rb.Size = '64,28'; $rb.TextAlign = 'MiddleCenter'
    $rb.Text = "$t px"; $rb.Tag = $t; $rb.FlatStyle = 'Flat'; $rb.BackColor = $C_PAINEL; $rb.ForeColor = $C_TXT
    $rb.FlatAppearance.CheckedBackColor = [System.Drawing.Color]::FromArgb(78, 88, 104)
    $rb.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(70, 76, 86)
    if ($t -eq 48) { $rb.Checked = $true }
    $rb.Add_CheckedChanged({ if ($this.Checked) { $script:Tamanho = [int]$this.Tag; Update-Previa } })
    $pnTam.Controls.Add($rb)
    $x += 68
}
$form.Controls.Add((New-Label (T '48 px é o padrão. Telas grandes ou interface maior: 64 px.' '48 px is the default. Big screens or larger UI: 64 px.') 22 338 340 40 $C_SUB))
$cbAliado = New-Object System.Windows.Forms.CheckBox
$cbAliado.Location = '22,380'; $cbAliado.Size = '340,40'; $cbAliado.ForeColor = $C_TXT
$cbAliado.Text = T 'Seta de aliado (NPC amigo) em verde, como no jogo. Desmarcado: na cor escolhida.' 'Ally arrow (friendly NPC) in green, like the game. Unchecked: in the chosen colour.'
$cbAliado.Add_CheckedChanged({ Update-Previa })
$form.Controls.Add($cbAliado)

# prévia em tamanho real / real-size preview
$pbPrevia = New-Object System.Windows.Forms.PictureBox
$pbPrevia.Location = '372,282'; $pbPrevia.Size = '328,140'; $pbPrevia.BackColor = [System.Drawing.Color]::FromArgb(52, 62, 76)
$form.Controls.Add($pbPrevia)
function Update-Previa {
    $t = $script:Tamanho; $c = $script:Cor
    $aliado = if ($cbAliado.Checked) { 'verde' } else { $c }
    $bmp = New-Object System.Drawing.Bitmap 328, 140
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::FromArgb(52, 62, 76))
    $g.InterpolationMode = 'HighQualityBicubic'
    $lado = [math]::Min($t, 96)
    $x = 8
    foreach ($par in @(@('seta', "$c-brilho"), @('mao-aberta', "$c-brilho"), @('fala', "$c-brilho"), @('seta', "$aliado-brilho"), @('seta', 'vermelho-brilho'))) {
        $im = Get-Png $par[0] $par[1] $t
        if ($im) { $g.DrawImage($im, $x, 8, $lado, $lado) }
        $x += [math]::Max($lado * 0.62, 40) + 6
    }
    $txt = if ($t -gt 96) { T "prévia reduzida (real: $t px)" "scaled-down preview (actual: $t px)" } else { T 'tamanho real · aliado e inimigo à direita' 'actual size · ally and enemy on the right' }
    $g.DrawString($txt, $fonte, (New-Object System.Drawing.SolidBrush $C_SUB), 8, 116)
    $g.Dispose()
    if ($pbPrevia.Image) { $pbPrevia.Image.Dispose() }
    $pbPrevia.Image = $bmp
}

# ---------------------------------------------------------------- botões e registro
$btInstalar = New-Button (T 'Instalar' 'Install') 22 436 200 40
$btInstalar.Font = $fonteB; $btInstalar.BackColor = [System.Drawing.Color]::FromArgb(56, 110, 70)
$form.Controls.Add($btInstalar)
$btDesinstalar = New-Button (T 'Desinstalar' 'Uninstall') 232 436 140 40
$form.Controls.Add($btDesinstalar)
$btFechar = New-Button (T 'Fechar' 'Close') 590 436 110 40
$btFechar.Add_Click({ $form.Close() })
$form.Controls.Add($btFechar)

$tbLog = New-Object System.Windows.Forms.RichTextBox
$tbLog.Location = '22,488'; $tbLog.Size = '678,136'; $tbLog.ReadOnly = $true
$tbLog.BackColor = [System.Drawing.Color]::FromArgb(22, 24, 28); $tbLog.ForeColor = $C_TXT; $tbLog.BorderStyle = 'None'
$tbLog.Font = New-Object System.Drawing.Font('Consolas', 9)
$form.Controls.Add($tbLog)

$CORES_LOG = @{ Green = $C_OK; Red = $C_RUIM; Yellow = [System.Drawing.Color]::Khaki; DarkGray = $C_SUB; Gray = $C_TXT; Cyan = [System.Drawing.Color]::SkyBlue }
$script:Saida = {
    param($texto, $cor)
    $tbLog.SelectionStart = $tbLog.TextLength
    $tbLog.SelectionColor = if ($CORES_LOG[$cor]) { $CORES_LOG[$cor] } else { $C_TXT }
    $tbLog.AppendText("$texto`r`n"); $tbLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Update-Status {
    $d = $cbPasta.Text.Trim().Trim('"')
    if (-not (Test-GameDir $d)) {
        $lbStatus.ForeColor = $C_RUIM
        $lbStatus.Text = T 'Gw2-64.exe não está nessa pasta. Use "Procurar..." e escolha a pasta do jogo.' 'Gw2-64.exe is not in that folder. Use "Browse..." and pick the game folder.'
        $btInstalar.Enabled = $false; $btDesinstalar.Enabled = $false
        return
    }
    $s = Get-GameStatus $d
    $m = { param($ok, $nome) if ($ok) { "✔ $nome" } else { "✘ $nome" } }
    $partes = @((& $m $s.Nexus 'Nexus'), (& $m $s.CustomCursors 'Custom Cursors'))
    if ($s.Pack) { $partes += (T '• gw2-facetado já instalado (instalar de novo troca cor/tamanho)' '• gw2-facetado already installed (installing again switches colour/size)') }
    if (Test-GameRunning) { $partes += (T '• JOGO ABERTO: feche antes' '• GAME RUNNING: close it first') }
    $lbStatus.Text = $partes -join '    '
    $lbStatus.ForeColor = if ($s.Nexus -and $s.CustomCursors -and -not (Test-GameRunning)) { $C_OK } else { [System.Drawing.Color]::Khaki }
    $btInstalar.Enabled = $true; $btDesinstalar.Enabled = $s.Pack -or $s.Settings
}
$cbPasta.Add_TextChanged({ Update-Status })
$cbPasta.Add_SelectedIndexChanged({ Update-Status })

$btProcurar.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = T 'Pasta do Guild Wars 2 (a que tem Gw2-64.exe)' 'Guild Wars 2 folder (the one with Gw2-64.exe)'
    if ($dlg.ShowDialog($form) -eq 'OK') { $cbPasta.Text = $dlg.SelectedPath }
})

function Invoke-Seguro([scriptblock]$acao) {
    $form.UseWaitCursor = $true; $btInstalar.Enabled = $false; $btDesinstalar.Enabled = $false
    try { & $acao }
    catch {
        Say $_.Exception.Message $_.Exception.Message 'Red'
        [void][System.Windows.Forms.MessageBox]::Show($form, $_.Exception.Message, 'gw2-facetado', 'OK', 'Warning')
    }
    finally { $form.UseWaitCursor = $false; Update-Status }
}

$btInstalar.Add_Click({
    Invoke-Seguro {
        $d = $cbPasta.Text.Trim().Trim('"')
        $tbLog.Clear()
        Say "Instalando em: $d" "Installing into: $d" 'Cyan'
        $null = Install-Pack $d $script:Cor $script:Tamanho $cbAliado.Checked
        [void][System.Windows.Forms.MessageBox]::Show($form,
            (T "Pronto! Abra o jogo para ver os cursores.`n`nO tamanho fica igual nos três modos de 'Contraste do cursor' (Opções > Geral > Acessibilidade). Para trocar cor ou tamanho, é só instalar de novo." "Done! Start the game to see the cursors.`n`nThe size is the same in all three 'Cursor contrast' modes (Options > General > Accessibility). To switch colour or size, just install again."),
            'gw2-facetado', 'OK', 'Information')
    }
})

$btDesinstalar.Add_Click({
    $r = [System.Windows.Forms.MessageBox]::Show($form,
        (T "Voltar os cursores do gw2-facetado ao padrão do jogo?`n`nSim = voltar e apagar a pasta do pack`nNão = só voltar os cursores" "Reset the gw2-facetado cursors to the game default?`n`nYes = reset and delete the pack folder`nNo = only reset the cursors"),
        'gw2-facetado', 'YesNoCancel', 'Question')
    if ($r -eq 'Cancel') { return }
    Invoke-Seguro {
        $tbLog.Clear()
        $null = Uninstall-Pack ($cbPasta.Text.Trim().Trim('"')) ($r -eq 'Yes')
    }
})

# ---------------------------------------------------------------- início
$form.Add_Shown({
    $form.Refresh()
    Say 'Procurando a pasta do jogo...' 'Looking for the game folder...' 'DarkGray'
    $achadas = @(Get-GameDirCandidates)
    foreach ($a in $achadas) { [void]$cbPasta.Items.Add($a) }
    if ($achadas.Count) {
        $cbPasta.SelectedIndex = 0
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
})

[void]$form.ShowDialog()
