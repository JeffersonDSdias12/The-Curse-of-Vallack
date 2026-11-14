# =====================================================================
#  gerar_lamina.ps1 - posicao da LAMINA (cabo e ponta) em cada quadro dos
#  golpes do Twilight (v1.17). O rastro de fogo da espada segue esses pontos.
#  Gera:
#   * scripts/scr_lamina/scr_lamina.gml   (GameMaker)
#   * godot/src/core/lamina_dados.gd      (Godot)
#  Os pontos sao relativos a origem da sprite, em px da sprite HD (k = 3).
#  Quadros em que a deteccao automatica falha (lamina escondida no borrao do
#  golpe ou colada no corpo) estao marcados a mao em $manual.
#  Uso:  powershell -ExecutionPolicy Bypass -File ferramentas/gerar_lamina.ps1 [-Previa arquivo.png]
#  (so ASCII aqui: o PowerShell 5 le este .ps1 sem BOM como ANSI)
# =====================================================================
param([string]$Previa = "")
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
Add-Type -ReferencedAssemblies System.Drawing -Path (Join-Path $PSScriptRoot "GeraLamina.cs")

$sprites = @('spr_player_ataque', 'spr_player_ataque_ar', 'spr_player_especial', 'spr_player_atacar_agaichado',
    'spr_player_atacar_agaichado_especial', 'spr_ataque_2', 'spr_ataque_especial_2', 'spr_ataque_03',
    'spr_player_ataque_rapido', 'spr_player_ataque_duplo', 'spr_player_ataque_triplo', 'spr_player_ataque_frenetico')
# [cabo x, cabo y, ponta x, ponta y] em px do quadro (conferidos na previa)
$manual = @{
    'spr_player_ataque:3'           = @(146, 128, 186, 142)
    'spr_player_ataque_ar:0'        = @(52, 113, 19, 152)
    'spr_player_ataque_ar:3'        = @(114, 150, 172, 127)
    'spr_player_atacar_agaichado:3' = @(150, 42, 177, 44)
    'spr_ataque_2:1'                = @(42, 138, 14, 176)
    # pouso do golpe por cima: a lamina fica cravada a frente, como no quadro 7
    # (assim o rastro nao "raspa" o chao para tras ao pousar)
    'spr_ataque_2:8'                = @(112, 121, 104, 208)
    'spr_ataque_2:9'                = @(112, 121, 104, 208)
    # v1.17: ataque frenetico (a lamina fica dentro do borrao; marcados na previa)
    'spr_player_ataque_frenetico:0' = @(97, 113, 60, 158)
    'spr_player_ataque_frenetico:2' = @(112, 48, 26, 113)
    'spr_player_ataque_frenetico:3' = @(75, 66, 27, 113)
}

$gml = New-Object System.Text.StringBuilder
$gd = New-Object System.Text.StringBuilder
$arqs = @(); $rot = @(); $pts = @()
foreach ($sp in $sprites) {
    $yy = [IO.File]::ReadAllText((Join-Path $raiz "sprites\$sp\$sp.yy"), $utf8)
    $ids = @([regex]::Matches($yy, '"\$GMSpriteFrame":"v1","%Name":"([0-9a-f\-]{36})"') | ForEach-Object { $_.Groups[1].Value })
    $xo = [int]([regex]::Match($yy, '"xorigin":(-?\d+)').Groups[1].Value)
    $yo = [int]([regex]::Match($yy, '"yorigin":(-?\d+)').Groups[1].Value)
    $ms = @()
    for ($i = 0; $i -lt $ids.Count; $i++) {
        $a = Join-Path $raiz "sprites\$sp\$($ids[$i]).png"
        $chave = "${sp}:$i"
        if ($manual.ContainsKey($chave)) { $m = [double[]]$manual[$chave] }
        else { $m = [GeraLamina]::Medir($a) }
        $ms += ,$m
        $arqs += $a; $rot += ($sp -replace 'spr_(player_)?', '') + ":$i"
    }
    # quadros sem lamina visivel (escondida no borrao do golpe): interpolados
    # entre os vizinhos que tem (o rastro gira a lamina entre eles)
    for ($i = 0; $i -lt $ms.Count; $i++) {
        if ($ms[$i] -ne $null) { continue }
        $p = $i - 1; while ($p -ge 0 -and ($ms[$p] -eq $null -or $ms[$p].Count -gt 7)) { $p-- }
        $n = $i + 1; while ($n -lt $ms.Count -and $ms[$n] -eq $null) { $n++ }
        if ($p -lt 0 -and $n -ge $ms.Count) { throw "sem lamina em nenhum quadro de $sp" }
        if ($p -lt 0) { $ms[$i] = $ms[$n] } elseif ($n -ge $ms.Count) { $ms[$i] = $ms[$p] }
        else { $k = ($i - $p) / ($n - $p); $ms[$i] = [double[]](0..3 | ForEach-Object { $ms[$p][$_] + ($ms[$n][$_] - $ms[$p][$_]) * $k }) }
        "interpolado: ${sp}:$i"
    }
    $q = @()
    foreach ($m in $ms) {
        $pts += ,$m
        $q += ("[{0}, {1}, {2}, {3}]" -f [Math]::Round($m[0] - $xo), [Math]::Round($m[1] - $yo), [Math]::Round($m[2] - $xo), [Math]::Round($m[3] - $yo))
    }
    [void]$gml.AppendLine("        " + $sp + ": [" + ($q -join ", ") + "],")
    [void]$gd.AppendLine("`t`"" + $sp + "`": [" + ($q -join ", ") + "],")
    "{0,-40} {1} quadros" -f $sp, $ids.Count
}

$cab = "//  GERADO por ferramentas/gerar_lamina.ps1 - nao edite a mao.`r`n" +
    "//  Lamina de cada quadro dos golpes: [cabo x, cabo y, ponta x, ponta y]`r`n" +
    "//  relativos a origem da sprite, em px da sprite HD (k = 3).`r`n"
$txt = $cab + "function lamina_dados()`r`n{`r`n    static _d = undefined;`r`n    if (is_undefined(_d)) _d = {`r`n" +
    $gml.ToString().TrimEnd().TrimEnd(',') + "`r`n    };`r`n    return _d;`r`n}`r`n"
$pasta = Join-Path $raiz "scripts\scr_lamina"
New-Item -ItemType Directory -Force $pasta | Out-Null
[IO.File]::WriteAllText((Join-Path $pasta "scr_lamina.gml"), $txt, $utf8)
$yyS = Join-Path $pasta "scr_lamina.yy"
if (-not (Test-Path $yyS)) {
    $y = '{' + "`r`n" + '  "$GMScript":"v1",' + "`r`n" + '  "%Name":"scr_lamina",' + "`r`n" + '  "isCompatibility":false,' + "`r`n" + '  "isDnD":false,' + "`r`n" +
        '  "name":"scr_lamina",' + "`r`n" + '  "parent":{' + "`r`n" + '    "name":"scripts",' + "`r`n" + '    "path":"folders/scripts.yy",' + "`r`n" + '  },' + "`r`n" +
        '  "resourceType":"GMScript",' + "`r`n" + '  "resourceVersion":"2.0",' + "`r`n" + '}'
    [IO.File]::WriteAllText($yyS, $y, $utf8)
}
$yyp = Join-Path $raiz "The Curse of Vallack.yyp"
$yypTxt = [IO.File]::ReadAllText($yyp, $utf8)
if ($yypTxt -notmatch '"name":"scr_lamina"') {
    $ancora = '    {"id":{"name":"scr_v117","path":"scripts/scr_v117/scr_v117.yy",},},'
    if (-not $yypTxt.Contains($ancora)) { throw "ancora scr_v117 nao achada no .yyp" }
    $yypTxt = $yypTxt.Replace($ancora, $ancora + "`r`n" + '    {"id":{"name":"scr_lamina","path":"scripts/scr_lamina/scr_lamina.yy",},},')
    [IO.File]::WriteAllText($yyp, $yypTxt, $utf8)
    "GM: scr_lamina registrado"
}

$gdTxt = "class_name LaminaDados`r`n# GERADO por ferramentas/gerar_lamina.ps1 (na raiz do projeto) - nao edite a mao.`r`n" +
    "# Lamina de cada quadro dos golpes: [cabo x, cabo y, ponta x, ponta y] relativos`r`n" +
    "# a origem da sprite, em px da sprite HD (k = 3). O mesmo da versao PC.`r`n`r`n" +
    "const D := {`r`n" + $gd.ToString().TrimEnd().TrimEnd(',') + "`r`n}`r`n"
[IO.File]::WriteAllText((Join-Path $raiz "godot\src\core\lamina_dados.gd"), $gdTxt, $utf8)
"Godot: godot/src/core/lamina_dados.gd"
if ($Previa -ne "") { [GeraLamina]::Previa([string[]]$arqs, [string[]]$rot, [double[][]]$pts, $Previa, 0.75); "previa: $Previa" }
