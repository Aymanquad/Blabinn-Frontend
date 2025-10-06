#!/bin/bash

# Local Development Setup Script for Blabinn Frontend
# This script helps set up the local development environment

echo "🚀 Setting up Blabinn Frontend for Local Development"
echo "=================================================="

# Check if we're in the right directory
if [ ! -d "lib" ] || [ ! -f "pubspec.yaml" ]; then
    echo "❌ Please run this script from the Blabinn-Frontend root directory"
    exit 1
fi

# Install Flutter dependencies
echo "Installing Flutter dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
    echo "✓ Dependencies installed successfully"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

# Check Flutter setup
echo "Checking Flutter setup..."
flutter doctor

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Make sure your backend is running at http://127.0.0.1:8000"
echo "2. Update the IP address in lib/core/env_config.dart if needed"
echo "3. Run: flutter run"
echo ""
echo "Available commands:"
echo "  flutter run                    # Run on connected device/emulator"
echo "  flutter run -d chrome          # Run on web browser"
echo "  flutter run -d windows         # Run on Windows desktop"
echo "  flutter run -d macos           # Run on macOS desktop"
echo "  flutter run -d linux           # Run on Linux desktop"
echo ""
echo "To find your computer's IP address:"
echo "  Windows: ipconfig"
echo "  macOS/Linux: ifconfig"
