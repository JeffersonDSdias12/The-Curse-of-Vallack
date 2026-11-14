# =====================================================================
#  Tratamento visual dos sprites de personagens, inimigos e boss.
#  Lê sempre os ORIGINAIS (godot/_originais), então pode rodar de novo.
#  Uso:  powershell -File ferramentas/processar_sprites.ps1
# =====================================================================
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot      # pasta godot
$spr = Join-Path $raiz "assets\sprites"
$orig = Join-Path $raiz "_originais"
$utf8 = New-Object System.Text.UTF8Encoding($false)

Add-Type -ReferencedAssemblies System.Drawing -Path (Join-Path $PSScriptRoot "ProcSprite.cs")

# ----- cópia dos originais (só na primeira vez) -----
if (-not (Test-Path (Join-Path $orig "sprites.json"))) {
    New-Item -ItemType Directory -Force (Join-Path $orig "sprites") | Out-Null
    [IO.File]::WriteAllText((Join-Path $orig ".gdignore"), "", $utf8)
    Copy-Item (Join-Path $raiz "assets\data\sprites.json") (Join-Path $orig "sprites.json")
    foreach ($d in Get-ChildItem $spr -Directory) {
        $dst = Join-Path $orig "sprites\$($d.Name)"
        New-Item -ItemType Directory -Force $dst | Out-Null
        Copy-Item (Join-Path $d.FullName "*.png") $dst
    }
    "originais guardados em $orig"
}

# ----- famílias: [padrão do nome, pad (contorno), nitidez, contraste, saturação,
#        corte de alfa, bloco p/ suavizar (0 = não)] — a primeira que casar vale -----
$familias = @(
    # corrida: tira a "perna fantasma" semitransparente que piscava a cada quadro
    @("^spr_player_run$", 3, 0.55, 1.05, 1.06, 0.75, 0),
    # animações em resolução mais baixa (quadriculadas): suaviza os blocos
    @("^spr_player_(ataque|especial|agaichar)$", 3, 0.6, 1.05, 1.06, 0.22, 5),
    @("^spr_player_atacar_agaichado$", 3, 0.6, 1.05, 1.06, 0.22, 7),
    @("^spr_player_atacar_agaichado_especial$", 3, 0.6, 1.05, 1.06, 0.22, 5),
    @("^spr_inimigo01_atacando$", 3, 0.6, 1.06, 1.05, 0.22, 5),
    @("^spr_player", 3, 0.55, 1.05, 1.06, 0.22, 0),
    @("^spr_ataque_(2|03|especial_2)$", 3, 0.55, 1.05, 1.06, 0.22, 0),
    @("^spr_inimigo01_", 3, 0.5, 1.06, 1.05, 0.22, 0),
    @("^spr_inimigo02_", 3, 0.5, 1.06, 1.06, 0.22, 0),
    @("^spr_boss_01(_atacando|_parado)?$", 4, 0.4, 1.06, 1.05, 0.22, 0),
    @("^spr_esqueleto_", 2, 0.5, 1.06, 1.05, 0.22, 0),
    @("^spr_porco_", 2, 0.6, 1.10, 1.08, 0.22, 0),
    @("^spr_aranha_", 2, 0.5, 1.06, 1.06, 0.22, 0),
    @("^spr_estatua$", 2, 0.45, 1.08, 1.05, 0.22, 4),
    @("^spr_morador_", 2, 0.5, 1.04, 1.04, 0.22, 0)
)

$json = [IO.File]::ReadAllText((Join-Path $orig "sprites.json"), $utf8) | ConvertFrom-Json
$reconstruidos = 0
$total = 0
foreach ($p in $json.PSObject.Properties) {
    $nome = $p.Name
    # v1.17: escalada e ataques novos já saem prontos (ferramentas/importar_folhas.ps1, na raiz)
    if ($nome -match '^spr_player_(subindo_escada|descendo_escada|pular_e_agarrar_cordas|segurando_e_subindo_cordas|ataque_rapido|ataque_duplo|ataque_triplo|ataque_frenetico)$') { continue }
    $fam = $null
    foreach ($f in $familias) { if ($nome -match $f[0]) { $fam = $f; break } }
    if ($fam -eq $null) { continue }
    $pad = [int]$fam[1]
    $d = $p.Value
    $n = [int]$d.n
    $blocos = @()
    for ($i = 0; $i -lt $n; $i++) {
        $w = 0; $h = 0
        $px = [ProcSprite]::Carregar((Join-Path $orig "sprites\$nome\$i.png"), [ref]$w, [ref]$h)
        $s = [ProcSprite]::Reconstruir($px, $w, $h)
        if ($s -gt 1) { $reconstruidos++; $blocos += "$i=$s" }
        elseif ([int]$fam[6] -gt 1) {
            [ProcSprite]::Suavizar($px, $w, $h, [double]$fam[6])
            $reconstruidos++
            $blocos += "$i~$($fam[6])"
        }
        [ProcSprite]::Limpar($px, $w, $h, [double]$fam[5])
        [ProcSprite]::Realcar($px, $w, $h, [double]$fam[2], [double]$fam[3], [double]$fam[4])
        $nw = 0; $nh = 0
        $o = [ProcSprite]::Contornar($px, $w, $h, $pad, 14, 7, 9, [ref]$nw, [ref]$nh)
        [ProcSprite]::Salvar((Join-Path $spr "$nome\$i.png"), $o, $nw, $nh)
        # mipmaps: o sprite é desenhado reduzido (1/k) sem serrilhar
        $imp = Join-Path $spr "$nome\$i.png.import"
        if (Test-Path $imp) {
            $t = [IO.File]::ReadAllText($imp, $utf8).Replace("mipmaps/generate=false", "mipmaps/generate=true")
            [IO.File]::WriteAllText($imp, $t, $utf8)
        }
        $total++
    }
    $d.w = [double]$d.w + 2 * $pad
    $d.h = [double]$d.h + 2 * $pad
    $d.xo = [double]$d.xo + $pad
    $d.yo = [double]$d.yo + $pad
    $d.bl = [double]$d.bl + $pad
    $d.bt = [double]$d.bt + $pad
    $d.br = [double]$d.br + $pad
    $d.bb = [double]$d.bb + $pad
    $d | Add-Member -NotePropertyName pad -NotePropertyValue $pad -Force
    $msg = "$nome  n=$n pad=$pad"
    if ($blocos.Count -gt 0) { $msg += "  reconstruidos: " + ($blocos -join " ") }
    $msg
}
[IO.File]::WriteAllText((Join-Path $raiz "assets\data\sprites.json"), ($json | ConvertTo-Json -Depth 5 -Compress), $utf8)
"quadros tratados: $total  (reconstruidos de pixel-art em blocos: $reconstruidos)"
