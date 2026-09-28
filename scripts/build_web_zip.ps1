# Builds Flutter web + deploy zip with version cache-bust files.
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -match 'version:\s*([0-9.]+)\+([0-9]+)') {
    $version = $Matches[1]
    $build = $Matches[2]
} else {
    throw "Could not read version from pubspec.yaml"
}

$versionTag = "$version+$build"
$builtAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

Write-Host "Building HisabPro web $versionTag ..."

# Keep assets/version.json in sync with pubspec
@{
    app = "hisab_pro"
    version = $version
    build = [int]$build
    ui = "commission-ui-v1"
    built_at = $builtAt
} | ConvertTo-Json | Set-Content "assets\version.json" -Encoding UTF8

flutter build web --release --base-href / --no-tree-shake-icons

$dest = Join-Path $root "UPLOAD-TO-WEBSITE"
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
New-Item -ItemType Directory -Path $dest | Out-Null
Copy-Item "build\web\*" $dest -Recurse -Force
Copy-Item "web\.htaccess" (Join-Path $dest ".htaccess") -Force

# Rename main.dart.js so browsers/CDN cannot serve an old cached copy
$jsTag = $versionTag.Replace('+', '_').Replace('.', '_')
$versionedMainJs = "main.dart.$jsTag.js"
Copy-Item (Join-Path $dest "main.dart.js") (Join-Path $dest $versionedMainJs) -Force
$bootstrapPath = Join-Path $dest "flutter_bootstrap.js"
$bootstrap = Get-Content $bootstrapPath -Raw
$bootstrap = $bootstrap.Replace('"mainJsPath":"main.dart.js"', "`"mainJsPath`":`"$versionedMainJs`"")
$bootstrap = $bootstrap.Replace('main.dart.js', $versionedMainJs)
Set-Content $bootstrapPath $bootstrap -Encoding UTF8 -NoNewline
Write-Host "Cache-bust JS: $versionedMainJs"

# Root cache-bust file — open /cache_version.json after deploy to verify
@{
    app = "hisab_pro"
    version = $version
    build = [int]$build
    tag = $versionTag
    ui = "commission-ui-v1"
    main_js = $versionedMainJs
    built_at = $builtAt
} | ConvertTo-Json | Set-Content (Join-Path $dest "cache_version.json") -Encoding UTF8

Copy-Item (Join-Path $dest "check-deploy.php") -ErrorAction SilentlyContinue

@'
<?php
header('Content-Type: text/plain; charset=utf-8');
$checks = [
    'index.html' => 'Main page',
    'cache_version.json' => 'Deploy version (cache check)',
    'assets/FontManifest.json' => 'Icon fonts',
    'assets/fonts/MaterialIcons-Regular.otf' => 'Material Icons',
    'assets/assets/version.json' => 'Bundled app version',
    'canvaskit/canvaskit.js' => 'CanvasKit',
];
$allOk = true;
foreach ($checks as $path => $label) {
    $ok = file_exists(__DIR__ . '/' . $path);
    echo ($ok ? 'OK' : 'MISSING') . " — $path ($label)\n";
    if (!$ok) $allOk = false;
}
if (file_exists(__DIR__ . '/cache_version.json')) {
    echo "\nDeployed: " . file_get_contents(__DIR__ . '/cache_version.json') . "\n";
}
echo "\n" . ($allOk ? "ALL OK — hard refresh with Ctrl+Shift+R\n" : "UPLOAD INCOMPLETE\n");
'@ | Set-Content (Join-Path $dest "check-deploy.php") -Encoding UTF8

$zip = Join-Path $root "hisabpro-web-deploy.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
tar -a -cf $zip -C $dest .

Write-Host ""
Write-Host "Done: $zip"
Write-Host "Version: $versionTag (ui: light-result-box)"
Write-Host "After upload check: https://hisabpro.dise.org.in/cache_version.json"
