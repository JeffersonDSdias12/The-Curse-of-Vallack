# =====================================================================
#  Gera as FOTOS das 18 fases do MAPA DE VALLACK (v1.17) para as duas
#  versões: datafiles/ (PC, GameMaker) e godot/assets/data/ (Android).
#   mapa_fases.jpg  6 x 3 fotos de 320 x 180 (GeraMapa.cs). A fase 1 usa a
#                   arte de verdade da vila (rode antes gerar_cenario.ps1).
#  Uso:  powershell -File ferramentas/gerar_mapa.ps1   (depois --import no Godot)
# =====================================================================
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
Add-Type -ReferencedAssemblies System.Drawing -Path (Join-Path $PSScriptRoot "GeraMapa.cs")
[GeraMapa]::Gerar((Join-Path $raiz "datafiles"), (Join-Path $raiz "godot\assets\data"))
