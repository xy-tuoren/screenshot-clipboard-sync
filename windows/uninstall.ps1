# Windows Uninstall Script for screenshot-clipboard-sync
$ErrorActionPreference = "SilentlyContinue"

Write-Host "🗑️ Uninstalling screenshot-clipboard-sync on Windows..." -ForegroundColor Yellow

# Stop running process
Get-Process -Name "screenshot-clipboard-sync" | Stop-Process -Force

# Remove from Registry Startup
$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Remove-ItemProperty -Path $RegistryPath -Name "ScreenshotClipboardSync" -ErrorAction SilentlyContinue

# Remove Installation Directory and files
$InstallDir = Join-Path $env:APPDATA "screenshot-clipboard-sync"
if (Test-Path $InstallDir) {
    Remove-Item -Path $InstallDir -Recurse -Force
}

Write-Host "✅ Uninstallation complete! Service stopped and cleaned up." -ForegroundColor Green
