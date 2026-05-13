$port = 8765
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$port/")

try {
    $listener.Start()

    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch "Loopback" -and $_.PrefixOrigin -ne "WellKnown" } | Select-Object -First 1).IPAddress
    if (-not $ip) { $ip = "localhost" }

    Write-Host ""
    Write-Host "  Server running on:" -ForegroundColor White
    Write-Host "  PC:   http://localhost:$port" -ForegroundColor Cyan
    Write-Host "  Phone: http://${ip}:$port" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Press Ctrl+C to stop" -ForegroundColor DarkGray
    Write-Host ""

    $mimeTypes = @{
        ".html" = "text/html; charset=utf-8"
        ".css"  = "text/css; charset=utf-8"
        ".js"   = "application/javascript; charset=utf-8"
        ".png"  = "image/png"
        ".jpg"  = "image/jpeg"
        ".jpeg" = "image/jpeg"
        ".gif"  = "image/gif"
        ".svg"  = "image/svg+xml"
        ".ico"  = "image/x-icon"
    }

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.LocalPath.TrimStart('/')
        if ($path -eq "") { $path = "index.html" }
        $filePath = Join-Path $root $path

        if (Test-Path $filePath -Type Leaf) {
            $ext = [IO.Path]::GetExtension($filePath).ToLower()
            $mime = $mimeTypes[$ext]
            if (-not $mime) { $mime = "application/octet-stream" }

            $response.ContentType = $mime
            $bytes = [IO.File]::ReadAllBytes($filePath)
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
        }
        $response.Close()
    }
} finally {
    $listener.Stop()
}
