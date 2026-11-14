param([string]$Video, [string]$PastaSaida, [string]$Nome)
# Extrai a trilha de áudio de um vídeo para WAV com o MediaTranscoder do Windows (WinRT).
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
$null = [Windows.Storage.StorageFolder, Windows.Storage, ContentType = WindowsRuntime]
$null = [Windows.Media.Transcoding.MediaTranscoder, Windows.Media.Transcoding, ContentType = WindowsRuntime]
$null = [Windows.Media.MediaProperties.MediaEncodingProfile, Windows.Media.MediaProperties, ContentType = WindowsRuntime]

$metodos = [System.WindowsRuntimeSystemExtensions].GetMethods()
$asTaskOp = ($metodos | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
$asTaskAcao = ($metodos | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncActionWithProgress`1' })[0]
function Await($op, [Type]$tipo) { $t = $asTaskOp.MakeGenericMethod($tipo).Invoke($null, @($op)); $t.Wait() | Out-Null; $t.Result }

$entrada = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($Video)) ([Windows.Storage.StorageFile])
$pasta = Await ([Windows.Storage.StorageFolder]::GetFolderFromPathAsync($PastaSaida)) ([Windows.Storage.StorageFolder])
$saida = Await ($pasta.CreateFileAsync($Nome, [Windows.Storage.CreationCollisionOption]::ReplaceExisting)) ([Windows.Storage.StorageFile])
$perfil = [Windows.Media.MediaProperties.MediaEncodingProfile]::CreateWav([Windows.Media.MediaProperties.AudioEncodingQuality]::High)
$perfil.Video = $null
$tr = New-Object Windows.Media.Transcoding.MediaTranscoder
$prep = Await ($tr.PrepareFileTranscodeAsync($entrada, $saida, $perfil)) ([Windows.Media.Transcoding.PrepareTranscodeResult])
"pode=$($prep.CanTranscode) motivo=$($prep.FailureReason)"
if ($prep.CanTranscode) {
    $t = $asTaskAcao.MakeGenericMethod([double]).Invoke($null, @($prep.TranscodeAsync()))
    $t.Wait() | Out-Null
    "ok"
}
