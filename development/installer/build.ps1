$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$framework = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319'
$compiler = Join-Path $framework 'csc.exe'
$source = Join-Path $root 'CuedSetup.cs'
$output = Join-Path $root 'CuedSetup.exe'
$iconRoot = Join-Path (Split-Path -Parent $root) 'icon'
$icon = Join-Path $iconRoot 'cued.ico'
$iconBuilder = Join-Path $iconRoot 'build-icon.ps1'

if (-not (Test-Path -LiteralPath $compiler)) {
    throw "The Windows .NET Framework compiler was not found at $compiler"
}

if (-not (Test-Path -LiteralPath $icon)) {
    & $iconBuilder
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $icon)) {
        throw "The Cued icon could not be built."
    }
}

& $compiler `
    /nologo `
    /target:winexe `
    /platform:x64 `
    /optimize+ `
    "/win32icon:$icon" `
    /out:$output `
    /reference:"$(Join-Path $framework 'System.dll')" `
    /reference:"$(Join-Path $framework 'System.Core.dll')" `
    /reference:"$(Join-Path $framework 'System.Drawing.dll')" `
    /reference:"$(Join-Path $framework 'System.Windows.Forms.dll')" `
    $source

if ($LASTEXITCODE -ne 0) {
    throw "Compilation failed with exit code $LASTEXITCODE"
}

Write-Host "Built $output"
