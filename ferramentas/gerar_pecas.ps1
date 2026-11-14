# =====================================================================
#  Peças de cenário do Alex (paredes, ruínas, chão e plataformas) num atlas:
#  datafiles/pecas_fase1.png + .json (PC) e godot/assets/data/ (Android).
#  Cada peça é uma "mancha" da folha (as partes que se tocam ficam juntas),
#  reduzida por área para 0,6x. O jogo desenha a 0,7 disso (~0,42 da folha).
#  Uso:  powershell -File ferramentas/gerar_pecas.ps1 [-Previa arquivo.png]
# =====================================================================
param([string]$Previa = "")
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$fonte = Join-Path $PSScriptRoot "_arte_equipe\Alex\Sprites"
$utf8 = New-Object System.Text.UTF8Encoding($false)
Add-Type -ReferencedAssemblies System.Drawing -Path @((Join-Path $PSScriptRoot "ProcSprite.cs"), (Join-Path $PSScriptRoot "ImportaArte.cs"))

$cen = Get-ChildItem $fonte -Directory | Where-Object { $_.Name -like "Cen*rio" } | Select-Object -First 1
$vila = Get-ChildItem $cen.FullName -Directory | Where-Object { $_.Name -like "*Vila*" } | Select-Object -First 1
$folhas = @(
    @{ id = "parede"; arq = (Get-ChildItem $vila.FullName -Filter "Sprites de parede.png").FullName },
    @{ id = "chao"; arq = (Get-ChildItem $vila.FullName -Filter "Sprites do ch*.png").FullName }
)
$ESC = 0.6
$pecas = @()
foreach ($f in $folhas) {
    $w = 0; $h = 0
    $px = [ProcSprite]::Carregar($f.arq, [ref]$w, [ref]$h)
    $caixas = [ImportaArte]::Manchas($px, $w, $h, 1500, 4)
    $i = 0
    foreach ($c in $caixas) {
        $reg = [ImportaArte]::Regiao($px, $w, $h, $c[0], $c[1], $c[2] + 1, $c[3] + 1)
        # tira pedaços de peças vizinhas que entram na caixa (cipós, folhas)
        [ImportaArte]::LimparVizinhos($reg, $c[2] - $c[0] + 1, $c[3] - $c[1] + 1, 0.0, $true)
        $ow = 0; $oh = 0
        $r = [ImportaArte]::Reduzir($reg, $c[2] - $c[0] + 1, $c[3] - $c[1] + 1, $ESC, [ref]$ow, [ref]$oh)
        $pecas += , @{ nome = "$($f.id)$i"; px = $r; w = $ow; h = $oh }
        $i++
    }
}

# empacotamento em prateleiras (as mais altas primeiro)
$LARG = 2048
$ordem = $pecas | Sort-Object { -$_.h }
$x = 1; $y = 1; $alt = 0
foreach ($p in $ordem) {
    if ($x + $p.w + 1 -gt $LARG) { $x = 1; $y += $alt + 2; $alt = 0 }
    $p.x = $x; $p.y = $y
    $x += $p.w + 2
    $alt = [math]::Max($alt, $p.h)
}
$ALT = $y + $alt + 1
$atlas = [ImportaArte]::Vazio($LARG, $ALT)
foreach ($p in $pecas) { [ImportaArte]::Colar($atlas, $LARG, $ALT, $p.px, $p.w, $p.h, $p.x, $p.y) }

$d = [ordered]@{}
foreach ($p in $pecas) { $d[$p.nome] = @($p.x, $p.y, $p.w, $p.h) }
$json = @{ escala = $ESC; pecas = $d } | ConvertTo-Json -Depth 4 -Compress
foreach ($dst in @((Join-Path $raiz "datafiles"), (Join-Path $raiz "godot\assets\data"))) {
    [ProcSprite]::Salvar((Join-Path $dst "pecas_fase1.png"), $atlas, $LARG, $ALT)
    [IO.File]::WriteAllText((Join-Path $dst "pecas_fase1.json"), $json, $utf8)
}
"pecas: $($pecas.Count)  atlas ${LARG}x$ALT"

if ($Previa) {
    # folha com o nome de cada peça (para escolher onde usar)
    $tmp = Join-Path $env:TEMP "pecas_prev.png"
    [ProcSprite]::Salvar($tmp, $atlas, $LARG, $ALT)
    $im = [System.Drawing.Image]::FromFile($tmp)
    $bmp = New-Object System.Drawing.Bitmap $LARG, $ALT
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::FromArgb(60, 60, 72))
    $g.DrawImage($im, 0, 0, $LARG, $ALT)
    $fonteT = New-Object System.Drawing.Font "Arial", 13, ([System.Drawing.FontStyle]::Bold)
    foreach ($p in $pecas) {
        $g.DrawRectangle([System.Drawing.Pens]::Yellow, $p.x, $p.y, $p.w, $p.h)
        $g.FillRectangle([System.Drawing.Brushes]::Black, $p.x, $p.y, 62, 18)
        $g.DrawString($p.nome, $fonteT, [System.Drawing.Brushes]::Yellow, $p.x + 1, $p.y)
    }
    $bmp.Save($Previa)
    $g.Dispose(); $bmp.Dispose(); $im.Dispose()
}
