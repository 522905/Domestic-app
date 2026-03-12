@echo off
echo ========================================
echo Fixing Gradle Build Issues
echo ========================================
echo.

REM Step 1: Kill any running Gradle daemons
echo [1/5] Stopping Gradle daemons...
cd /d "%~dp0android"
call gradlew --stop 2>nul
cd /d "%~dp0"
echo Done.
echo.

REM Step 2: Clean Flutter
echo [2/5] Running Flutter clean...
call flutter clean
echo Done.
echo.

REM Step 3: Get dependencies
echo [3/5] Getting Flutter dependencies...
call flutter pub get
echo Done.
echo.

REM Step 4: Clean Android build
echo [4/5] Cleaning Android build...
cd /d "%~dp0android"
if exist build rd /s /q build
if exist app\build rd /s /q app\build
if exist .gradle rd /s /q .gradle
cd /d "%~dp0"
echo Done.
echo.

REM Step 5: Build with Gradle
echo [5/5] Building app (this will take 3-5 minutes)...
call flutter run
echo.
echo ========================================
echo Build complete!
echo ========================================
pause
