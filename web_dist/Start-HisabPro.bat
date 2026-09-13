@echo off
title HisabPro
cd /d "%~dp0"
echo Starting HisabPro at http://localhost:8080
echo Close this window to stop the app.
start "" http://localhost:8080
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$listener = New-Object System.Net.HttpListener; $listener.Prefixes.Add('http://localhost:8080/'); $listener.Start(); Write-Host 'HisabPro is running...'; while ($listener.IsListening) { $context = $listener.GetContext(); $path = $context.Request.Url.LocalPath; if ($path -eq '/') { $path = '/index.html' }; $file = Join-Path (Get-Location) ($path.TrimStart('/').Replace('/', '\')); if (Test-Path $file -PathType Leaf) { $bytes = [System.IO.File]::ReadAllBytes($file); $context.Response.ContentLength64 = $bytes.Length; $ext = [System.IO.Path]::GetExtension($file).ToLower(); switch ($ext) { '.html' { $context.Response.ContentType = 'text/html' } '.js' { $context.Response.ContentType = 'application/javascript' } '.json' { $context.Response.ContentType = 'application/json' } '.wasm' { $context.Response.ContentType = 'application/wasm' } '.png' { $context.Response.ContentType = 'image/png' } default { $context.Response.ContentType = 'application/octet-stream' } }; $context.Response.OutputStream.Write($bytes, 0, $bytes.Length) } else { $context.Response.StatusCode = 404 }; $context.Response.Close() }"
