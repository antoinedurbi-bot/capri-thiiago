$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
if (-not $dir) { $dir = Get-Location }

$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) { $csc = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe" }

$wpf = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\WPF"
if (-not (Test-Path $wpf)) { $wpf = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\WPF" }

# Locate Windows.winmd
$winmd = "C:\Program Files (x86)\Windows Kits\10\UnionMetadata\10.0.26100.0\Windows.winmd"
if (-not (Test-Path $winmd)) {
    $found = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\UnionMetadata" -Filter "Windows.winmd" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $winmd = $found.FullName }
}

$capriRunning = Get-Process Capri -ErrorAction SilentlyContinue
if ($capriRunning) {
    Write-Host ">>> Capri is currently running. Skipping Capri.exe rebuild and using existing binary." -ForegroundColor Yellow
} else {
    Write-Host ">>> Building Capri.exe v0.2.1..." -ForegroundColor Cyan

    $files = Get-ChildItem "$dir\app\*.cs" | Where-Object { $_.Name -ne "Setup.cs" } | ForEach-Object { $_.FullName }
    $res = @(
        "/res:$dir\assets\chip.ico,Capri.Chip.ico",
        "/res:$dir\assets\fonts\ShareTechMono-Regular.ttf,Capri.Font.Mono.ttf"
    )
    Get-ChildItem "$dir\assets\sprites\*.png" | ForEach-Object {
        $res += "/res:$($_.FullName),Capri.Sprite.$($_.Name)"
    }

    $winmdArg = if (Test-Path $winmd) { "/r:`"$winmd`"" } else { "" }

    & $csc /nologo /target:winexe /out:"$dir\Capri.exe" /win32icon:"$dir\assets\chip.ico" $res /r:System.dll /r:System.Core.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll /r:System.Runtime.Serialization.dll /r:System.Xml.dll /r:System.IO.Compression.FileSystem.dll /r:System.Runtime.dll /r:System.Runtime.WindowsRuntime.dll /r:System.Runtime.InteropServices.WindowsRuntime.dll /r:"$wpf\WindowsBase.dll" /r:"$wpf\System.Speech.dll" /r:"$wpf\UIAutomationClient.dll" /r:"$wpf\UIAutomationTypes.dll" $winmdArg $files

    if ($LASTEXITCODE -ne 0) {
        Write-Host ">>> Error compiling Capri.exe!" -ForegroundColor Red
        exit 1
    }
    Write-Host ">>> Capri.exe successfully built!" -ForegroundColor Green
}

Write-Host ">>> Building Standalone Launcher & Installer (Capri-Setup.exe)..." -ForegroundColor Cyan

& $csc /nologo /target:winexe /out:"$dir\Capri-Setup.exe" /win32icon:"$dir\assets\chip.ico" /res:"$dir\assets\chip.ico,Capri.Chip.ico" /res:"$dir\assets\chip.png,Capri.Chip.png" /res:"$dir\Capri.exe,Capri.App.exe" /r:System.dll /r:System.Core.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll /r:Microsoft.CSharp.dll "$dir\app\Setup.cs" "$dir\app\AssemblyInfo.cs"

if ($LASTEXITCODE -eq 0) {
    Write-Host ">>> Capri-Setup.exe successfully built!" -ForegroundColor Green
} else {
    Write-Host ">>> Error compiling Capri-Setup.exe!" -ForegroundColor Red
    exit 1
}
