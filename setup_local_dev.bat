@echo off
REM Local Development Setup Script for Blabinn Frontend
REM This script helps set up the local development environment

echo 🚀 Setting up Blabinn Frontend for Local Development
echo ==================================================

REM Check if we're in the right directory
if not exist "lib" (
    echo ❌ Please run this script from the Blabinn-Frontend root directory
    pause
    exit /b 1
)

if not exist "pubspec.yaml" (
    echo ❌ Please run this script from the Blabinn-Frontend root directory
    pause
    exit /b 1
)

REM Install Flutter dependencies
echo Installing Flutter dependencies...
flutter pub get

if %errorlevel% equ 0 (
    echo ✓ Dependencies installed successfully
) else (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

REM Check Flutter setup
echo Checking Flutter setup...
flutter doctor

echo.
echo ✅ Setup complete!
echo.
echo Next steps:
echo 1. Make sure your backend is running at http://127.0.0.1:8000
echo 2. Update the IP address in lib/core/env_config.dart if needed
echo 3. Run: flutter run
echo.
echo Available commands:
echo   flutter run                    # Run on connected device/emulator
echo   flutter run -d chrome          # Run on web browser
echo   flutter run -d windows         # Run on Windows desktop
echo.
echo To find your computer's IP address:
echo   Windows: ipconfig
echo.
pause
