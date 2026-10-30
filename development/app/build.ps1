$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$framework = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319'
$wpf = Join-Path $framework 'WPF'
$compiler = Join-Path $framework 'csc.exe'
$source = Join-Path $root 'Cued.cs'
$output = Join-Path $root 'Cued.exe'
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
    /reference:"$(Join-Path $wpf 'PresentationCore.dll')" `
    /reference:"$(Join-Path $wpf 'PresentationFramework.dll')" `
    /reference:"$(Join-Path $wpf 'WindowsBase.dll')" `
    /reference:"$(Join-Path $framework 'System.Xaml.dll')" `
    /reference:"$(Join-Path $framework 'System.Web.Extensions.dll')" `
    /reference:"$(Join-Path $framework 'System.dll')" `
    /reference:"$(Join-Path $framework 'System.Core.dll')" `
    $source `
    (Join-Path $root 'DeckLoader.cs') `
    (Join-Path $root 'PlayerSettings.cs') `
    (Join-Path $root '..\common\ProviderHandoff.cs')

if ($LASTEXITCODE -ne 0) {
    throw "Compilation failed with exit code $LASTEXITCODE"
}

Write-Host "Built $output"
