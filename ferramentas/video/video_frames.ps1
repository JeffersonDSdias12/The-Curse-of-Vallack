param(
    [string]$Video,
    [string]$Saida,
    [double]$Fps = 24,
    [int]$Largura = 0,
    [int]$Altura = 0,
    [double]$Inicio = 0,
    [double]$Fim = -1,
    [double]$Passo = 0
)
# Extrai quadros de um vídeo com as APIs de mídia do Windows (WinRT), sem ffmpeg.
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
$null = [Windows.Media.Editing.MediaComposition, Windows.Media.Editing, ContentType = WindowsRuntime]
$null = [Windows.Media.Editing.MediaClip, Windows.Media.Editing, ContentType = WindowsRuntime]
$null = [Windows.Storage.Streams.IRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime]

$asTaskGen = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
function Await($op, [Type]$tipo) {
    $m = $asTaskGen.MakeGenericMethod($tipo)
    $t = $m.Invoke($null, @($op))
    $t.Wait() | Out-Null
    $t.Result
}

$arq = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($Video)) ([Windows.Storage.StorageFile])
$clip = Await ([Windows.Media.Editing.MediaClip]::CreateFromFileAsync($arq)) ([Windows.Media.Editing.MediaClip])
$comp = New-Object Windows.Media.Editing.MediaComposition
[System.Collections.Generic.ICollection[Windows.Media.Editing.MediaClip]].GetMethod("Add").Invoke($comp.Clips, @($clip)) | Out-Null
$dur = $comp.Duration.TotalSeconds
$props = $clip.GetVideoEncodingProperties()
"duracao=$dur largura=$($props.Width) altura=$($props.Height)"
if ($Largura -le 0) { $Largura = $props.Width }
if ($Altura -le 0) { $Altura = $props.Height }
if ($Fim -lt 0) { $Fim = $dur }
if ($Passo -le 0) { $Passo = 1.0 / $Fps }
New-Item -ItemType Directory -Force $Saida | Out-Null
$i = 0
$t = $Inicio
while ($t -lt $Fim - 0.0001) {
    $ts = [TimeSpan]::FromTicks([long]($t * 10000000))
    $img = Await ($comp.GetThumbnailAsync($ts, $Largura, $Altura, [Windows.Media.Editing.VideoFramePrecision]::NearestFrame)) ([Windows.Graphics.Imaging.ImageStream])
    $net = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($img)
    $fs = [System.IO.File]::Create((Join-Path $Saida ("q{0:D4}.jpg" -f $i)))
    $net.CopyTo($fs)
    $fs.Close()
    $net.Close()
    $i++
    $t = $Inicio + $i * $Passo
}
"quadros=$i"
