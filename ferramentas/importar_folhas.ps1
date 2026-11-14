# =====================================================================
#  importar_folhas.ps1 - animacoes novas do Twilight (v1.17), a partir das
#  folhas de quadros enviadas pela equipe (ferramentas/_folhas_v117/*.jpg):
#   escada: subindo / descendo (de costas, com a espada na mao)
#   corda : pular e agarrar / segurando e subindo
#   ataque: rapido (1 toque), duplo (2), triplo (3) e frenetico (4 ou mais)
#  ImportaFolhas.cs acha as caixas, tira o fundo e o numero amarelo; aqui
#  cada quadro e reduzido para a escala das sprites do jogo (ESCALA) e todos
#  os quadros de uma animacao sao alinhados numa tela comum:
#   "pes"    = meio dos pes no chao (golpes: o corpo nao escorrega)
#   "tronco" = centro do tronco (escalada: o corpo fica firme e os bracos e
#              pernas se mexem; a origem fica na altura dos pes)
#  Instala no GameMaker (sprites/, .yyp, scr_hd) e no Godot (assets/sprites,
#  sprites.json, _originais). Pode rodar de novo (GUIDs mantidos).
#  Uso: powershell -ExecutionPolicy Bypass -File ferramentas/importar_folhas.ps1 [-Previa pasta]
#  (so ASCII aqui: o PowerShell 5 le este .ps1 sem BOM como ANSI)
# =====================================================================
param([string]$Previa = "")
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
Add-Type -ReferencedAssemblies System.Drawing -Path (Join-Path $PSScriptRoot "ImportaFolhas.cs")
$folhas = Join-Path $PSScriptRoot "_folhas_v117"
$ESCALA = 0.70        # cabelo ~41 px nas folhas -> como as sprites HD do jogo (k = 3)

# caixas na ordem de leitura de cada folha (os rotulos repetidos das folhas
# foram conferidos a olho: veja o LEIAME v1.17)
$caixasEsperadas = @{ "escalada.jpg" = 22; "ataque_rapido.jpg" = 14; "ataque_duplo.jpg" = 15; "ataque_triplo.jpg" = 18; "ataque_frenetico.jpg" = 18 }
$sprites = @(
    @{ nome = "spr_player_subindo_escada";             folha = "escalada.jpg";         caixas = @(0, 1, 2, 3, 4);                        ancora = "tronco"; vel = 8 },
    @{ nome = "spr_player_descendo_escada";            folha = "escalada.jpg";         caixas = @(5, 6, 7, 8, 9, 10);                    ancora = "tronco"; vel = 8 },
    @{ nome = "spr_player_pular_e_agarrar_cordas";     folha = "escalada.jpg";         caixas = @(11, 12, 13, 14, 15);                   ancora = "tronco"; vel = 12 },
    @{ nome = "spr_player_segurando_e_subindo_cordas"; folha = "escalada.jpg";         caixas = @(16, 17, 18, 19, 20, 21);               ancora = "tronco"; vel = 8 },
    @{ nome = "spr_player_ataque_rapido";              folha = "ataque_rapido.jpg";    caixas = @(8, 9, 10, 11, 12, 13);                 ancora = "pes";    vel = 15 },
    @{ nome = "spr_player_ataque_duplo";               folha = "ataque_duplo.jpg";     caixas = @(0, 1, 2, 3, 4, 8, 9, 10, 11, 12, 13, 14); ancora = "pes"; vel = 15 },
    @{ nome = "spr_player_ataque_triplo";              folha = "ataque_triplo.jpg";    caixas = @(0..17);                                ancora = "pes";    vel = 15 },
    @{ nome = "spr_player_ataque_frenetico";           folha = "ataque_frenetico.jpg"; caixas = @(0..17);                                ancora = "pes";    vel = 15 }
)

# ----- instalador (GameMaker + Godot) -----
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
    # Godot
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

function Remover-Sprite([string]$nome) {
    $pasta = Join-Path $raiz "sprites\$nome"
    if (Test-Path $pasta) { Remove-Item $pasta -Recurse -Force }
    $script:yypTxt = [regex]::Replace($script:yypTxt, '\r?\n    \{"id":\{"name":"' + $nome + '","path":"sprites/' + $nome + '/' + $nome + '\.yy",\},\},', '')
    foreach ($j in $script:jsonObj.Keys) { $script:jsonObj[$j].PSObject.Properties.Remove($nome) }
    foreach ($base in @((Join-Path $g "assets\sprites"), (Join-Path $g "_originais\sprites"))) {
        $dst = Join-Path $base $nome
        if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    }
}

# ----- 1) recorta e alinha -----
$tmp = Join-Path $env:TEMP ("folhas_" + [Guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Force $tmp | Out-Null
$cache = @{}
foreach ($sp in $sprites) {
    if (-not $cache.ContainsKey($sp.folha)) {
        $f = [ImportaFolhas]::Carregar((Join-Path $folhas $sp.folha))
        $cx = [ImportaFolhas]::Caixas($f)
        if ($cx.Count -ne $caixasEsperadas[$sp.folha]) { throw "$($sp.folha): $($cx.Count) caixas (esperado $($caixasEsperadas[$sp.folha]))" }
        $cache[$sp.folha] = @{ f = $f; cx = $cx; fundo = @([ImportaFolhas]::FundoR, [ImportaFolhas]::FundoG, [ImportaFolhas]::FundoB) }
    }
    $c = $cache[$sp.folha]
    [ImportaFolhas]::FundoR = $c.fundo[0]; [ImportaFolhas]::FundoG = $c.fundo[1]; [ImportaFolhas]::FundoB = $c.fundo[2]
    $qs = @()
    foreach ($i in $sp.caixas) {
        $desl = New-Object 'int[]' 2
        $q = [ImportaFolhas]::Aparar([ImportaFolhas]::Escalar([ImportaFolhas]::Extrair($c.f, $c.cx[$i]), $ESCALA), $desl)
        $m = [ImportaFolhas]::MedirCorpo($q)
        if ($sp.ancora -eq "pes") { $ax = $m[6]; $ay = $m[3]; $pe = 0.0 } else { $ax = $m[4]; $ay = $m[5]; $pe = $m[3] - $m[5] }
        $qs += ,@($q, $ax, $ay, $pe)
    }
    $esq = 0.0; $dir = 0.0; $cima = 0.0; $baixo = 0.0; $pes = @()
    foreach ($e in $qs) {
        $esq = [Math]::Max($esq, $e[1]); $dir = [Math]::Max($dir, $e[0].W - $e[1])
        $cima = [Math]::Max($cima, $e[2]); $baixo = [Math]::Max($baixo, $e[0].H - $e[2]); $pes += $e[3]
    }
    $pes = @($pes | Sort-Object); $mpe = $pes[[int][Math]::Floor($pes.Count / 2)]
    $W = [int][Math]::Ceiling($esq + $dir) + 4
    $H = [int][Math]::Ceiling($cima + $baixo) + 4
    $AX = [int][Math]::Ceiling($esq) + 2; $AY = [int][Math]::Ceiling($cima) + 2
    $arqs = @(); $lista = New-Object 'System.Collections.Generic.List[ImportaFolhas+Img]'
    for ($k = 0; $k -lt $qs.Count; $k++) {
        $e = $qs[$k]
        $tela = New-Object 'ImportaFolhas+Img' $W, $H
        [ImportaFolhas]::Colar($tela, $e[0], [int][Math]::Round($AX - $e[1]), [int][Math]::Round($AY - $e[2]))
        $a = Join-Path $tmp ("{0}_{1}.png" -f $sp.nome, $k)
        [ImportaFolhas]::Salvar($tela, $a)
        $arqs += $a; $lista.Add($tela)
    }
    $XO = $AX; $YO = [int][Math]::Round($AY + $mpe)
    if ($YO -gt $H - 1) { $YO = $H - 1 }
    Instalar-Sprite $sp.nome $arqs $W $H $XO $YO $sp.vel
    "{0,-40} {1,2} quadros  {2}x{3}  origem {4},{5}  ({6})" -f $sp.nome, $arqs.Count, $W, $H, $XO, $YO, $sp.ancora
    if ($Previa -ne "") { [ImportaFolhas]::Previa($lista, $XO, $YO, (Join-Path $Previa ($sp.nome + ".png")), $sp.nome) }
}

# as sprites de escalada geradas antes desta importacao saem do projeto
Remover-Sprite "spr_player_escada"
Remover-Sprite "spr_player_corda"

[IO.File]::WriteAllText($yyp, $script:yypTxt, $utf8)
foreach ($j in $script:jsonObj.Keys) { [IO.File]::WriteAllText($j, ($script:jsonObj[$j] | ConvertTo-Json -Depth 5 -Compress), $utf8) }

# escala HD (k = 3) no GameMaker
$hd = Join-Path $raiz "scripts\scr_hd\scr_hd.gml"
$hdTxt = [IO.File]::ReadAllText($hd, $utf8)
$hdTxt = [regex]::Replace($hdTxt, '\r?\n    hd_registrar\(spr_player_(escada|corda), 3\);[^\r\n]*', '')
$novas = ""
foreach ($sp in $sprites) { if ($hdTxt -notmatch ('hd_registrar\(' + $sp.nome + ',')) { $novas += "`r`n    hd_registrar(" + $sp.nome + ", 3);" } }
if ($novas -ne "") { $hdTxt = $hdTxt.Replace("    hd_registrar(spr_player_ataque_ar, 3);", "    hd_registrar(spr_player_ataque_ar, 3);`r`n    // v1.17: escalada e ataques novos (ferramentas/importar_folhas.ps1)" + $novas) }
[IO.File]::WriteAllText($hd, $hdTxt, $utf8)
Remove-Item $tmp -Recurse -Force
"pronto"
