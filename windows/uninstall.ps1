# Windows Uninstall Script for screenshot-clipboard-sync
$ErrorActionPreference = "SilentlyContinue"

Write-Host "🗑️ Uninstalling screenshot-clipboard-sync on Windows..." -ForegroundColor Yellow

# Stop running process
Get-Process -Name "screenshot-clipboard-sync" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

# Remove from Registry Startup (Current User Run)
$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Remove-ItemProperty -Path $RegistryPath -Name "ScreenshotClipboardSync" -ErrorAction SilentlyContinue

# Remove Installation Directory and executable
$InstallDir = Join-Path $env:APPDATA "screenshot-clipboard-sync"
if (Test-Path $InstallDir) {
    Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "✅ Uninstallation complete! Service stopped and cleaned up." -ForegroundColor Green
