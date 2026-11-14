# =====================================================================
#  importar_movimento.ps1 - parado, andar e corrida novos do Twilight (v1.19)
#  Fonte: capturas de tela do editor de sprites (ferramentas/_folhas_v119):
#   parado.jpg  (spr_player_parado, 8 quadros)
#   andando.jpg (spr_player_andando_suave, 16 quadros)
#   corrida.jpg (spr_player_corrida_ofegante, 16 quadros)
#  Cada captura tem 3 linhas de 6 celulas: a linha 1 traz os quadros 0-5, a
#  linha 2 repete 0-5 em outra escala (ignorada) e a linha 3 traz os outros
#  quadros (rotulos abaixo). A linha 3 esta menor: ESCALA_L3 foi medida nos
#  quadros 1, 2 e 3 do parado, que aparecem nas duas linhas.
#  Quadros que nao vieram nas capturas sao completados com o quadro vizinho
#  real (o menos repetido): o ciclo fica com 16 posicoes e o passo nao pula.
#  Alinhamento "tronco" (como a escalada do importar_folhas.ps1): o centro do
#  corpo fica parado e a origem vai para a altura dos pes.
#  Instala no GameMaker (sprites/, .yyp, scr_hd) e no Godot (assets/sprites,
#  _originais, sprites.json). Pode rodar de novo (GUIDs mantidos).
#  Uso: powershell -ExecutionPolicy Bypass -File ferramentas/importar_movimento.ps1 [-Medir] [-Previa pasta]
#  (so ASCII aqui: o PowerShell 5 le este .ps1 sem BOM como ANSI)
# =====================================================================
param([switch]$Medir, [string]$Previa = "")
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
Add-Type -ReferencedAssemblies System.Drawing -Path @((Join-Path $PSScriptRoot "ImportaFolhas.cs"), (Join-Path $PSScriptRoot "ImportaCapturas.cs"))
$folhas = Join-Path $PSScriptRoot "_folhas_v119"
$FUNDO = @(63, 77, 90)     # fundo das celulas nas capturas
$ESCALA = 1.0              # linha 1 -> sprites HD do jogo (k = 3): corpo do parado ~161 px = idle atual 162 (-Medir)
$ESCALA_L3 = 0.952         # a linha 3 aparece com 95,2% do tamanho da linha 1 (parado 0,951; andar 0,954)

# l3 = quadro de cada pose da linha 3 (-1 = repetida/ignorada)
$sprites = @(
    @{ nome = "spr_player_parado";   folha = "parado.jpg";  n = 8;  l3 = @(-1, -1, -1, -1, 6, 7);       vel = 8 },
    @{ nome = "spr_player_andar";    folha = "andando.jpg"; n = 16; l3 = @(8, 10, 11, 12, 14, 15);     vel = 12 },
    @{ nome = "spr_player_corrida";  folha = "corrida.jpg"; n = 16; l3 = @(8, 10, 11, 12, 13, 15);     vel = 16 }
)

# ----- poses de uma captura: @{ l1 = 6 imagens; l3 = 6 imagens } -----
function Poses([string]$arq) {
    $f = [ImportaFolhas]::Carregar($arq)
    [ImportaFolhas]::FundoR = $FUNDO[0]; [ImportaFolhas]::FundoG = $FUNDO[1]; [ImportaFolhas]::FundoB = $FUNDO[2]
    $ps = [ImportaCapturas]::Poses($f, $FUNDO[0], $FUNDO[1], $FUNDO[2], 1500)
    $l1 = @(); $l3 = @()
    foreach ($p in $ps) {
        # caixa um pouco maior que a mancha: pega a baforada da corrida e o halo
        $c = [int[]]@(($p[0] - 50), ($p[1] - 30), ($p[0] + $p[2] + 50), ($p[1] + $p[3] + 2))
        $q = [ImportaFolhas]::Extrair($f, $c)
        [ImportaCapturas]::TirarBordas($q)
        if ($p[1] -lt $f.H * 0.3) { $l1 += , $q } elseif ($p[1] -gt $f.H * 0.6) { $l3 += , $q }
    }
    if ($l1.Count -ne 6 -or $l3.Count -ne 6) { throw "$arq : $($l1.Count) poses na linha 1 e $($l3.Count) na linha 3 (esperado 6 e 6)" }
    return @{ l1 = $l1; l3 = $l3 }
}

function AlturaCorpo($q) { $m = [ImportaFolhas]::MedirCorpo($q); return $m[3] - $m[2] + 1 }

if ($Medir) {
    # corpo (sem a lamina) da spr_player_idle atual, para igualar o tamanho
    $hs = @()
    foreach ($a in Get-ChildItem (Join-Path $raiz "godot\_originais\sprites\spr_player_idle") -Filter *.png) { $hs += AlturaCorpo ([ImportaFolhas]::Carregar($a.FullName)) }
    "idle atual: corpo " + (($hs | ForEach-Object { [int]$_ }) -join ",")
    foreach ($a in @(Get-ChildItem (Join-Path $raiz "godot\_originais\sprites\spr_player_ataque_rapido") -Filter *.png)[0]) { "ataque_rapido q0: corpo " + [int](AlturaCorpo ([ImportaFolhas]::Carregar($a.FullName))) }
    foreach ($sp in $sprites) {
        $p = Poses (Join-Path $folhas $sp.folha)
        "{0}: linha1 {1} | linha3 {2}" -f $sp.nome, (($p.l1 | ForEach-Object { [int](AlturaCorpo $_) }) -join ","), (($p.l3 | ForEach-Object { [int](AlturaCorpo $_) }) -join ",")
        $c1 = @($p.l1 | ForEach-Object { $h = [ImportaFolhas]::MedirCabelo($_); if ($h) { [int]$h[0] } }) -join ","
        $c3 = @($p.l3 | ForEach-Object { $h = [ImportaFolhas]::MedirCabelo($_); if ($h) { [int]$h[0] } }) -join ","
        "   cabelo (largura): linha1 $c1 | linha3 $c3"
    }
    return
}

# ----- instalador (GameMaker + Godot): o mesmo do importar_folhas.ps1 -----
$modelo = [IO.File]::ReadAllText((Join-Path $raiz "sprites\spr_player_jump\spr_player_jump.yy"), $utf8)
$yyp = Join-Path $raiz "The Curse of Vallack.yyp"
$script:yypTxt = [IO.File]::ReadAllText($yyp, $utf8)
$g = Join-Path $raiz "godot"
$jsons = @((Join-Path $g "assets\data\sprites.json"), (Join-Path $g "_originais\sprites.json"))
$script:jsonObj = @{}
foreach ($j in $jsons) { if (Test-Path $j) { $script:jsonObj[$j] = [IO.File]::ReadAllText($j, $utf8) | ConvertFrom-Json } }

function Instalar-Sprite([string]$nome, [string[]]$arquivos, [int]$W, [int]$H, [int]$XO, [int]$YO, [int]$vel) {
    $pasta = Join-Path $raiz "sprites\$nome"
    $arqYY = Join-Path $pasta "$nome.yy"
    $n = $arquivos.Count
    $quadros = @(); $camada = $null
    if (Test-Path $arqYY) {
        $velho = [IO.File]::ReadAllText($arqYY, $utf8)
        $quadros = @([regex]::Matches($velho, '"\$GMSpriteFrame":"v1","%Name":"([0-9a-f\-]{36})"') | ForEach-Object { $_.Groups[1].Value })
        $m = [regex]::Match($velho, '"\$GMImageLayer":"","%Name":"([0-9a-f\-]{36})"')
        if ($m.Success) { $camada = $m.Groups[1].Value }
    }
    while ($quadros.Count -lt $n) { $quadros += [Guid]::NewGuid().ToString() }
    $quadros = @($quadros[0..($n - 1)])
    if ($camada -eq $null) { $camada = [Guid]::NewGuid().ToString() }
    if (Test-Path $pasta) { Get-ChildItem $pasta -Filter *.png | Remove-Item; if (Test-Path (Join-Path $pasta "layers")) { Remove-Item (Join-Path $pasta "layers") -Recurse -Force } }
    New-Item -ItemType Directory -Force $pasta | Out-Null
    for ($i = 0; $i -lt $n; $i++) {
        Copy-Item $arquivos[$i] (Join-Path $pasta "$($quadros[$i]).png") -Force
        $dl = Join-Path $pasta "layers\$($quadros[$i])"
        New-Item -ItemType Directory -Force $dl | Out-Null
        Copy-Item $arquivos[$i] (Join-Path $dl "$camada.png") -Force
    }
    $t = $modelo.Replace("spr_player_jump", $nome)
    $t = [regex]::Replace($t, '"bboxMode":\d+', '"bboxMode":0')
    $t = [regex]::Replace($t, '"bbox_bottom":\d+', '"bbox_bottom":' + ($H - 1))
    $t = [regex]::Replace($t, '"bbox_left":\d+', '"bbox_left":0')
    $t = [regex]::Replace($t, '"bbox_right":\d+', '"bbox_right":' + ($W - 1))
    $t = [regex]::Replace($t, '"bbox_top":\d+', '"bbox_top":0')
    $t = [regex]::Replace($t, '"height":\d+', '"height":' + $H)
    $t = [regex]::Replace($t, '"width":\d+', '"width":' + $W)
    $t = [regex]::Replace($t, '"xorigin":\d+', '"xorigin":' + $XO)
    $t = [regex]::Replace($t, '"yorigin":\d+', '"yorigin":' + $YO)
    $t = [regex]::Replace($t, '"length":[\d\.]+', '"length":' + $n + '.0')
    $t = [regex]::Replace($t, '"playbackSpeed":[\d\.]+', '"playbackSpeed":' + $vel + '.0')
    $t = [regex]::Replace($t, '("\$GMImageLayer":"","%Name":")[0-9a-f\-]{36}(".*?"name":")[0-9a-f\-]{36}', ('${1}' + $camada + '${2}' + $camada))
    $fr = ($quadros | ForEach-Object { '    {"$GMSpriteFrame":"v1","%Name":"' + $_ + '","name":"' + $_ + '","resourceType":"GMSpriteFrame","resourceVersion":"2.0",},' }) -join "`n"
    $t = [regex]::Replace($t, '(?s)"frames":\[\r?\n.*?\r?\n  \],', ('"frames":[' + "`n" + $fr.Replace('$', '$$') + "`n  ],"))
    $kfs = @()
    for ($i = 0; $i -lt $n; $i++) {
        $kfs += '            {"$Keyframe<SpriteFrameKeyframe>":"","Channels":{' + "`n" +
            '                "0":{"$SpriteFrameKeyframe":"","Id":{"name":"' + $quadros[$i] + '","path":"sprites/' + $nome + '/' + $nome + '.yy",},"resourceType":"SpriteFrameKeyframe","resourceVersion":"2.0",},' + "`n" +
            '              },"Disabled":false,"id":"' + [Guid]::NewGuid().ToString() + '","IsCreationKey":false,"Key":' + $i + '.0,"Length":1.0,"resourceType":"Keyframe<SpriteFrameKeyframe>","resourceVersion":"2.0","Stretch":false,},'
    }
    $t = [regex]::Replace($t, '(?s)("Keyframes":\[\r?\n)            \{"\$Keyframe<SpriteFrameKeyframe>".*?(\r?\n          \],"resourceType":"KeyframeStore<SpriteFrameKeyframe>")', ('${1}' + (($kfs -join "`n").Replace('$', '$$')) + '${2}'))
    [IO.File]::WriteAllText($arqYY, $t, $utf8)
    if ($script:yypTxt -notmatch [regex]::Escape('"name":"' + $nome + '"')) {
        $ancora = '    {"id":{"name":"spr_player_jump","path":"sprites/spr_player_jump/spr_player_jump.yy",},},'
        if (-not $script:yypTxt.Contains($ancora)) { throw "ancora spr_player_jump nao achada no .yyp" }
        $script:yypTxt = $script:yypTxt.Replace($ancora, $ancora + "`r`n" + '    {"id":{"name":"' + $nome + '","path":"sprites/' + $nome + '/' + $nome + '.yy",},},')
    }
    foreach ($j in $script:jsonObj.Keys) {
        $d = [ordered]@{ bb = $H - 1; bl = 0; br = $W - 1; bt = 0; h = $H; n = $n; spd = $vel; spdt = 0; w = $W; xo = $XO; yo = $YO; pad = 0; k = 3 }
        $script:jsonObj[$j] | Add-Member -NotePropertyName $nome -NotePropertyValue ([pscustomobject]$d) -Force
    }
    foreach ($base in @((Join-Path $g "assets\sprites"), (Join-Path $g "_originais\sprites"))) {
        $dst = Join-Path $base $nome
        if (Test-Path $dst) { Get-ChildItem $dst -Filter *.png | Remove-Item }
        New-Item -ItemType Directory -Force $dst | Out-Null
        for ($i = 0; $i -lt $n; $i++) { Copy-Item $arquivos[$i] (Join-Path $dst "$i.png") -Force }
    }
}

# ----- quadros de cada posicao do ciclo (completa os que faltaram) -----
function Completar([int]$n, $reais) {
    # $reais: hashtable posicao -> imagem; devolve lista de n imagens e o mapa usado
    $usos = @{}; foreach ($k in $reais.Keys) { $usos[$k] = 1 }
    $mapa = @()
    for ($i = 0; $i -lt $n; $i++) {
        if ($reais.ContainsKey($i)) { $mapa += $i; continue }
        $a = $i - 1; while ($a -ge 0 -and -not $reais.ContainsKey($a)) { $a-- }
        $b = $i + 1; while ($b -lt $n -and -not $reais.ContainsKey($b)) { $b++ }
        if ($a -lt 0) { $esc = $b } elseif ($b -ge $n) { $esc = $a } elseif ($usos[$b] -lt $usos[$a]) { $esc = $b } else { $esc = $a }
        $usos[$esc]++; $mapa += $esc
    }
    return , $mapa
}

$tmp = Join-Path $env:TEMP ("movimento_" + [Guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Force $tmp | Out-Null
foreach ($sp in $sprites) {
    $p = Poses (Join-Path $folhas $sp.folha)
    $reais = @{}
    for ($i = 0; $i -lt 6; $i++) { $reais[$i] = [ImportaFolhas]::Escalar($p.l1[$i], $ESCALA) }
    for ($i = 0; $i -lt 6; $i++) { if ($sp.l3[$i] -ge 0) { $reais[$sp.l3[$i]] = [ImportaFolhas]::Escalar($p.l3[$i], $ESCALA / $ESCALA_L3) } }
    $mapa = Completar $sp.n $reais
    # medidas (alinhamento pelo tronco)
    $med = @{}
    foreach ($k in $reais.Keys) {
        $desl = New-Object 'int[]' 2
        $q = [ImportaFolhas]::Aparar($reais[$k], $desl)
        $m = [ImportaFolhas]::MedirCorpo($q)
        $med[$k] = @($q, $m[4], $m[5], ($m[3] - $m[5]))
    }
    $esq = 0.0; $dir = 0.0; $cima = 0.0; $baixo = 0.0; $pes = @()
    foreach ($e in $med.Values) {
        $esq = [Math]::Max($esq, $e[1]); $dir = [Math]::Max($dir, $e[0].W - $e[1])
        $cima = [Math]::Max($cima, $e[2]); $baixo = [Math]::Max($baixo, $e[0].H - $e[2]); $pes += $e[3]
    }
    $pes = @($pes | Sort-Object); $mpe = $pes[[int][Math]::Floor($pes.Count / 2)]
    $W = [int][Math]::Ceiling($esq + $dir) + 4
    $H = [int][Math]::Ceiling($cima + $baixo) + 4
    $AX = [int][Math]::Ceiling($esq) + 2; $AY = [int][Math]::Ceiling($cima) + 2
    $arqs = @(); $lista = New-Object 'System.Collections.Generic.List[ImportaFolhas+Img]'
    for ($i = 0; $i -lt $sp.n; $i++) {
        $e = $med[$mapa[$i]]
        $tela = New-Object 'ImportaFolhas+Img' $W, $H
        [ImportaFolhas]::Colar($tela, $e[0], [int][Math]::Round($AX - $e[1]), [int][Math]::Round($AY - $e[2]))
        $a = Join-Path $tmp ("{0}_{1}.png" -f $sp.nome, $i)
        [ImportaFolhas]::Salvar($tela, $a)
        $arqs += $a; $lista.Add($tela)
    }
    $XO = $AX; $YO = [int][Math]::Round($AY + $mpe)
    if ($YO -gt $H - 1) { $YO = $H - 1 }
    Instalar-Sprite $sp.nome $arqs $W $H $XO $YO $sp.vel
    $comp = @(); for ($i = 0; $i -lt $sp.n; $i++) { if ($mapa[$i] -ne $i) { $comp += "$i<-$($mapa[$i])" } }
    "{0,-22} {1,2} quadros  {2}x{3}  origem {4},{5}  completados: {6}" -f $sp.nome, $arqs.Count, $W, $H, $XO, $YO, ($(if ($comp.Count) { $comp -join " " } else { "nenhum" }))
    if ($Previa -ne "") { [ImportaFolhas]::Previa($lista, $XO, $YO, (Join-Path $Previa ($sp.nome + ".png")), $sp.nome) }
}

[IO.File]::WriteAllText($yyp, $script:yypTxt, $utf8)
foreach ($j in $script:jsonObj.Keys) { [IO.File]::WriteAllText($j, ($script:jsonObj[$j] | ConvertTo-Json -Depth 5 -Compress), $utf8) }

# escala HD (k = 3) no GameMaker
$hd = Join-Path $raiz "scripts\scr_hd\scr_hd.gml"
$hdTxt = [IO.File]::ReadAllText($hd, $utf8)
$novas = ""
foreach ($sp in $sprites) { if ($hdTxt -notmatch ('hd_registrar\(' + $sp.nome + ',')) { $novas += "`r`n    hd_registrar(" + $sp.nome + ", 3);" } }
if ($novas -ne "") { $hdTxt = $hdTxt.Replace("    hd_registrar(spr_player_ataque_ar, 3);", "    hd_registrar(spr_player_ataque_ar, 3);`r`n    // v1.19: parado, andar e corrida novos (ferramentas/importar_movimento.ps1)" + $novas) }
[IO.File]::WriteAllText($hd, $hdTxt, $utf8)
Remove-Item $tmp -Recurse -Force
"pronto"
