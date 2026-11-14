# Exporta as imagens dos personagens (Figuras 01 a 10) para documentos.
# Saida: imagens_documento/ (com fundo) e imagens_documento/fundo transparente/
# Uso: powershell -File ferramentas\exportar_figuras.ps1
$raiz = Split-Path $PSScriptRoot -Parent
Add-Type -AssemblyName System.Drawing
Add-Type -Path "$PSScriptRoot\ExportaFiguras.cs" -ReferencedAssemblies System.Drawing
[ExportaFiguras]::Rodar($raiz, (Join-Path $raiz "imagens_documento"))
