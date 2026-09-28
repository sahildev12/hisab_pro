# Maintenance page deploy zip (replaces Flutter app on main domain temporarily).
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$src = Join-Path $root "maintenance"
$dest = Join-Path $root "UPLOAD-MAINTENANCE"
$zip = Join-Path $root "hisabpro-maintenance-deploy.zip"

if (-not (Test-Path (Join-Path $src "index.html"))) {
    throw "maintenance/index.html not found"
}

if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
New-Item -ItemType Directory -Path $dest | Out-Null
Copy-Item "$src\*" $dest -Recurse -Force

@'
AddType text/html .html
<IfModule mod_headers.c>
  <FilesMatch "\.(html)$">
    Header set Cache-Control "no-cache, no-store, must-revalidate"
  </FilesMatch>
</IfModule>
'@ | Set-Content (Join-Path $dest ".htaccess") -Encoding UTF8

@'
HISABPRO — MAINTENANCE PAGE UPLOAD
==================================

Upload ALL files in this zip to your website root (public_html).
This REPLACES the Flutter app temporarily.

Files:
  index.html   — AWS maintenance page (main page visitors see)
  .htaccess    — no-cache for HTML

Edit backup server URL before upload:
  Open index.html and change BACKUP_SERVER_URL at the bottom.

After upload, visit your domain — you should see the AWS maintenance page,
NOT the HisabPro app.

To restore the app later, upload hisabpro-web-deploy.zip instead.
'@ | Set-Content (Join-Path $dest "UPLOAD-README.txt") -Encoding UTF8

if (Test-Path $zip) { Remove-Item $zip -Force }
tar -a -cf $zip -C $dest .

Write-Host ""
Write-Host "Done: $zip"
Write-Host "Upload folder: $dest"
Write-Host "Edit BACKUP_SERVER_URL in maintenance/index.html if needed, then re-run this script."
