# =====================================================================
#  Trilha sonora (v1.16) para as duas versões:
#  datafiles/ (PC, GameMaker) e godot/assets/data/ (Android).
#   * as 5 músicas MP3 da pasta "Trilha sonora" viram OGG com o LOOP
#     fechado (o fim se mistura ao começo) e o volume igualado em -14 LUFS
#     (GeraTrilha.cs)
#   * sfx_important_message.ogg: impacto metálico grave sintetizado
#  O codificador é o ffmpeg que vem com o GameMaker (libvorbis).
#  Uso:  powershell -File ferramentas/converter_trilha.ps1 ["...\Trilha sonora"]
#        (depois --import no Godot)
# =====================================================================
param([string]$origem = (Join-Path ([Environment]::GetFolderPath("Desktop")) "Trilha sonora"))
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$ff = Get-ChildItem "C:\ProgramData\GameMakerStudio2*\Cache\runtimes\*\bin\ffmpeg\windows\ffmpeg.exe" -ErrorAction SilentlyContinue |
      Sort-Object FullName -Descending | Select-Object -First 1
if (-not $ff) { throw "ffmpeg do GameMaker nao encontrado (C:\ProgramData\GameMakerStudio2...\Cache\runtimes)" }
$ff = $ff.FullName
Add-Type -Path (Join-Path $PSScriptRoot "GeraTrilha.cs")

$ALVO_LUFS = -14.0       # mesmo nível da trilha antiga da fase (mus_fase)
$CRUZAR_S  = 4.0         # segundos de mistura entre o fim e o começo (loop)
$QUEDA_DB  = 6.0         # o fade-out final abaixo disto (do volume típico) sai
$QUALIDADE = 3           # libvorbis -q 3 (~112 kbps, 44,1 kHz)

$tmp = Join-Path ([IO.Path]::GetTempPath()) "vallack_trilha"
New-Item -ItemType Directory -Force $tmp | Out-Null
$destinos = @((Join-Path $raiz "datafiles"), (Join-Path $raiz "godot\assets\data"))

function Codificar($wav, $nome) {
    $ogg = Join-Path $tmp ($nome + ".ogg")
    & $ff -hide_banner -loglevel error -y -i $wav -c:a libvorbis -q:a $QUALIDADE $ogg
    if (-not (Test-Path $ogg)) { throw "falhou ao codificar $nome" }
    foreach ($d in $destinos) { Copy-Item $ogg (Join-Path $d ($nome + ".ogg")) -Force }
    "{0}.ogg  {1:N0} KB" -f $nome, ((Get-Item $ogg).Length / 1KB)
}

$trilhas = @(
    @("Trilha menu inicial\Before_the_Iron_Gate.mp3",        "bgm_main_menu"),
    @("trilha carregando fase\Before_The_Iron_Gate (1).mp3", "bgm_loading_screen"),
    @("trilha fase 1\Anvil_of_the_Gods.mp3",                 "bgm_battle_phase1"),
    @("trilha mini boss\Siege_at_Blackened_Keep.mp3",        "bgm_mini_boss"),
    @("Trilha boss fase 1\Weight_of_the_Fallen_Throne.mp3",  "bgm_final_boss_phase1")
)
foreach ($t in $trilhas) {
    $mp3 = Join-Path $origem $t[0]
    if (-not (Test-Path -LiteralPath $mp3)) { throw "nao achei $mp3" }
    $ent = Join-Path $tmp ($t[1] + "_mp3.wav")
    $sai = Join-Path $tmp ($t[1] + ".wav")
    & $ff -hide_banner -loglevel error -y -i $mp3 -vn -ac 2 -ar 44100 -c:a pcm_s16le $ent
    [GeraTrilha]::Loop($ent, $sai, $ALVO_LUFS, $CRUZAR_S, $QUEDA_DB)
    Codificar $sai $t[1]
}

$sfx = Join-Path $tmp "sfx_important_message.wav"
[GeraTrilha]::Aviso($sfx, -16.0)
Codificar $sfx "sfx_important_message"

Remove-Item $tmp -Recurse -Force
