param([string] $App, [string] $OutputDirectory)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $App) { $App = Join-Path $root 'development\app\Cued.exe' }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $env:TEMP ('cued-player-tests-' + [Guid]::NewGuid().ToString('N')) }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$framework = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319'
$wpf = Join-Path $framework 'WPF'
$exe = Join-Path $OutputDirectory 'PlayerTests.exe'
& "$framework\csc.exe" /nologo /target:exe /platform:x64 "/out:$exe" "/reference:$wpf\PresentationCore.dll" "/reference:$wpf\PresentationFramework.dll" "/reference:$wpf\WindowsBase.dll" "/reference:$framework\System.Xaml.dll" "/reference:$framework\System.Web.Extensions.dll" (Join-Path $PSScriptRoot 'player-tests.cs')
if ($LASTEXITCODE -ne 0) { throw 'Player test compilation failed' }
& $exe $App $OutputDirectory (Join-Path $root 'tests\fixtures') | Tee-Object -FilePath (Join-Path $OutputDirectory 'player-tests.json')
if ($LASTEXITCODE -ne 0) { throw 'Player tests failed' }
