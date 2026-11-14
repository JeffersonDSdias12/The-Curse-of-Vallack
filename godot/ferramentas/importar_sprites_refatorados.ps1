[CmdletBinding()]
param(
    [string]$Alex = 'C:\Projetos\Projeto do jogo\Alex\Sprites',
    [string]$Eduardo = 'C:\Projetos\Projeto do jogo\Eduardo\Sprites'
)

# Importador determinístico da refatoração visual. Ele recorta as folhas de
# animação recebidas, centraliza cada quadro em uma tela comum e preserva o
# "pé" da sprite na origem já usada pelo jogo. As máscaras de colisão não são
# alteradas: apenas os PNGs visuais são substituídos.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (-not (Test-Path -LiteralPath $Alex)) { throw "Pasta de sprites do Alex não encontrada: $Alex" }
if (-not (Test-Path -LiteralPath $Eduardo)) { throw "Pasta de sprites do Eduardo não encontrada: $Eduardo" }

$raiz = Split-Path -Parent $PSScriptRoot
$pastaSprites = Join-Path $raiz 'assets\sprites'
$metadados = Get-Content -LiteralPath (Join-Path $raiz 'assets\data\sprites.json') -Raw | ConvertFrom-Json


function Caminho {
    param([string]$Base, [string[]]$Partes)
    $p = $Base
    foreach ($parte in $Partes) { $p = Join-Path $p $parte }
    return $p
}


# Windows PowerShell 5.1 interpreta scripts UTF-8 sem BOM na página de código
# local. Para os poucos nomes de arquivos com acento, localizamos por sufixo ou
# padrão ASCII, deixando o importador reproduzível tanto no PowerShell 5 quanto
# no PowerShell 7.
function Arquivo-NaPasta {
    param([string]$Pasta, [string]$Padrao)
    $arquivo = Get-ChildItem -LiteralPath $Pasta -File -Filter '*.png' |
        Where-Object { $_.Name -like $Padrao } |
        Select-Object -First 1
    if ($null -eq $arquivo) { throw "Arquivo esperado não encontrado em $Pasta ($Padrao)" }
    return $arquivo.FullName
}


function Pasta-NaPasta {
    param([string]$Pasta, [string]$Padrao)
    $diretorio = Get-ChildItem -LiteralPath $Pasta -Directory |
        Where-Object { $_.Name -like $Padrao } |
        Select-Object -First 1
    if ($null -eq $diretorio) { throw "Pasta esperada não encontrada em $Pasta ($Padrao)" }
    return $diretorio.FullName
}


function Quadros-Arquivos {
    param([string]$Pasta)
    if (-not (Test-Path -LiteralPath $Pasta)) { throw "Pasta esperada não encontrada: $Pasta" }
    $arquivos = Get-ChildItem -LiteralPath $Pasta -File -Filter '*.png' |
        Where-Object { $_.Name -notmatch 'strip' } |
        Sort-Object @{ Expression = {
            $m = [regex]::Match($_.Name, '\d+')
            if ($m.Success) { [int]$m.Value } else { 99999 }
        } }, Name
    return @($arquivos | ForEach-Object {
        [pscustomobject]@{ Arquivo = $_.FullName; X = 0; Y = 0; Largura = 0; Altura = 0 }
    })
}


function Quadros-Folha {
    param([string]$Arquivo, [int]$Colunas, [int]$Linhas = 1)
    if (-not (Test-Path -LiteralPath $Arquivo)) { throw "Folha de sprites não encontrada: $Arquivo" }
    $imagem = [System.Drawing.Image]::FromFile($Arquivo)
    try {
        $quadros = @()
        for ($linha = 0; $linha -lt $Linhas; $linha++) {
            $y1 = [math]::Floor($linha * $imagem.Height / $Linhas)
            $y2 = [math]::Floor(($linha + 1) * $imagem.Height / $Linhas)
            for ($coluna = 0; $coluna -lt $Colunas; $coluna++) {
                $x1 = [math]::Floor($coluna * $imagem.Width / $Colunas)
                $x2 = [math]::Floor(($coluna + 1) * $imagem.Width / $Colunas)
                $quadros += [pscustomobject]@{ Arquivo = $Arquivo; X = $x1; Y = $y1; Largura = $x2 - $x1; Altura = $y2 - $y1 }
            }
        }
        return @($quadros)
    }
    finally { $imagem.Dispose() }
}


function Amostrar-Quadros {
    param([object[]]$Quadros, [int]$Quantidade)
    if ($Quadros.Count -eq 0) { throw 'A animação não possui quadros.' }
    $saida = @()
    for ($i = 0; $i -lt $Quantidade; $i++) {
        if ($Quantidade -le $Quadros.Count) {
            $indice = if ($Quantidade -eq 1) { 0 } else { [math]::Round($i * ($Quadros.Count - 1) / ($Quantidade - 1)) }
        }
        else { $indice = $i % $Quadros.Count }
        $saida += $Quadros[$indice]
    }
    return @($saida)
}


function Limites-Alfa {
    param([System.Drawing.Bitmap]$Imagem)
    $esq = $Imagem.Width; $topo = $Imagem.Height; $dir = -1; $base = -1
    for ($y = 0; $y -lt $Imagem.Height; $y++) {
        for ($x = 0; $x -lt $Imagem.Width; $x++) {
            if ($Imagem.GetPixel($x, $y).A -gt 12) {
                if ($x -lt $esq) { $esq = $x }
                if ($x -gt $dir) { $dir = $x }
                if ($y -lt $topo) { $topo = $y }
                if ($y -gt $base) { $base = $y }
            }
        }
    }
    if ($dir -lt $esq -or $base -lt $topo) { throw 'Foi encontrado um quadro sem pixels visíveis.' }
    return @($esq, $topo, ($dir - $esq + 1), ($base - $topo + 1))
}


function Salvar-Sprite {
    param(
        [string]$Nome,
        [object[]]$Quadros,
        [double]$Multiplicador = 1,
        [switch]$PixelArt
    )
    $propriedade = $metadados.PSObject.Properties[$Nome]
    if ($null -eq $propriedade) { throw "Sprite não existe no catálogo: $Nome" }
    $dado = $propriedade.Value
    $selecionados = @(Amostrar-Quadros $Quadros ([int]$dado.n))
    $larguraSaida = [math]::Round([double]$dado.w * $Multiplicador)
    $alturaSaida = [math]::Round([double]$dado.h * $Multiplicador)
    $origemY = [math]::Round($alturaSaida * ([double]$dado.yo / [double]$dado.h))
    $destino = Join-Path $pastaSprites $Nome
    [System.IO.Directory]::CreateDirectory($destino) | Out-Null

    for ($indice = 0; $indice -lt $selecionados.Count; $indice++) {
        $quadro = $selecionados[$indice]
        $fonte = [System.Drawing.Bitmap]::new($quadro.Arquivo)
        $larguraRecorte = if ([int]$quadro.Largura -gt 0) { [int]$quadro.Largura } else { $fonte.Width }
        $alturaRecorte = if ([int]$quadro.Altura -gt 0) { [int]$quadro.Altura } else { $fonte.Height }
        $origemX = if ([int]$quadro.Largura -gt 0) { [int]$quadro.X } else { 0 }
        $origemY = if ([int]$quadro.Altura -gt 0) { [int]$quadro.Y } else { 0 }
        $recorte = [System.Drawing.Bitmap]::new($larguraRecorte, $alturaRecorte)
        $gRecorte = [System.Drawing.Graphics]::FromImage($recorte)
        try {
            $gRecorte.Clear([System.Drawing.Color]::Transparent)
            $gRecorte.DrawImage($fonte,
                [System.Drawing.Rectangle]::new(0, 0, $recorte.Width, $recorte.Height),
                [System.Drawing.Rectangle]::new($origemX, $origemY, $larguraRecorte, $alturaRecorte),
                [System.Drawing.GraphicsUnit]::Pixel)
        }
        finally { $gRecorte.Dispose(); $fonte.Dispose() }

        try {
            $lim = Limites-Alfa $recorte
            $margemW = [math]::Floor($larguraSaida * 0.94)
            $margemH = [math]::Floor($alturaSaida * 0.94)
            $escala = [math]::Min($margemW / [double]$lim[2], $margemH / [double]$lim[3])
            $dw = [math]::Max(1, [math]::Round($lim[2] * $escala))
            $dh = [math]::Max(1, [math]::Round($lim[3] * $escala))
            $dx = [math]::Round(($larguraSaida - $dw) / 2.0)
            $dy = [math]::Max(0, [math]::Min($alturaSaida - $dh, $origemY - $dh))
            $saida = [System.Drawing.Bitmap]::new($larguraSaida, $alturaSaida, [System.Drawing.Imaging.PixelFormat]::Format32bppPArgb)
            $gSaida = [System.Drawing.Graphics]::FromImage($saida)
            try {
                $gSaida.Clear([System.Drawing.Color]::Transparent)
                $gSaida.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $gSaida.InterpolationMode = if ($PixelArt) {
                    [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
                } else {
                    [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                }
                $gSaida.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $gSaida.DrawImage($recorte,
                    [System.Drawing.Rectangle]::new($dx, $dy, $dw, $dh),
                    [System.Drawing.Rectangle]::new([int]$lim[0], [int]$lim[1], [int]$lim[2], [int]$lim[3]),
                    [System.Drawing.GraphicsUnit]::Pixel)
                $saida.Save((Join-Path $destino ($indice.ToString() + '.png')),
                    [System.Drawing.Imaging.ImageFormat]::Png)
            }
            finally { $gSaida.Dispose(); $saida.Dispose() }
        }
        finally { $recorte.Dispose() }
    }
    Write-Host ("  {0}: {1} quadro(s), {2}x{3}, visual {4}x" -f $Nome, $selecionados.Count, $larguraSaida, $alturaSaida, $Multiplicador)
}


# Cavaleiro em alta definição (Alex)
$principal = Caminho $Alex @('Personagem Principal')
$parado = Quadros-Arquivos (Caminho $principal @('Parado')) | Where-Object { $_.Arquivo -match '\\[1-4]\.png$' }
$andando = Quadros-Arquivos (Caminho $principal @('Andando')) | Where-Object { $_.Arquivo -match '\\[1-6]\.png$' }
$pulando = Quadros-Arquivos (Caminho $principal @('Pulando')) | Where-Object { $_.Arquivo -match '\\[1-7]\.png$' }
$ataque = (Quadros-Folha (Arquivo-NaPasta (Caminho $principal @('Atacando')) '*Ataque do Guerreiro Pixel Art.png') 8 2 | Select-Object -First 6)
$morte = Quadros-Folha (Arquivo-NaPasta (Caminho $principal @('Morrendo')) '*Queda do Guerreiro Carmesim.png') 10
$defesa = Quadros-Folha (Caminho $principal @('Defendendo', 'Cavaleiro defendendo.png')) 8
$aereo = Quadros-Folha (Arquivo-NaPasta (Caminho $principal @('Ataque no ar')) '*Ataque do Cavaleiro no ar.png') 6
$agachar = Quadros-Folha (Caminho $principal @('Abaixando', 'Sprite Sheet do Cavaleiro Vermelho em Agachamento.png')) 7
$ataqueBaixo = Quadros-Folha (Caminho $principal @('Ataque abaixado', 'Ataque normal abaixado.png')) 6
$ataqueBaixoEspecial = Quadros-Folha (Caminho $principal @('Ataque abaixado', 'Ataque especial abaixado.png')) 7
Salvar-Sprite 'spr_player' $parado 3
Salvar-Sprite 'spr_player_idle' $parado 3
Salvar-Sprite 'spr_player_run' $andando 3
Salvar-Sprite 'spr_player_jump' $pulando 3
Salvar-Sprite 'spr_player_fall' @($pulando[3], $pulando[4], $pulando[5], $pulando[6]) 3
Salvar-Sprite 'spr_player_dano' $morte 3
Salvar-Sprite 'spr_player_morte' $morte 3
Salvar-Sprite 'spr_player_defendendo' $defesa 3
Salvar-Sprite 'spr_player_ataque' $ataque 3
Salvar-Sprite 'spr_player_especial' $aereo 3
Salvar-Sprite 'spr_player_agaichar' @($agachar[4]) 3
Salvar-Sprite 'spr_player_atacar_agaichado' $ataqueBaixo 3
Salvar-Sprite 'spr_player_atacar_agaichado_especial' $ataqueBaixoEspecial 3


# Homem-porco e Mulher-Aranha em alta definição (Alex)
$javali = Caminho $Alex @('Inimigo (Homem-Porco)')
$javaliParado = Quadros-Arquivos (Caminho $javali @('Parado'))
$javaliAndando = Quadros-Arquivos (Caminho $javali @('Andando'))
$javaliCorrendo = Quadros-Arquivos (Caminho $javali @('Correndo'))
$javaliAtacando = Quadros-Folha (Caminho $javali @('Atacando', 'Sprite Sheet de Ataque do Guerreiro Javali.png')) 4 2
$javaliPulando = Quadros-Folha (Caminho $javali @('Saltando_', 'Sprite de Guerreiro Javali em Salto.png')) 5 2
$javaliMorrendo = (Quadros-Folha (Caminho $javali @('Morrendo', 'Morrendo.png')) 5 2 | Select-Object -First 9)
Salvar-Sprite 'spr_inimigo01_parado' $javaliParado 3
Salvar-Sprite 'spr_inimigo01_andar' $javaliAndando 3
Salvar-Sprite 'spr_inimigo01_correndo' $javaliCorrendo 3
Salvar-Sprite 'spr_inimigo01_atacando' $javaliAtacando 3
Salvar-Sprite 'spr_inimigo01_pulando' $javaliPulando 3
Salvar-Sprite 'spr_inimigo01_morrendo' $javaliMorrendo 3

$aranha = Caminho $Alex @('Inimigo Mulher-Aranha')
Salvar-Sprite 'spr_aranha_parada' (Quadros-Folha (Caminho $aranha @('Parada', 'Sequência de quatro poses da mulher-aranha.png')) 4) 3
Salvar-Sprite 'spr_aranha_andando' (Quadros-Folha (Caminho $aranha @('Andando', 'Sprite sheet da aranha guerreira prateada.png')) 4) 3
Salvar-Sprite 'spr_aranha_ataque' (Quadros-Folha (Caminho $aranha @('Atacando', 'Mulher-aranha em ataque, quatro quadros.png')) 4) 3


# Esqueletos, porco corrompido e árvore (Eduardo). Estes quadros são pixel art:
# o redimensionamento usa vizinho mais próximo para manter o contorno nítido.
$esqueletos = Caminho $Eduardo @('sprite esqueleto', 'esqueletos')
$guerreiro = Caminho $esqueletos @('Guerreiro')
Salvar-Sprite 'spr_esqueleto_parado' (Quadros-Arquivos (Caminho $guerreiro @('Parado'))) 1 -PixelArt
Salvar-Sprite 'spr_esqueleto_andando' (Quadros-Arquivos (Caminho $guerreiro @('Andando'))) 1 -PixelArt
Salvar-Sprite 'spr_esqueleto_correndo' (Quadros-Arquivos (Caminho $guerreiro @('Corendo'))) 1 -PixelArt
Salvar-Sprite 'spr_esqueleto_ataque' (Quadros-Arquivos (Caminho $guerreiro @('Ataque'))) 1 -PixelArt
Salvar-Sprite 'spr_esqueleto_dano' (Quadros-Arquivos (Caminho $guerreiro @('Sofrendo Damage'))) 1 -PixelArt
Salvar-Sprite 'spr_esqueleto_morrendo' (Quadros-Arquivos (Caminho $guerreiro @('Morrendo'))) 1 -PixelArt

$arqueiro = Caminho $esqueletos @('Arqueiro')
Salvar-Sprite 'spr_inimigo02_parado' (Quadros-Arquivos (Caminho $arqueiro @('Parado'))) 1 -PixelArt
Salvar-Sprite 'spr_inimigo02_correndo' (Quadros-Arquivos (Caminho $arqueiro @('Correndo'))) 1 -PixelArt
Salvar-Sprite 'spr_inimigo02_atacando' (Quadros-Arquivos (Caminho $arqueiro @('ataque'))) 1 -PixelArt
Salvar-Sprite 'spr_inimigo02_morrendo' (Quadros-Arquivos (Caminho $arqueiro @('Morrendo'))) 1 -PixelArt
Salvar-Sprite 'spr_inimigo02_sofrendo_dano' (Quadros-Arquivos (Caminho $arqueiro @('Sofrendo damge'))) 1 -PixelArt

$porco = Caminho $Eduardo @('Porco corrompido')
Salvar-Sprite 'spr_porco_parado' (Quadros-Arquivos (Caminho $porco @('parado'))) 1 -PixelArt
Salvar-Sprite 'spr_porco_correndo' (Quadros-Arquivos (Caminho $porco @('porco correndo'))) 1 -PixelArt
Salvar-Sprite 'spr_porco_ataque' (Quadros-Arquivos (Caminho $porco @('porco ataque vermelho (normal)'))) 1 -PixelArt
Salvar-Sprite 'spr_porco_roxo' (Quadros-Arquivos (Caminho $porco @('porco ataque especial roxo'))) 1 -PixelArt
Salvar-Sprite 'spr_porco_salto' (Quadros-Arquivos (Caminho $porco @('saltando'))) 1 -PixelArt
Salvar-Sprite 'spr_porco_furia' (Quadros-Arquivos (Pasta-NaPasta $porco 'porco em furia ou fazendo invoca*')) 1 -PixelArt
Salvar-Sprite 'spr_porco_invocar' (Quadros-Arquivos (Pasta-NaPasta $porco 'invoca* 2')) 1 -PixelArt
Salvar-Sprite 'spr_porco_morrendo' (Quadros-Arquivos (Caminho $porco @('morrendo'))) 1 -PixelArt

$arvores = Caminho $Eduardo @('sprite Arvore', 'sprites_arvores_70x92')
Salvar-Sprite 'spr_boss_01' (Quadros-Arquivos (Caminho $arvores @('arvore_assombrada'))) 1 -PixelArt
Salvar-Sprite 'spr_boss_01_parado' (Quadros-Arquivos (Caminho $arvores @('arvore_amaldicoada'))) 1 -PixelArt
$arvoreAtaque = Caminho (Pasta-NaPasta $Eduardo 'invoca* arvore') @('sprites_arvore_invocacao_bola_de_fogo_70x92', 'arvore_bola_de_fogo')
Salvar-Sprite 'spr_boss_01_atacando' (Quadros-Arquivos $arvoreAtaque) 1 -PixelArt
$projetil = Caminho $arvoreAtaque @('Bola de Fogo', 'projetil_bola_de_fogo')
Salvar-Sprite 'spr_boss_01_bola_de_fogo' (Quadros-Arquivos $projetil) 1 -PixelArt

Write-Host ''
Write-Host 'Sprites refatorados com sucesso. As máscaras lógicas permanecem intactas.'
