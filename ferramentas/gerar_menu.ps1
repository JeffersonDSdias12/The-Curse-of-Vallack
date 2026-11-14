# =====================================================================
#  Gera a arte do menu inicial (v1.14) para as duas versões:
#  datafiles/ (PC, GameMaker) e godot/assets/data/ (Android).
#   mancha_sangue.png  pincelada de sangue atrás da logo (GeraMenu.cs)
#   heroi_retrato.png  busto de Twilight recortado da arte HD da equipe
#                      (ferramentas/_arte_equipe), espelhado para olhar o menu
#  Uso:  powershell -File ferramentas/gerar_menu.ps1   (depois --import no Godot)
# =====================================================================
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
Add-Type -ReferencedAssemblies System.Drawing -Path (Join-Path $PSScriptRoot "GeraMenu.cs")
[GeraMenu]::Gerar((Join-Path $raiz "datafiles"), (Join-Path $raiz "godot\assets\data"))

Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile((Join-Path $PSScriptRoot "_arte_equipe\Alex\Sprites\Personagem Principal\Parado\1.png"))
$r = New-Object System.Drawing.Rectangle 300, 180, 560, 700          # cabeça, ombros e peito (sem a espada)
$b = New-Object System.Drawing.Bitmap $r.Width, $r.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($b)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.DrawImage($src, (New-Object System.Drawing.Rectangle 0, 0, $r.Width, $r.Height), $r, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$b.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)
for ($y = 480; $y -lt $r.Height; $y++) {
    $f = 1 - ($y - 480) / ($r.Height - 480)          # some aos poucos embaixo (sai da escuridão)
    for ($x = 0; $x -lt $r.Width; $x++) { $c = $b.GetPixel($x, $y); if ($c.A -gt 0) { $b.SetPixel($x, $y, [System.Drawing.Color]::FromArgb([int]($c.A * $f), $c.R, $c.G, $c.B)) } }
}
foreach ($d in (Join-Path $raiz "datafiles"), (Join-Path $raiz "godot\assets\data")) { $b.Save((Join-Path $d "heroi_retrato.png"), [System.Drawing.Imaging.ImageFormat]::Png) }
$src.Dispose(); $b.Dispose()
"heroi_retrato.png 560x700"
