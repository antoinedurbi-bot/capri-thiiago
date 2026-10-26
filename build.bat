@echo off
setlocal
cd /d "%~dp0"
echo ===================================================
echo   Compiling Capri Desktop v0.2.1
echo ===================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1"
if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Capri.exe compiled successfully!
) else (
    echo.
    echo [ERROR] Build failed. See output above.
)
pause
