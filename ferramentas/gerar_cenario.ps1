# =====================================================================
#  Gera o cenário da FASE 1 (pixel art desenhada por código) para as duas
#  versões: datafiles/ (PC, GameMaker) e godot/assets/data/ (Android).
#  Uso:  powershell -File ferramentas/gerar_cenario.ps1
#  Depois, no Godot, importe a imagem nova (abrir o editor ou --import).
# =====================================================================
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
Add-Type -ReferencedAssemblies System.Drawing -Path (Join-Path $PSScriptRoot "GeraCenario.cs")
[Gera]::Gerar((Join-Path $raiz "datafiles"), (Join-Path $raiz "godot\assets\data"))
