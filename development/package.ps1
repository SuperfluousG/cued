param([Parameter(Mandatory=$true)][string] $OutputDirectory)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $output) { throw "Output already exists: $output. Choose a new candidate directory to preserve prior builds." }
$version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
& (Join-Path $PSScriptRoot 'app\build.ps1')
& (Join-Path $PSScriptRoot 'installer\build.ps1')
New-Item -ItemType Directory -Path $output | Out-Null
$stage = Join-Path $output "Cued-$version-windows-x64"
New-Item -ItemType Directory -Path "$stage\app", "$stage\source", "$stage\packages" | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'app\Cued.exe') -Destination "$stage\app\Cued.exe"
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'installer\CuedSetup.exe') -Destination "$stage\CuedSetup.exe"
Copy-Item -LiteralPath (Join-Path $root 'app\sample.cued.json') -Destination "$stage\app\sample.cued.json"
Copy-Item -LiteralPath (Join-Path $root 'app\launch.cmd') -Destination "$stage\app\launch.cmd"
Copy-Item -LiteralPath (Join-Path $root 'source\make-cued-deck') -Destination "$stage\source\make-cued-deck" -Recurse
# Copy only maintained skill sources, never Python runtime caches.
$cacheFiles = Get-ChildItem -LiteralPath "$stage\source" -File -Recurse | Where-Object { $_.Extension -eq '.pyc' }
if ($cacheFiles) { throw 'Unexpected Python cache in skill source; remove it from the source before packaging.' }
Compress-Archive -LiteralPath "$stage\source\make-cued-deck" -DestinationPath "$stage\packages\make-cued-deck-claude.zip"
$marketplace = Join-Path $output 'marketplace-stage'
New-Item -ItemType Directory -Path "$marketplace\.agents\plugins", "$marketplace\plugins\cued\.codex-plugin", "$marketplace\plugins\cued\skills" -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'openai-marketplace\.agents\plugins\marketplace.json') -Destination "$marketplace\.agents\plugins\marketplace.json"
Copy-Item -LiteralPath (Join-Path $root 'openai-marketplace\plugins\cued\.codex-plugin\plugin.json') -Destination "$marketplace\plugins\cued\.codex-plugin\plugin.json"
Copy-Item -LiteralPath "$stage\source\make-cued-deck" -Destination "$marketplace\plugins\cued\skills\make-cued-deck" -Recurse
# ZipFile includes dot directories on Windows and does not depend on hidden-file filtering.
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($marketplace, "$stage\packages\cued-openai-marketplace-$version.zip")
foreach ($file in @('QUICK-START.md','VERSION','RELEASE-NOTES.md')) { Copy-Item -LiteralPath (Join-Path $root $file) -Destination (Join-Path $stage $file) }
$commit = & git -C $root rev-parse HEAD
if ($LASTEXITCODE -ne 0) { throw 'Cannot identify source commit' }
Set-Content -LiteralPath "$stage\SOURCE-COMMIT.txt" -Value $commit -Encoding ascii
$entries = Get-ChildItem -LiteralPath $stage -File -Recurse | Sort-Object FullName | ForEach-Object { (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() + '  ' + $_.FullName.Substring($stage.Length + 1).Replace('\','/') }
[IO.File]::WriteAllLines("$stage\SHA256SUMS.txt", $entries, (New-Object Text.UTF8Encoding($false)))
$zip = "$stage.zip"
[IO.Compression.ZipFile]::CreateFromDirectory($stage, $zip)
(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant() + '  ' + [IO.Path]::GetFileName($zip) | Set-Content -LiteralPath "$output\SHA256SUMS.txt" -Encoding ascii
Write-Output $zip
