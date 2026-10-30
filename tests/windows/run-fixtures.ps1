param(
    [string]$App,
    [string]$Output
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $App) { $App = Join-Path $repo 'development\app\Cued.exe' }
if (-not $Output) { $Output = Join-Path $repo 'test-output\windows-fixtures.json' }
$App = [IO.Path]::GetFullPath($App)
$Output = [IO.Path]::GetFullPath($Output)
New-Item -ItemType Directory -Path (Split-Path -Parent $Output) -Force | Out-Null
$runner = Join-Path (Split-Path -Parent $Output) 'FixtureParity.exe'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
& $compiler /nologo "/out:$runner" /reference:System.Web.Extensions.dll (Join-Path $PSScriptRoot 'FixtureParity.cs')
if ($LASTEXITCODE -ne 0) { throw 'Fixture harness compilation failed' }
& $runner $App (Join-Path $repo 'tests\fixtures') $Output
if ($LASTEXITCODE -ne 0) { throw 'Windows fixture parity failed' }
