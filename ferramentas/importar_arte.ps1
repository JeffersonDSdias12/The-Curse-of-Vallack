# =====================================================================
#  Importa a arte da equipe (ferramentas/_arte_equipe) para o jogo:
#  GameMaker (PC, pasta sprites/) e Godot (Android, godot/assets/sprites).
#  Feche o projeto no GameMaker antes de rodar.
#  Uso:  powershell -File ferramentas/importar_arte.ps1 [-So spr_a,spr_b] [-Medir]
#
#  Cada animação é montada assim:
#   * a folha é cortada onde há menos tinta entre as poses (ImportaArte.cs)
#   * os pedaços da pose vizinha saem da célula
#   * a arte HD é reduzida por área para a escala do personagem (a MESMA em
#     todas as animações dele: "ref" é a altura do corpo em pé naquela folha)
#   * a pixel art é ampliada com EPX
#   * todos os quadros vão para uma tela comum com os pés na origem e o
#     centro do corpo na mesma coluna (o corpo não pula entre os quadros)
#   * a quantidade de quadros segue a tabela de golpes / IA de cada sprite
#     (scr_combate e Step dos inimigos usam o número do quadro)
# =====================================================================
param([string[]]$So = @(), [switch]$Medir, [string]$Dump = "", [string]$Previa = "", [double]$Zoom = 1, [switch]$Cabecas)
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$fonte = Join-Path $PSScriptRoot "_arte_equipe"
$gmSpr = Join-Path $raiz "sprites"
$gdSpr = Join-Path $raiz "godot\assets\sprites"
$gdJson = Join-Path $raiz "godot\assets\data\sprites.json"
$yyp = Join-Path $raiz "The Curse of Vallack.yyp"
$utf8 = New-Object System.Text.UTF8Encoding($false)

Add-Type -ReferencedAssemblies System.Drawing -Path @((Join-Path $PSScriptRoot "ProcSprite.cs"), (Join-Path $PSScriptRoot "ImportaArte.cs"))

# ---------------------------------------------------------------------
# fontes
# ---------------------------------------------------------------------
# acha um caminho por partes com curinga (os nomes têm acento)
function Achar([string]$rel) {
    $p = $fonte
    foreach ($parte in $rel.Split('\')) {
        $c = Get-ChildItem -LiteralPath $p -Filter $parte | Select-Object -First 1
        if ($null -eq $c) { throw "Não achei '$parte' em $p" }
        $p = $c.FullName
    }
    return $p
}

$cache = @{}
function Imagem([string]$arq) {
    if (-not $cache.ContainsKey($arq)) {
        $w = 0; $h = 0
        $px = [ProcSprite]::Carregar($arq, [ref]$w, [ref]$h)
        $cache[$arq] = @{ px = $px; w = $w; h = $h }
    }
    return $cache[$arq]
}

# folha com "lin" linhas e "col" colunas (col pode ser uma lista por linha)
function Folha([string]$rel, $col, [int]$lin = 1) {
    $arq = Achar $rel
    $im = Imagem $arq
    $cl = [ImportaArte]::Cortes($im.px, $im.w, $im.h, 0, 0, $im.w, $im.h, $lin, $false)
    $q = @()
    for ($i = 0; $i -lt $lin; $i++) {
        $nc = if ($col -is [array]) { $col[$i] } else { $col }
        $cc = [ImportaArte]::CortesCorpo($im.px, $im.w, $im.h, 0, $cl[$i], $im.w, $cl[$i + 1], $nc)
        $xs = $null; $ws = $null
        $fr = [ImportaArte]::Separar($im.px, $im.w, $im.h, $cl[$i], $cl[$i + 1], $cc, [ref]$xs, [ref]$ws)
        for ($j = 0; $j -lt $nc; $j++) {
            $q += , @{ px = $fr[$j]; w = $ws[$j]; h = $cl[$i + 1] - $cl[$i]; celX = ($cc[$j] + $cc[$j + 1]) / 2.0 - $xs[$j] }
        }
    }
    return , $q
}

# a mesma lista de quadros com a altura de referência própria (folhas misturadas)
function ComRef($q, [double]$ref) {
    $o = @()
    foreach ($f in $q) { $c = $f.Clone(); $c.ref = $ref; $o += , $c }
    return , $o
}

# quadros soltos (um arquivo por quadro), em ordem numérica; "largura" filtra as tiras
function Arquivos([string]$rel, [int]$largura = 0) {
    $pasta = Achar $rel
    $q = @()
    $lista = Get-ChildItem -LiteralPath $pasta -File -Filter *.png |
        Sort-Object @{ e = { $m = [regex]::Matches($_.BaseName, '\d+'); if ($m.Count) { [int]$m[$m.Count - 1].Value } else { 0 } } }, Name
    foreach ($f in $lista) {
        $im = Imagem $f.FullName
        if ($largura -gt 0 -and $im.w -ne $largura) { continue }
        $q += , @{ px = $im.px; w = $im.w; h = $im.h; celX = $im.w / 2.0 }
    }
    return , $q
}

# ---------------------------------------------------------------------
# montagem de uma animação
# a: nome, q (quadros da fonte), sel (índices), alvo (altura do corpo em pé
#    na saída, px), ref (altura do corpo em pé na folha, px da fonte),
#    amp (pixel art: ampliação inteira), k, pad, spd, faixa (alturas do
#    corpo usadas para o centro), ancora ("corpo" | "celula" | "pes")
# ---------------------------------------------------------------------
function Montar($a) {
    $sel = if ($a.ContainsKey("sel")) { @($a.sel) } else { 0..($a.q.Count - 1) }
    # v1.13: a origem fica no centro do TRONCO (o que o olho segue; sem lâmina nem
    # rastro): o desenho espelha em volta dele ao virar de lado sem o corpo pular
    $faixa = if ($a.faixa) { $a.faixa } else { @(0.45, 0.8) }
    $ancora = if ($a.ancora) { $a.ancora } else { "corpo" }
    $pad = if ($null -ne $a.pad) { [int]$a.pad } else { 0 }
    [ImportaArte]::SoAlfa = [bool]$a.soAlfa
    $itens = @()
    $refSaida = 0
    foreach ($i in $sel) {
        $f = $a.q[$i]
        $cw = $f.w; $ch = $f.h
        $c = $f.px.Clone()
        [ImportaArte]::LimparVizinhos($c, $cw, $ch, 0.002, $false)
        if ($a.semRastro) { [ImportaArte]::TirarRastro($c, $cw, $ch) }
        $l = 0; $t = 0; $nw = 0; $nh = 0
        $c = [ImportaArte]::Aparar($c, $cw, $ch, [ref]$l, [ref]$t, [ref]$nw, [ref]$nh)
        # posição do recorte dentro da célula (âncora "celula")
        $celX = $f.celX - $l; $celY = $ch - $t
        if ($a.amp) {
            $e = [int]$a.amp
            $ow = 0; $oh = 0
            $c = [ImportaArte]::Ampliar($c, $nw, $nh, $e, [ref]$ow, [ref]$oh)
            $s = [double]$e
        }
        else {
            $r = if ($f.ref) { [double]$f.ref } else { [double]$a.ref }
            $s = [double]$a.alvo / $r
            $ow = 0; $oh = 0
            $c = [ImportaArte]::Reduzir($c, $nw, $nh, $s, [ref]$ow, [ref]$oh)
            if ($a.nitidez) { [ProcSprite]::Realcar($c, $ow, $oh, [double]$a.nitidez, 1.03, 1.04) }
        }
        if ($a.tom) { [ImportaArte]::Tom($c, [double]$a.tom[0], [double]$a.tom[1]) }
        $altRef = if ($a.amp) { [double]$a.alvo } else { [double]$a.alvo }
        $base = [ImportaArte]::Base($c, $ow, $oh)
        $cx = [ImportaArte]::Centro($c, $ow, $oh, $base, $altRef, [double]$faixa[0], [double]$faixa[1])
        switch ($ancora) {
            "celula" { $cx = $celX * $s; $base = [math]::Min($oh - 1, $celY * $s - 1) }
            "pes" { $cx = [ImportaArte]::Centro($c, $ow, $oh, $base, $altRef, 0.0, 0.12) }
            "caixa" { $cx = $ow / 2.0; $base = $oh - 1 }
        }
        if ($a.dx) { $cx -= [double]$a.dx[$itens.Count % $a.dx.Count] }
        $itens += , @{ px = $c; w = $ow; h = $oh; cx = $cx; base = $base }
    }
    # REGISTRO: cada quadro anda até a cabeça e o tronco ficarem em cima dos do
    # 1º quadro (sem isso o corpo "pulava" a cada quadro: teletransporte)
    $registrar = if ($a.ContainsKey("registrar")) { [bool]$a.registrar } else { $true }
    if ($registrar -and $ancora -eq "corpo" -and $itens.Count -gt 1) {
        $i0 = $itens[0]
        $maxd = [int]([double]$a.alvo * 0.3)
        $soma = 0.0
        for ($j = 1; $j -lt $itens.Count; $j++) {
            $it = $itens[$j]
            $dx = [ImportaArte]::Registrar($i0.px, $i0.w, $i0.h, $i0.cx, $i0.base, $it.px, $it.w, $it.h, $it.cx, $it.base, [double]$a.alvo, 0.42, 0.85, $maxd)
            $it.cx -= $dx
            $soma += $dx
        }
        # o conjunto inteiro fica com o tronco MÉDIO na origem (não só o do 1º
        # quadro): em qualquer quadro em que virar, o corpo pula o mínimo
        $media = $soma / $itens.Count
        foreach ($it in $itens) { $it.cx += $media }
    }
    # âncora "celula": todos os quadros alinhados pela célula, mas o conjunto
    # centrado no corpo do primeiro quadro
    if ($ancora -eq "celula") {
        $c0 = [ImportaArte]::Centro($itens[0].px, $itens[0].w, $itens[0].h, $itens[0].base, [double]$a.alvo, [double]$faixa[0], [double]$faixa[1])
        $d = $itens[0].cx - $c0
        foreach ($it in $itens) { $it.cx -= $d }
    }
    # tela comum
    $esq = 0; $dir = 0; $cima = 0; $baixo = 0
    foreach ($it in $itens) {
        $esq = [math]::Max($esq, [math]::Ceiling($it.cx))
        $dir = [math]::Max($dir, [math]::Ceiling($it.w - $it.cx))
        $cima = [math]::Max($cima, $it.base + 1)
        $baixo = [math]::Max($baixo, $it.h - $it.base - 1)
    }
    $W = [int]($esq + $dir + 2 * $pad); $H = [int]($cima + $baixo + 2 * $pad)
    $xo = [int]($esq + $pad); $yo = [int]($cima + $pad)
    $quadros = @()
    foreach ($it in $itens) {
        $tela = [ImportaArte]::Vazio($W, $H)
        [ImportaArte]::Colar($tela, $W, $H, $it.px, $it.w, $it.h, [int][math]::Round($xo - $it.cx), [int]($yo - $it.base - 1))
        if ($pad -gt 0) {
            # contorno escuro fino (o mesmo dos outros personagens)
            $mw = 0; $mh = 0
            $inner = [ImportaArte]::Regiao($tela, $W, $H, $pad, $pad, $W - $pad, $H - $pad)
            $tela = [ProcSprite]::Contornar($inner, $W - 2 * $pad, $H - 2 * $pad, $pad, 14, 7, 9, [ref]$mw, [ref]$mh)
        }
        $quadros += , $tela
    }
    # caixa (união dos quadros)
    $bl = $W; $bt = $H; $br = 0; $bb = 0
    foreach ($qd in $quadros) {
        $cx = [ImportaArte]::Caixa($qd, $W, $H)
        $bl = [math]::Min($bl, $cx[0]); $bt = [math]::Min($bt, $cx[1]); $br = [math]::Max($br, $cx[2]); $bb = [math]::Max($bb, $cx[3])
    }
    return @{ nome = $a.nome; quadros = $quadros; w = $W; h = $H; xo = $xo; yo = $yo; bl = $bl; bt = $bt; br = $br; bb = $bb;
        spd = [double]$a.spd; k = [double]$a.k; pad = $pad; pasta = $a.pasta }
}

# ---------------------------------------------------------------------
# gravação: GameMaker
# ---------------------------------------------------------------------
function Guid() { return [guid]::NewGuid().ToString() }

function GravarGM($m) {
    $nome = $m.nome
    $dir = Join-Path $gmSpr $nome
    $yyArq = Join-Path $dir "$nome.yy"
    $pai = @{ name = "Sprites"; path = "folders/Sprites.yy" }
    $tg = "Default"
    $novo = -not (Test-Path $yyArq)
    if (-not $novo) {
        $old = [IO.File]::ReadAllText($yyArq, $utf8)
        $mp = [regex]::Match($old, '"parent":\{\s*"name":"([^"]*)",\s*"path":"([^"]*)"')
        if ($mp.Success) { $pai = @{ name = $mp.Groups[1].Value; path = $mp.Groups[2].Value } }
        $mt = [regex]::Match($old, '"textureGroupId":\{\s*"name":"([^"]*)"')
        if ($mt.Success) { $tg = $mt.Groups[1].Value }
        # apaga os quadros antigos
        Get-ChildItem $dir -File -Filter *.png | Remove-Item -Force
        if (Test-Path (Join-Path $dir "layers")) { Remove-Item (Join-Path $dir "layers") -Recurse -Force }
    }
    elseif ($m.irmao) {
        # sprite nova: mesma pasta e grupo de textura de uma sprite parecida
        $old = [IO.File]::ReadAllText((Join-Path $gmSpr "$($m.irmao)\$($m.irmao).yy"), $utf8)
        $mp = [regex]::Match($old, '"parent":\{\s*"name":"([^"]*)",\s*"path":"([^"]*)"')
        if ($mp.Success) { $pai = @{ name = $mp.Groups[1].Value; path = $mp.Groups[2].Value } }
        $mt = [regex]::Match($old, '"textureGroupId":\{\s*"name":"([^"]*)"')
        if ($mt.Success) { $tg = $mt.Groups[1].Value }
    }
    New-Item -ItemType Directory -Force $dir | Out-Null
    $camada = Guid
    $nomesQ = @()
    foreach ($qd in $m.quadros) {
        $g = Guid
        $nomesQ += $g
        [ProcSprite]::Salvar((Join-Path $dir "$g.png"), $qd, $m.w, $m.h)
        $dl = Join-Path $dir "layers\$g"
        New-Item -ItemType Directory -Force $dl | Out-Null
        [ProcSprite]::Salvar((Join-Path $dl "$camada.png"), $qd, $m.w, $m.h)
    }
    $sb = New-Object System.Text.StringBuilder
    $fr = ($nomesQ | ForEach-Object { "    {""`$GMSpriteFrame"":""v1"",""%Name"":""$_"",""name"":""$_"",""resourceType"":""GMSpriteFrame"",""resourceVersion"":""2.0"",}," }) -join "`n"
    $kf = @()
    for ($i = 0; $i -lt $nomesQ.Count; $i++) {
        $kf += "            {""`$Keyframe<SpriteFrameKeyframe>"":"""",""Channels"":{`n                ""0"":{""`$SpriteFrameKeyframe"":"""",""Id"":{""name"":""$($nomesQ[$i])"",""path"":""sprites/$nome/$nome.yy"",},""resourceType"":""SpriteFrameKeyframe"",""resourceVersion"":""2.0"",},`n              },""Disabled"":false,""id"":""$(Guid)"",""IsCreationKey"":false,""Key"":$i.0,""Length"":1.0,""resourceType"":""Keyframe<SpriteFrameKeyframe>"",""resourceVersion"":""2.0"",""Stretch"":false,},"
    }
    $n = $nomesQ.Count
    $spd = ([double]$m.spd).ToString([Globalization.CultureInfo]::InvariantCulture)
    if ($spd -notmatch '\.') { $spd += ".0" }
    $t = @"
{
  "`$GMSprite":"v2",
  "%Name":"$nome",
  "bboxMode":2,
  "bbox_bottom":$($m.bb),
  "bbox_left":$($m.bl),
  "bbox_right":$($m.br),
  "bbox_top":$($m.bt),
  "collisionKind":1,
  "collisionTolerance":0,
  "DynamicTexturePage":false,
  "edgeFiltering":false,
  "For3D":false,
  "frames":[
$fr
  ],
  "gridX":0,
  "gridY":0,
  "height":$($m.h),
  "HTile":false,
  "layers":[
    {"`$GMImageLayer":"","%Name":"$camada","blendMode":0,"displayName":"default","isLocked":false,"name":"$camada","opacity":100.0,"resourceType":"GMImageLayer","resourceVersion":"2.0","visible":true,},
  ],
  "name":"$nome",
  "nineSlice":null,
  "origin":9,
  "parent":{
    "name":"$($pai.name)",
    "path":"$($pai.path)",
  },
  "preMultiplyAlpha":false,
  "resourceType":"GMSprite",
  "resourceVersion":"2.0",
  "sequence":{
    "`$GMSequence":"v1",
    "%Name":"$nome",
    "autoRecord":true,
    "backdropHeight":768,
    "backdropImageOpacity":0.5,
    "backdropImagePath":"",
    "backdropWidth":1366,
    "backdropXOffset":0.0,
    "backdropYOffset":0.0,
    "events":{
      "`$KeyframeStore<MessageEventKeyframe>":"",
      "Keyframes":[],
      "resourceType":"KeyframeStore<MessageEventKeyframe>",
      "resourceVersion":"2.0",
    },
    "eventStubScript":null,
    "eventToFunction":{},
    "length":$n.0,
    "lockOrigin":false,
    "moments":{
      "`$KeyframeStore<MomentsEventKeyframe>":"",
      "Keyframes":[],
      "resourceType":"KeyframeStore<MomentsEventKeyframe>",
      "resourceVersion":"2.0",
    },
    "name":"$nome",
    "playback":1,
    "playbackSpeed":$spd,
    "playbackSpeedType":0,
    "resourceType":"GMSequence",
    "resourceVersion":"2.0",
    "showBackdrop":true,
    "showBackdropImage":false,
    "timeUnits":1,
    "tracks":[
      {"`$GMSpriteFramesTrack":"","builtinName":0,"events":[],"inheritsTrackColour":true,"interpolation":1,"isCreationTrack":false,"keyframes":{"`$KeyframeStore<SpriteFrameKeyframe>":"","Keyframes":[
$($kf -join "`n")
          ],"resourceType":"KeyframeStore<SpriteFrameKeyframe>","resourceVersion":"2.0",},"modifiers":[],"name":"frames","resourceType":"GMSpriteFramesTrack","resourceVersion":"2.0","spriteId":null,"trackColour":0,"tracks":[],"traits":0,},
    ],
    "visibleRange":null,
    "volume":1.0,
    "xorigin":$($m.xo),
    "yorigin":$($m.yo),
  },
  "swatchColours":null,
  "swfPrecision":0.5,
  "textureGroupId":{
    "name":"$tg",
    "path":"texturegroups/$tg",
  },
  "type":0,
  "VTile":false,
  "width":$($m.w),
}
"@
    [IO.File]::WriteAllText($yyArq, $t.Replace("`r`n", "`n"), $utf8)
    if ($novo) {
        $p = [IO.File]::ReadAllText($yyp, $utf8)
        if ($p -notmatch [regex]::Escape("sprites/$nome/$nome.yy")) {
            $p = $p -replace '("resources":\[\r?\n)', "`$1    {""id"":{""name"":""$nome"",""path"":""sprites/$nome/$nome.yy"",},},`n"
            [IO.File]::WriteAllText($yyp, $p, $utf8)
        }
    }
}

# ---------------------------------------------------------------------
# gravação: Godot (PNG por quadro + sprites.json com a escala HD "k")
# ---------------------------------------------------------------------
$json = [IO.File]::ReadAllText($gdJson, $utf8) | ConvertFrom-Json

function GravarGD($m) {
    $dir = Join-Path $gdSpr $m.nome
    New-Item -ItemType Directory -Force $dir | Out-Null
    for ($i = 0; $i -lt $m.quadros.Count; $i++) {
        [ProcSprite]::Salvar((Join-Path $dir "$i.png"), $m.quadros[$i], $m.w, $m.h)
    }
    # quadros que sobraram da versão anterior
    Get-ChildItem $dir -File | Where-Object { $_.Name -match '^(\d+)\.png(\.import)?$' -and [int]$Matches[1] -ge $m.quadros.Count } | Remove-Item -Force
    $d = [pscustomobject]@{ bb = $m.bb; bl = $m.bl; br = $m.br; bt = $m.bt; h = $m.h; n = $m.quadros.Count; spd = $m.spd; spdt = 0.0;
        w = $m.w; xo = $m.xo; yo = $m.yo; pad = $m.pad; k = $m.k }
    $json | Add-Member -NotePropertyName $m.nome -NotePropertyValue $d -Force
}

# ---------------------------------------------------------------------
# medição (para calibrar "ref"): altura do corpo de cada quadro na fonte
# ---------------------------------------------------------------------
function MedirQ($titulo, $q, $dump) {
    $lin = @()
    for ($i = 0; $i -lt $q.Count; $i++) {
        $f = $q[$i]
        $cw = $f.w; $ch = $f.h
        $c = $f.px.Clone()
        [ImportaArte]::LimparVizinhos($c, $cw, $ch, 0.002, $false)
        $l = 0; $t = 0; $nw = 0; $nh = 0
        $c = [ImportaArte]::Aparar($c, $cw, $ch, [ref]$l, [ref]$t, [ref]$nw, [ref]$nh)
        $cab = [ImportaArte]::Rosto($c, $nw, $nh)
        $lin += "$i=${nw}x${nh}(r$($cab[0]))"
        if ($dump) {
            $ow = 0; $oh = 0
            $r = [ImportaArte]::Reduzir($c, $nw, $nh, 0.4, [ref]$ow, [ref]$oh)
            [ProcSprite]::Salvar((Join-Path $dump ("{0}_{1:00}.png" -f $titulo, $i)), $r, $ow, $oh)
        }
    }
    "{0}: {1}" -f $titulo, ($lin -join "  ")
}

# =====================================================================
# TABELA DAS ANIMAÇÕES
# =====================================================================
$heroi = "Alex\Sprites\Personagem Principal"
$javali = "Alex\Sprites\Inimigo (Homem-Porco)"
$aranha = "Alex\Sprites\Inimigo Mulher-Aranha"
$edu = "Eduardo\Sprites"

# folhas do herói (HD do Alex)
$H = @{
    parado   = Folha "$heroi\Parado\Op*1.png" 8
    corrida  = Folha "$heroi\Correndo\Folha*.png" 12
    pulo     = Folha "$heroi\Pulando\Imagem*.png" 7
    ataque   = Folha "$heroi\Atacando\Seq*.png" 8 2
    aereo    = Folha "$heroi\Ataque no ar\Seq*.png" 6
    golpeAr  = Folha "$heroi\Ataque no ar\Spritesheet*.png" 12
    baixo    = Folha "$heroi\Ataque abaixado\Ataque normal*.png" 6
    baixoEsp = Folha "$heroi\Ataque abaixado\Ataque especial*.png" 7
    defesa   = Folha "$heroi\Defendendo\Cavaleiro defendendo.png" 7
    agachar  = Folha "$heroi\Abaixando\Sprite*.png" 6
    queda    = Folha "$heroi\Morrendo\Seq*.png" 10
}
$J = @{
    parado  = Arquivos "$javali\Parado"
    andando = Arquivos "$javali\Andando"
    correndo = Arquivos "$javali\Correndo"
    golpe   = Folha "$javali\Atacando\Sprite de Golpe*.png" 5 2
    salto   = Folha "$javali\Saltando_\Sprite*.png" 5 2
    morte   = Folha "$javali\Morrendo\Morrendo.png" 5 2
}

if ($Medir) {
    if ($Dump) { New-Item -ItemType Directory -Force $Dump | Out-Null }
    foreach ($k in $H.Keys) { MedirQ "heroi.$k" $H[$k] $Dump }
    foreach ($k in $J.Keys) { MedirQ "javali.$k" $J[$k] $Dump }
    foreach ($x in @('Parada\Seq*.png', 'Andando\Sprite*.png', 'Atacando\Mulher-aranha em ataque*.png')) { MedirQ "aranha.$x" (Folha "$aranha\$x" 4) $Dump }
    return
}

# ----- HERÓI (Twilight): corpo em pé = 162 px na sprite (k = 3, desenhado
# a 1,25x = ~67 px no mundo, a altura da máscara). "ref" = altura do corpo
# em pé em cada folha (cada folha desenha o herói num tamanho). Os quadros
# seguem a tabela de golpes do scr_combate (q = quadro). -----
$aH = 162
# altura do corpo em pé em cada folha: altura do quadro de referência / fração da
# pose (correndo ~0,93; base de luta ~0,8; agachado ~0,6). O rosto errava nas folhas
# em que o herói é pequeno (o salto com golpe saía 25% maior).
$rH = @{ parado = 483; corrida = 342; pulo = 362; ataque = 282; aereo = 400; baixo = 400; baixoEsp = 390; defesa = 410; agachar = 494; golpeAr = 310; queda = 348 }
$heroiTab = @(
    @{ nome = "spr_player_idle"; q = $H.parado; ref = $rH.parado; spd = 7 }
    @{ nome = "spr_player"; q = $H.parado; sel = @(0); ref = $rH.parado; spd = 2 }
    @{ nome = "spr_player_run"; q = $H.corrida; ref = $rH.corrida; spd = 24; semRastro = $true }
    # pulo: começa no quadro 1 e segura o 4 (alto do pulo); queda: 0-2 em loop, 3 = pouso
    @{ nome = "spr_player_jump"; q = $H.pulo; sel = @(1, 2, 2, 3, 3); ref = $rH.pulo; spd = 6 }
    @{ nome = "spr_player_fall"; q = $H.pulo; sel = @(4, 4, 4, 0); ref = $rH.pulo; spd = 6 }
    @{ nome = "spr_player_dano"; q = $H.queda; sel = @(0, 1, 2, 1); ref = $rH.queda; spd = 8 }
    @{ nome = "spr_player_morte"; q = $H.queda; ref = $rH.queda; spd = 9; faixa = @(0.0, 0.3); registrar = $false }
    # defesa em loop só com as poses de guarda (o aparar pula para o quadro 2)
    @{ nome = "spr_player_defendendo"; q = $H.defesa; sel = @(2, 3, 3, 5, 5, 3); ref = $rH.defesa; spd = 10 }
    # CORTE / CORTE DUPLO / CONTRA / LÂMINA: q2-q4 acertam
    @{ nome = "spr_player_ataque"; q = $H.ataque; sel = @(1, 2, 3, 4, 6, 7); ref = $rH.ataque; spd = 15; semRastro = $true }
    # CORTE AÉREO (novo: antes usava o corte no chão)
    @{ nome = "spr_player_ataque_ar"; q = $H.aereo; ref = $rH.aereo; spd = 15; semRastro = $true; irmao = "spr_player_ataque" }
    # ONDA CARMESIM / IRA: q0 carga, q1-q4 golpes, q5 volta
    @{ nome = "spr_player_especial"; q = $H.ataque; sel = @(14, 10, 9, 11, 12, 15); ref = $rH.ataque; spd = 8; semRastro = $true }
    @{ nome = "spr_player_agaichar"; q = $H.agachar; sel = @(5); ref = $rH.agachar; spd = 10 }
    # RASTEIRA / CHAMA DE SYLLA
    @{ nome = "spr_player_atacar_agaichado"; q = $H.baixo; ref = $rH.baixo; spd = 10; semRastro = $true }
    # ONDA agachado (o 7º quadro não é usado pela tabela)
    @{ nome = "spr_player_atacar_agaichado_especial"; q = $H.baixoEsp; sel = @(0, 1, 2, 4, 5, 6, 6); ref = $rH.baixoEsp; spd = 10; semRastro = $true }
    # SALTO DO CARRASCO / EXECUÇÃO / MERGULHO / LANÇADOR / FINALIZADOR:
    # 0-1 preparo, 2 salto, 3-5 no ar, 6 descendo, 7 desce até o chão, 8 impacto, 9-11 volta
    @{ nome = "spr_ataque_2"; q = $H.golpeAr; sel = @(0, 1, 2, 3, 4, 5, 6, 8, 10, 10, 11, 11); ref = $rH.golpeAr; spd = 6; semRastro = $true }
    # TREMOR: 0 zoom, 1-3 carga, 4 carga máxima, 5 desce, 6 crava a espada, 7 fim
    @{ nome = "spr_ataque_03"; q = $H.ataque; sel = @(15, 14, 14, 2, 2, 11, 13, 13); ref = $rH.ataque; spd = 10; semRastro = $true }
    # QUEDA CARMESIM: 0 zoom, 1 salto, 2-3 sobe, 4 alto, 5 mergulho, 6 impacto, 7 faíscas
    @{ nome = "spr_ataque_especial_2"; q = ((ComRef $H.golpeAr $rH.golpeAr) + (ComRef $H.ataque $rH.ataque)); sel = @(0, 2, 3, 4, 4, 6, 25, 25); ref = $rH.golpeAr; spd = 10; semRastro = $true }
)
foreach ($a in $heroiTab) { $a.alvo = $aH; $a.k = 3; $a.pad = 2; if (-not $a.nitidez) { $a.nitidez = 0.3 } }

# ----- HOMEM-PORCO (besta e mini-boss): corpo em pé = 210 px (k = 3, ~70 px no mundo) -----
$aJ = 210
$javaliTab = @(
    @{ nome = "spr_inimigo01_parado"; q = $J.parado; sel = @(0, 1, 2, 1); ref = 1253; spd = 3 }
    @{ nome = "spr_inimigo01_andar"; q = $J.andando; ref = 1080; spd = 6 }
    @{ nome = "spr_inimigo01_correndo"; q = $J.correndo; ref = 1020; spd = 10 }
    # IA: o golpe acerta a partir do quadro 2
    @{ nome = "spr_inimigo01_atacando"; q = $J.golpe; ref = 330; spd = 30; semRastro = $true }
    # IA: segura o quadro 5 no ar
    @{ nome = "spr_inimigo01_pulando"; q = $J.salto; ref = 335; spd = 10 }
    @{ nome = "spr_inimigo01_morrendo"; q = $J.morte; sel = @(0, 1, 2, 3, 4, 5, 6, 7, 9); ref = 360; spd = 10; faixa = @(0.0, 0.3); registrar = $false }
)
foreach ($a in $javaliTab) { $a.alvo = $aJ; $a.k = 3; $a.pad = 2; if (-not $a.nitidez) { $a.nitidez = 0.3 } }

# ----- MULHER-ARANHA (folhas HD do Alex, k = 3; desenhada a 1,45x como antes:
# corpo de ~47 px = 141 px na sprite) -----
$A = @{
    parada  = Folha "$aranha\Parada\Seq*.png" 4
    andando = Folha "$aranha\Andando\Sprite*.png" 4
    ataque  = Folha "$aranha\Atacando\Mulher-aranha em ataque*.png" 4
}
$aranhaTab = @(
    @{ nome = "spr_aranha_parada"; q = $A.parada; ref = 630; spd = 6 }
    @{ nome = "spr_aranha_andando"; q = $A.andando; ref = 630; spd = 10 }
    @{ nome = "spr_aranha_ataque"; q = $A.ataque; ref = 630; spd = 10 }
)
foreach ($a in $aranhaTab) { $a.alvo = 141; $a.k = 3; $a.pad = 2; $a.nitidez = 0.3 }
# ----- ESQUELETO ARQUEIRO (inimigo02; pixel art 40x58 -> 2x, k = 2) -----
$arq = "$edu\sprite esqueleto\esqueletos\Arqueiro"
$arqueiroTab = @(
    @{ nome = "spr_inimigo02_parado"; q = (Arquivos "$arq\Parado" 40); spd = 8 }
    @{ nome = "spr_inimigo02_correndo"; q = (Arquivos "$arq\Correndo" 40); spd = 8 }
    # IA: a flecha sai no quadro 5
    @{ nome = "spr_inimigo02_atacando"; q = (Arquivos "$arq\ataque" 40); spd = 5 }
    @{ nome = "spr_inimigo02_sofrendo_dano"; q = (Arquivos "$arq\Sofrendo*" 40); sel = @(0, 1, 2, 3, 4, 5, 6, 7); spd = 6 }
    @{ nome = "spr_inimigo02_morrendo"; q = (Arquivos "$arq\Morrendo" 40); spd = 5; faixa = @(0.0, 0.3); registrar = $false }
)
foreach ($a in $arqueiroTab) { $a.amp = 2; $a.alvo = 80; $a.k = 2; $a.pad = 2; $a.soAlfa = $true }      # ossos brancos: corpo pela opacidade

# ----- ESQUELETO GUERREIRO e PORCO CORROMPIDO (Eduardo; pixel art 40x58 / 40x60
# -> EPX 2x, k = 2, como antes). Os quadros antigos nunca tinham sido alinhados:
# o tronco do esqueleto oscilava até 17 px (ele "teletransportava" ao andar e
# ao virar). Quadros na ordem e na quantidade que a IA usa. -----
$gue = "$edu\sprite esqueleto\esqueletos\Guerreiro"
$por = "$edu\Porco corrompido"
$ossosTab = @(
    @{ nome = "spr_esqueleto_parado"; q = (Arquivos "$gue\Parado" 40); spd = 9 }
    @{ nome = "spr_esqueleto_andando"; q = (Arquivos "$gue\Andando" 40); spd = 10 }
    @{ nome = "spr_esqueleto_correndo"; q = (Arquivos "$gue\Corendo" 40); spd = 12 }
    @{ nome = "spr_esqueleto_ataque"; q = (Arquivos "$gue\Ataque" 40); spd = 12 }
    # IA: o dano volta ao quadro 1 depois do 7,9
    @{ nome = "spr_esqueleto_dano"; q = (Arquivos "$gue\Sofrendo Damage" 40); spd = 12 }
    @{ nome = "spr_esqueleto_morrendo"; q = (Arquivos "$gue\Morrendo" 40); sel = @(0, 1, 2, 3, 4, 5, 6, 7, 8); spd = 10; faixa = @(0.0, 0.3); registrar = $false }
    @{ nome = "spr_porco_parado"; q = (Arquivos "$por\parado" 40); spd = 6 }
    @{ nome = "spr_porco_correndo"; q = (Arquivos "$por\porco correndo" 40); sel = @(0, 1, 2, 3, 4, 5, 6, 7, 8, 9); spd = 14 }
    # IA: o golpe acerta a partir do quadro 2 (o desenho avisa antes do 9)
    @{ nome = "spr_porco_ataque"; q = (Arquivos "$por\porco ataque vermelho (normal)" 40); sel = @(0, 1, 2, 3, 4, 5, 6, 7, 8, 9); spd = 12 }
    # IA: a onda sai no quadro 3 (8 quadros)
    @{ nome = "spr_porco_roxo"; q = (Arquivos "$por\porco ataque especial roxo" 40); sel = @(0, 1, 2, 3, 4, 5, 6, 7); spd = 12 }
    # IA: segura o quadro 5 no ar
    @{ nome = "spr_porco_salto"; q = (Arquivos "$por\saltando" 40); sel = @(0, 1, 2, 3, 4, 5, 6, 7, 8, 9); spd = 12 }
    @{ nome = "spr_porco_furia"; q = (Arquivos "$por\porco em furia*" 40); sel = @(0, 1, 2, 3, 4, 5, 6, 7, 8, 9); spd = 12 }
    # IA: invoca no quadro 5
    @{ nome = "spr_porco_invocar"; q = (Arquivos "$por\invoca* 2" 40); sel = @(0, 1, 2, 3, 4, 5, 6, 7, 8, 9); spd = 12 }
    @{ nome = "spr_porco_morrendo"; q = (Arquivos "$por\morrendo" 40); spd = 10; faixa = @(0.0, 0.3); registrar = $false }
)
foreach ($a in $ossosTab) { $a.amp = 2; $a.k = 2; $a.pad = 2; $a.alvo = if ($a.nome -like "spr_porco*") { 92 } else { 80 }; $a.soAlfa = $a.nome -like "spr_esqueleto*" }      # alvo = altura do corpo em pé (2x)

# ----- ÁRVORE AMALDIÇOADA (chefe; pixel art 70x92 -> 4x, k = 4) -----
$arv = "$edu\sprite Arvore\sprites_arvores_70x92"
$inv = "$edu\invoca* arvore\sprites_arvore_invocacao_bola_de_fogo_70x92"
$chefeTab = @(
    # fases 1 e 2: a MESMA Árvore Amaldiçoada em todos os estados (antes ela virava
    # outra árvore ao atacar e parecia sumir); os brilhos do ataque são do código
    @{ nome = "spr_boss_01_parado"; q = (Arquivos "$arv\arvore_amaldicoada" 70); spd = 7 }
    # despertar, raízes, galho, transição e morte
    @{ nome = "spr_boss_01"; q = (Arquivos "$arv\arvore_amaldicoada" 70); spd = 6 }
    # bola de fogo: 10 quadros (a chama sai no quadro 6)
    @{ nome = "spr_boss_01_atacando"; q = (Arquivos "$arv\arvore_amaldicoada" 70); sel = @(0, 1, 2, 3, 4, 5, 6, 7, 8, 0); spd = 6 }
    # fase 3: "A CHAMA DE VALLACK TOMA A ÁRVORE" (a árvore em chamas)
    @{ nome = "spr_boss_fogo"; q = (Arquivos "$inv\arvore_invocacao" 70); spd = 6; irmao = "spr_boss_01" }
    @{ nome = "spr_boss_fogo_parado"; q = (Arquivos "$inv\arvore_invocacao" 70); sel = @(5, 6, 7, 8, 9, 8, 7, 6); spd = 7; irmao = "spr_boss_01" }
    @{ nome = "spr_boss_fogo_atacando"; q = (Arquivos "$inv\arvore_bola_de_fogo" 70); spd = 6; irmao = "spr_boss_01" }
)
foreach ($a in $chefeTab) { $a.amp = 4; $a.alvo = 360; $a.k = 4; $a.pad = 4; $a.ancora = "pes" }

# ----- MATO E PLANTAS (Eduardo, pixel art 20x20, balançam em 4 quadros) e a
# ÁRVORE ASSOMBRADA (decoração animada da estrada, 70x92 -> 4x) -----
$mp = "$edu\matos e plantas"
$plantasTab = @(
    @{ nome = "spr_mato_normal"; q = (Arquivos "$mp\mato_normal_20x20_nitido" 20); spd = 1; irmao = "spr_mato" }
    @{ nome = "spr_planta"; q = (Arquivos "$mp\planta_normal_20x20_nitido" 20); spd = 1; irmao = "spr_mato" }
    @{ nome = "spr_planta_maldita"; q = (Arquivos "$mp\planta_amaldicoada_20x20_nitido" 20); spd = 1; irmao = "spr_mato" }
)
foreach ($a in $plantasTab) { $a.amp = 1; $a.alvo = 20; $a.k = 1; $a.pad = 0; $a.ancora = "pes" }
$arvoreTab = @(
    @{ nome = "spr_arvore_assombrada"; q = (Arquivos "$arv\arvore_assombrada" 70); spd = 5; amp = 4; alvo = 360; k = 4; pad = 4; ancora = "pes"; irmao = "spr_boss_01" }
)

$todas = $heroiTab + $javaliTab + $aranhaTab + $arqueiroTab + $ossosTab + $chefeTab + $plantasTab + $arvoreTab
$So = @($So | ForEach-Object { $_.Split(',') } | Where-Object { $_ -ne "" })
if ($So.Count -gt 0) { $todas = @($todas | Where-Object { $n = $_.nome; @($So | Where-Object { $n -like $_ }).Count -gt 0 }) }

$montadas = @()
foreach ($a in $todas) {
    $m = Montar $a
    $m.irmao = $a.irmao
    $montadas += , $m
    "{0,-40} n={1,-2} {2}x{3} origem=({4},{5}) k={6}" -f $m.nome, $m.quadros.Count, $m.w, $m.h, $m.xo, $m.yo, $m.k
}

if ($Previa) {
    # prévia: todas as animações no tamanho do mundo (1/k x escala), lado a lado
    $esc = @{ "spr_player" = 1.25; "spr_inimigo01" = 1.0; "spr_aranha" = 1.45; "spr_inimigo02" = 1.6; "spr_boss" = 0.5 }
    $linhas = @()
    foreach ($m in $montadas) {
        $e = 1.0
        foreach ($p in $esc.Keys) { if ($m.nome.StartsWith($p)) { $e = $esc[$p] } }
        if ($m.nome -like "spr_ataque*") { $e = 1.25 }
        $linhas += , @{ m = $m; s = $e / $m.k * $Zoom }
    }
    if ($Cabecas) {
        # um quadro de cada animação numa linha só, para comparar o tamanho da cabeça
        $W = 0; $alt = 0
        foreach ($l in $linhas) { $W += [int]($l.m.w * $l.s) + 8; $alt = [math]::Max($alt, [int]($l.m.yo * $l.s)) }
        $bmp = New-Object System.Drawing.Bitmap ([int]$W + 8), ($alt + 40)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::FromArgb(70, 70, 82))
        $g.InterpolationMode = 'HighQualityBicubic'
        $tmp = Join-Path $env:TEMP "previa_q.png"
        $x = 4; $fonte = New-Object System.Drawing.Font "Arial", 7
        foreach ($l in $linhas) {
            $m = $l.m; $s = $l.s
            [ProcSprite]::Salvar($tmp, $m.quadros[0], $m.w, $m.h)
            $im = [System.Drawing.Image]::FromFile($tmp)
            $g.DrawImage($im, [float]$x, [float](20 + $alt - $m.yo * $s), [float]($m.w * $s), [float]($m.h * $s))
            $im.Dispose()
            $g.DrawString($m.nome.Replace("spr_player_", "").Replace("spr_", ""), $fonte, [System.Drawing.Brushes]::White, $x, 4)
            $x += [int]($m.w * $s) + 8
        }
        $bmp.Save($Previa); $g.Dispose(); $bmp.Dispose()
        return
    }
    $W = 1900; $y = 10; $alturas = @()
    foreach ($l in $linhas) { $alturas += [int]($l.m.h * $l.s) + 26 }
    $H2 = ($alturas | Measure-Object -Sum).Sum + 20
    $bmp = New-Object System.Drawing.Bitmap $W, $H2
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::FromArgb(70, 70, 82))
    $g.InterpolationMode = 'HighQualityBicubic'
    $fonte = New-Object System.Drawing.Font "Arial", 8
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(120, 255, 255, 0))
    $penC = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(160, 0, 255, 255))
    $tmp = Join-Path $env:TEMP "previa_q.png"
    for ($i = 0; $i -lt $linhas.Count; $i++) {
        $l = $linhas[$i]; $m = $l.m; $s = $l.s
        $g.DrawString($m.nome, $fonte, [System.Drawing.Brushes]::White, 4, $y)
        $base = $y + 14 + [int]($m.yo * $s)
        $x = 230
        # linha do chão e altura do herói em pé (67 px)
        $g.DrawLine($pen, 0, $base, $W, $base)
        $g.DrawLine($penC, 0, $base - 67, 200, $base - 67)
        foreach ($qd in $m.quadros) {
            [ProcSprite]::Salvar($tmp, $qd, $m.w, $m.h)
            $im = [System.Drawing.Image]::FromFile($tmp)
            $g.DrawImage($im, [float]($x), [float]($y + 14), [float]($m.w * $s), [float]($m.h * $s))
            $im.Dispose()
            $g.DrawLine($penC, [float]($x + $m.xo * $s), [float]($base - 4), [float]($x + $m.xo * $s), [float]($base + 4))
            $x += [int]($m.w * $s) + 6
        }
        $y += $alturas[$i]
    }
    $bmp.Save($Previa)
    $g.Dispose(); $bmp.Dispose()
    "prévia: $Previa"
    return
}

# ---------------------------------------------------------------------
# grava nas duas versões
# ---------------------------------------------------------------------
foreach ($m in $montadas) {
    GravarGM $m
    GravarGD $m
}
[IO.File]::WriteAllText($gdJson, ($json | ConvertTo-Json -Depth 5 -Compress), $utf8)
"gravadas: $($montadas.Count) sprites (GameMaker e Godot)"
