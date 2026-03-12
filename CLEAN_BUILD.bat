@echo off
setlocal EnableDelayedExpansion

echo ============================================
echo CLEAN BUILD SCRIPT FOR DOMESTIC APP
echo ============================================
echo.

:: Kill all Java processes
echo [1] Killing any running Java/Gradle processes...
taskkill /F /IM java.exe /T >nul 2>&1
timeout /t 2 /nobreak >nul
echo Done.
echo.

:: Delete Gradle user home cache
echo [2] Deleting Gradle cache...
if exist "%USERPROFILE%\.gradle\caches" (
    rd /s /q "%USERPROFILE%\.gradle\caches" 2>nul
)
if exist "%USERPROFILE%\.gradle\daemon" (
    rd /s /q "%USERPROFILE%\.gradle\daemon" 2>nul
)
echo Done.
echo.

:: Flutter clean
echo [3] Running Flutter clean...
call flutter clean
echo Done.
echo.

:: Clean Android build directories
echo [4] Cleaning Android build folders...
cd /d "%~dp0android"
if exist build rd /s /q build 2>nul
if exist app\build rd /s /q app\build 2>nul
if exist .gradle rd /s /q .gradle 2>nul
cd /d "%~dp0"
echo Done.
echo.

:: Get dependencies
echo [5] Getting Flutter dependencies...
call flutter pub get
echo Done.
echo.

:: Build and run
echo [6] Building and running app...
echo This will take 3-5 minutes on first run...
echo.
call flutter run --verbose

echo.
echo ============================================
echo BUILD COMPLETE
echo ============================================
pause
