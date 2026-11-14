# Varredura de sprites, quadros e mascaras (GameMaker x Godot). So le; nao altera nada.
# Uso: powershell -File ferramentas\varredura_sprites.ps1
$raiz = Split-Path $PSScriptRoot -Parent
Add-Type -AssemblyName System.Drawing, System.Web.Extensions
Add-Type -Path "$PSScriptRoot\VarreduraSprites.cs" -ReferencedAssemblies System.Drawing, System.Web.Extensions
[VarreduraSprites]::Rodar($raiz)
