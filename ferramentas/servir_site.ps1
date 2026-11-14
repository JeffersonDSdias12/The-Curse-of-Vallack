# Serve a pasta site/ em http://localhost:8765 para conferir o site no navegador
# (abrir o index.html direto do disco também funciona; isto é só para testes).
param([int]$Porta = 8765)
$raiz = Join-Path (Split-Path $PSScriptRoot -Parent) "site"
$tipos = @{ ".html" = "text/html; charset=utf-8"; ".css" = "text/css"; ".js" = "text/javascript"; ".png" = "image/png"; ".jpg" = "image/jpeg";
    ".ico" = "image/x-icon"; ".json" = "application/json"; ".apk" = "application/vnd.android.package-archive"; ".exe" = "application/octet-stream" }
$http = New-Object System.Net.HttpListener
$http.Prefixes.Add("http://localhost:$Porta/")
$http.Start()
"servindo $raiz em http://localhost:$Porta/"
while ($http.IsListening) {
    $ctx = $http.GetContext()
    try {
        $rel = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart("/")
        if ($rel -eq "") { $rel = "index.html" }
        $arq = [IO.Path]::GetFullPath((Join-Path $raiz $rel))
        if ($arq.StartsWith($raiz) -and (Test-Path $arq -PathType Leaf)) {
            $ext = [IO.Path]::GetExtension($arq).ToLower()
            $ctx.Response.ContentType = $(if ($tipos.ContainsKey($ext)) { $tipos[$ext] } else { "application/octet-stream" })
            $fs = [IO.File]::OpenRead($arq)
            $ctx.Response.ContentLength64 = $fs.Length
            if ($ctx.Request.HttpMethod -ne "HEAD") { $fs.CopyTo($ctx.Response.OutputStream) }
            $fs.Close()
        } else { $ctx.Response.StatusCode = 404 }
    } catch { try { $ctx.Response.StatusCode = 500 } catch {} }
    try { $ctx.Response.Close() } catch {}
}
