@echo off
REM MIDI Player - Windows Uninstallation Script

echo ======================================
echo   MIDI Player - Windows Uninstaller
echo ======================================
echo.

REM Stop running instances
echo Checking for running instances...
tasklist /FI "IMAGENAME eq midi_player.exe" 2>NUL | find /I /N "midi_player.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo Stopping MIDI Player...
    taskkill /F /IM midi_player.exe /T 2>NUL
    timeout /t 2 /nobreak >NUL
    echo [OK] Stopped
) else (
    echo [OK] No running instances
)

echo.
echo This will remove:
echo   - Application files from %LOCALAPPDATA%\MIDIPlayer
echo   - Start Menu shortcuts
echo   - MIDI Player from PATH

echo.
set /p confirm="Continue with uninstallation? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Uninstallation cancelled.
    pause
    exit /b
)

REM Remove installation directory
echo.
echo Removing application files...
if exist "%LOCALAPPDATA%\MIDIPlayer\" (
    rd /s /q "%LOCALAPPDATA%\MIDIPlayer"
    echo [OK] Application files removed
) else (
    echo [!] Installation directory not found
)

REM Remove shortcuts
echo.
echo Removing shortcuts...
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\MIDI Player\" (
    rd /s /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\MIDI Player"
    echo [OK] Start Menu shortcut removed
)

if exist "%USERPROFILE%\Desktop\MIDI Player.lnk" (
    del "%USERPROFILE%\Desktop\MIDI Player.lnk"
    echo [OK] Desktop shortcut removed
)

REM Ask about user data
echo.
echo User data location: %APPDATA%\midi-player
if exist "%APPDATA%\midi-player\" (
    for /f %%A in ('powershell -command "(Get-ChildItem -Path '%APPDATA%\midi-player' -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB"') do set size=%%A
    echo Size: !size! MB
    echo.
    set /p removedata="Remove user configuration and data? (Y/N): "
    if /i "!removedata!"=="Y" (
        echo.
        set /p confirmdata="This cannot be undone. Are you sure? (Y/N): "
        if /i "!confirmdata!"=="Y" (
            rd /s /q "%APPDATA%\midi-player"
            rd /s /q "%LOCALAPPDATA%\midi-player" 2>NUL
            echo [OK] User data removed
        ) else (
            echo User data kept
        )
    ) else (
        echo User data kept
    )
) else (
    echo [!] No user data found
)

REM Note about PATH (manual removal required)
echo.
echo ======================================
echo [!] Manual Step Required
echo ======================================
echo.
echo Please manually remove "%LOCALAPPDATA%\MIDIPlayer" from your PATH:
echo 1. Open System Properties ^> Environment Variables
echo 2. Edit user PATH variable
echo 3. Remove the MIDIPlayer entry
echo.
echo Or run this PowerShell command:
echo [Environment]::SetEnvironmentVariable('PATH', ([Environment]::GetEnvironmentVariable('PATH', 'User') -replace ';%LOCALAPPDATA%\\MIDIPlayer', ''), 'User')
echo.

REM Verify removal
echo.
echo Verifying uninstallation...
where midi_player >NUL 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [OK] Verified: midi_player not found in PATH
) else (
    echo [!] Warning: midi_player still found in PATH
    echo Please restart your terminal or remove from PATH manually
)

REM Uninstall complete
echo.
echo ======================================
echo [OK] Uninstallation Complete!
echo ======================================
echo.

pause
