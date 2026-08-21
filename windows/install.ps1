# Windows Install Script for screenshot-clipboard-sync
$ErrorActionPreference = "Stop"

Write-Host "🚀 Installing screenshot-clipboard-sync on Windows..." -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceFile = Join-Path $ScriptDir "src\Program.cs"
$InstallDir = Join-Path $env:APPDATA "screenshot-clipboard-sync"
$TargetExe = Join-Path $InstallDir "screenshot-clipboard-sync.exe"

# Create installation directory
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# Stop any running instances
Get-Process -Name "screenshot-clipboard-sync" -ErrorAction SilentlyContinue | Stop-Process -Force

# Locate C# Compiler (csc.exe is built into every Windows 10/11 system)
$CscPath = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $CscPath)) {
    $CscPath = "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}

if (-not (Test-Path $CscPath)) {
    Write-Host "❌ Error: C# compiler (csc.exe) not found in .NET Framework." -ForegroundColor Red
    exit 1
}

Write-Host "📦 Compiling native Windows executable..." -ForegroundColor Yellow
$CompileArgs = @(
    "/target:winexe",
    "/optimize+",
    "/out:$TargetExe",
    "/reference:System.dll",
    "/reference:System.Drawing.dll",
    "/reference:System.Windows.Forms.dll",
    "$SourceFile"
)

$Process = Start-Process -FilePath $CscPath -ArgumentList $CompileArgs -Wait -NoNewWindow -PassThru
if ($Process.ExitCode -ne 0) {
    Write-Host "❌ Error: Compilation failed." -ForegroundColor Red
    exit 1
}

Write-Host "⚙️ Registering Windows Startup (HKCU\Software\Microsoft\Windows\CurrentVersion\Run)..." -ForegroundColor Yellow
$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $RegistryPath -Name "ScreenshotClipboardSync" -Value "`"$TargetExe`"" -Force

Write-Host "🔄 Starting background service..." -ForegroundColor Yellow
Start-Process -FilePath $TargetExe

Write-Host ""
Write-Host "✅ Installation complete!" -ForegroundColor Green
Write-Host "✨ screenshot-clipboard-sync is now running in the background and will start on boot." -ForegroundColor Green
Write-Host ""
Write-Host "💡 Windows Terminal Tip:" -ForegroundColor Cyan
Write-Host "   In Windows Terminal / PowerShell / Git Bash, right-click or press Ctrl+V to paste the image path!"
