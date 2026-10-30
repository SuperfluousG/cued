param([string] $OutputDirectory)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $env:TEMP ('cued-installer-evidence-' + [Guid]::NewGuid().ToString('N')) }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$framework = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319'
$exe = Join-Path $OutputDirectory 'InstallerTests.exe'
& "$framework\csc.exe" /nologo /target:exe "/out:$exe" (Join-Path $PSScriptRoot 'installer-tests.cs')
if ($LASTEXITCODE -ne 0) { throw 'Installer test compilation failed' }
& $exe (Join-Path $root 'development\installer\CuedSetup.exe') | Tee-Object -FilePath (Join-Path $OutputDirectory 'installer-copy-tests.json')
if ($LASTEXITCODE -ne 0) { throw 'Installer tests failed' }
