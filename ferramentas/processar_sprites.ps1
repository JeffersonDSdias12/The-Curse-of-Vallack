# =====================================================================
#  Tratamento visual dos sprites de personagens, inimigos e boss
#  (versão PC / GameMaker).
#  Lê sempre os ORIGINAIS (ferramentas/_originais_sprites), então pode
#  rodar de novo. Feche o projeto no GameMaker antes de rodar.
#  Uso:  powershell -File ferramentas/processar_sprites.ps1
#
#  Em cada quadro: suaviza os quadros "quadriculados", tira o halo e os
#  pontos soltos da borda, dá nitidez/contraste/cor e desenha um contorno
#  escuro em volta do corpo. A imagem ganha "pad" px de cada lado; a origem
#  e a caixa de colisão andam junto, então nada muda de lugar no jogo.
# =====================================================================
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot      # pasta do projeto GameMaker
$spr = Join-Path $raiz "sprites"
$orig = Join-Path $PSScriptRoot "_originais_sprites"
$utf8 = New-Object System.Text.UTF8Encoding($false)

Add-Type -ReferencedAssemblies System.Drawing -Path (Join-Path $PSScriptRoot "ProcSprite.cs")

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

# Origem horizontal de cada animação do herói no centro do tronco (medido nos
# quadros originais). Antes a origem ficava fora do corpo: ao virar de lado o
# desenho espelhava em volta de um ponto deslocado e o herói "pulava" alguns
# pixels, e trocar de animação (parado -> correndo) também mexia o corpo.
$centros = @{
    "spr_player" = 68; "spr_player_idle" = 63; "spr_player_run" = 62; "spr_player_jump" = 87;
    "spr_player_fall" = 88; "spr_player_dano" = 77; "spr_player_morte" = 76; "spr_player_defendendo" = 80;
    "spr_player_ataque" = 65; "spr_player_especial" = 65; "spr_player_agaichar" = 68;
    "spr_player_atacar_agaichado" = 117; "spr_player_atacar_agaichado_especial" = 74
}

function Num($t, $campo) { return [int][regex]::Match($t, '"' + $campo + '":(-?\d+)').Groups[1].Value }
function Trocar($t, $campo, $v) { return [regex]::Replace($t, '"' + $campo + '":-?\d+(\.\d+)?', '"' + $campo + '":' + $v) }

$total = 0
$suavizados = 0
foreach ($d in Get-ChildItem $spr -Directory) {
    $nome = $d.Name
    $fam = $null
    foreach ($f in $familias) { if ($nome -match $f[0]) { $fam = $f; break } }
    if ($fam -eq $null) { continue }
    $pad = [int]$fam[1]
    $yy = Join-Path $d.FullName "$nome.yy"
    $bak = Join-Path $orig $nome

    # ----- cópia dos originais (só na primeira vez) -----
    if (-not (Test-Path (Join-Path $bak "$nome.yy"))) {
        New-Item -ItemType Directory -Force $bak | Out-Null
        Copy-Item $yy $bak
        Copy-Item (Join-Path $d.FullName "*.png") $bak
    }

    $t = [IO.File]::ReadAllText((Join-Path $bak "$nome.yy"), $utf8)
    $quadros = [regex]::Matches($t, '"\$GMSpriteFrame":"v1","%Name":"([0-9a-f-]+)"') | ForEach-Object { $_.Groups[1].Value }
    $camada = [regex]::Match($t, '"\$GMImageLayer":"","%Name":"([0-9a-f-]+)"').Groups[1].Value
    $blocos = @()
    foreach ($q in $quadros) {
        $w = 0; $h = 0
        $px = [ProcSprite]::Carregar((Join-Path $bak "$q.png"), [ref]$w, [ref]$h)
        $s = [ProcSprite]::Reconstruir($px, $w, $h)
        if ($s -gt 1) { $suavizados++; $blocos += "$s" }
        elseif ([int]$fam[6] -gt 1) {
            [ProcSprite]::Suavizar($px, $w, $h, [double]$fam[6])
            $suavizados++
            $blocos += "~$($fam[6])"
        }
        [ProcSprite]::Limpar($px, $w, $h, [double]$fam[5])
        [ProcSprite]::Realcar($px, $w, $h, [double]$fam[2], [double]$fam[3], [double]$fam[4])
        $nw = 0; $nh = 0
        $o = [ProcSprite]::Contornar($px, $w, $h, $pad, 14, 7, 9, [ref]$nw, [ref]$nh)
        # o quadro composto e a camada única (a IDE edita pela camada)
        [ProcSprite]::Salvar((Join-Path $d.FullName "$q.png"), $o, $nw, $nh)
        $dl = Join-Path $d.FullName "layers\$q"
        New-Item -ItemType Directory -Force $dl | Out-Null
        [ProcSprite]::Salvar((Join-Path $dl "$camada.png"), $o, $nw, $nh)
        $total++
    }

    # tamanho, origem e caixa de colisão andam "pad" px (caixa manual: o
    # contorno não aumenta a colisão)
    $xo = (Num $t "xorigin") + $pad
    if ($centros.ContainsKey($nome)) { $xo = $centros[$nome] + $pad }
    $t = Trocar $t "width" ((Num $t "width") + 2 * $pad)
    $t = Trocar $t "height" ((Num $t "height") + 2 * $pad)
    foreach ($b in "bbox_left", "bbox_right", "bbox_top", "bbox_bottom") { $t = Trocar $t $b ((Num $t $b) + $pad) }
    $t = Trocar $t "bboxMode" 2
    $t = Trocar $t "xorigin" $xo
    $t = Trocar $t "yorigin" ((Num $t "yorigin") + $pad)
    [IO.File]::WriteAllText($yy, $t, $utf8)
    $msg = "$nome  n=$($quadros.Count) pad=$pad origem=($xo,$(Num $t 'yorigin'))"
    if ($blocos.Count -gt 0) { $msg += "  suavizados: " + ($blocos -join " ") }
    $msg
}
"quadros tratados: $total  (suavizados: $suavizados)"
