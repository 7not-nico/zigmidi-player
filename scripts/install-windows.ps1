# MIDI Player - Windows Installation Script
# Run with: powershell -ExecutionPolicy Bypass -File install-windows.ps1

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  MIDI Player - Windows Installer" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Installation directory
$installDir = "$env:LOCALAPPDATA\MIDIPlayer"
$dataDir = "$env:APPDATA\midi-player"

# Check if binary exists
if (-not (Test-Path ".\midi_player.exe")) {
    Write-Host "Error: midi_player.exe not found!" -ForegroundColor Red
    Write-Host "Please build the application first using: zig build -Dtarget=x86_64-windows"
    pause
    exit 1
}

# Create installation directory
Write-Host "Creating installation directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Write-Host "[OK] Directory created: $installDir" -ForegroundColor Green

# Copy files
Write-Host ""
Write-Host "Copying application files..." -ForegroundColor Yellow
Copy-Item ".\midi_player.exe" "$installDir\" -Force
Write-Host "[OK] Binary installed" -ForegroundColor Green

# Copy DLLs if they exist (for bundled distribution)
if (Test-Path ".\*.dll") {
    Copy-Item ".\*.dll" "$installDir\" -Force
    Write-Host "[OK] Libraries copied" -ForegroundColor Green
}

# Copy resources
if (Test-Path ".\soundfonts") {
    Copy-Item ".\soundfonts" "$installDir\" -Recurse -Force
    Write-Host "[OK] SoundFonts copied" -ForegroundColor Green
}

if (Test-Path ".\midis") {
    Copy-Item ".\midis" "$installDir\" -Recurse -Force
    Write-Host "[OK] Sample MIDI files copied" -ForegroundColor Green
}

# Create user data directory
Write-Host ""
Write-Host "Creating user data directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "$dataDir" -Force | Out-Null
New-Item -ItemType Directory -Path "$dataDir\soundfonts" -Force | Out-Null
New-Item -ItemType Directory -Path "$dataDir\midis" -Force | Out-Null
Write-Host "[OK] User directories created" -ForegroundColor Green

# Add to PATH
Write-Host ""
Write-Host "Adding to PATH..." -ForegroundColor Yellow
$path = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($path -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$path;$installDir", "User")
    Write-Host "[OK] Added to user PATH" -ForegroundColor Green
    Write-Host "    Note: Restart your terminal to use 'midi_player' command" -ForegroundColor Cyan
} else {
    Write-Host "[OK] Already in PATH" -ForegroundColor Green
}

# Create Start Menu shortcut
Write-Host ""
Write-Host "Creating Start Menu shortcut..." -ForegroundColor Yellow
$startMenuDir = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\MIDI Player"
New-Item -ItemType Directory -Path $startMenuDir -Force | Out-Null

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$startMenuDir\MIDI Player.lnk")
$Shortcut.TargetPath = "$installDir\midi_player.exe"
$Shortcut.WorkingDirectory = $installDir
$Shortcut.Description = "MIDI Player with FluidSynth"
$Shortcut.Save()
Write-Host "[OK] Shortcut created" -ForegroundColor Green

# Optional: Desktop shortcut
Write-Host ""
$createDesktop = Read-Host "Create desktop shortcut? (y/N)"
if ($createDesktop -eq "y" -or $createDesktop -eq "Y") {
    $DesktopShortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\MIDI Player.lnk")
    $DesktopShortcut.TargetPath = "$installDir\midi_player.exe"
    $DesktopShortcut.WorkingDirectory = $installDir
    $DesktopShortcut.Description = "MIDI Player with FluidSynth"
    $DesktopShortcut.Save()
    Write-Host "[OK] Desktop shortcut created" -ForegroundColor Green
}

# Installation complete
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "[OK] Installation Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installation directory: $installDir" -ForegroundColor Cyan
Write-Host "User data directory:    $dataDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Run with: midi_player <file.mid>" -ForegroundColor White
Write-Host "Or use the Start Menu shortcut" -ForegroundColor White
Write-Host ""
Write-Host "Note: FluidSynth is required. Install via vcpkg or msys2 if not bundled." -ForegroundColor Yellow
Write-Host ""

pause
