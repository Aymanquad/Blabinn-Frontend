#!/bin/bash

# Setup script for Chatify linting system
# This script installs and configures all linting tools and pre-commit hooks

set -e

echo "🚀 Setting up Chatify linting system..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Check if Dart is installed
if ! command -v dart &> /dev/null; then
    echo "❌ Dart is not installed. Please install Dart first."
    exit 1
fi

echo "✅ Flutter and Dart are installed"

# Install Flutter dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Install pre-commit if not already installed
if ! command -v pre-commit &> /dev/null; then
    echo "📦 Installing pre-commit..."
    pip install pre-commit
else
    echo "✅ pre-commit is already installed"
fi

# Install pre-commit hooks
echo "🔧 Installing pre-commit hooks..."
pre-commit install

# Install additional Flutter tools
echo "📦 Installing Flutter tools..."
flutter pub global activate dartdoc
flutter pub global activate coverage

# Create .gitignore entries for linting
echo "📝 Updating .gitignore..."
cat >> .gitignore << EOF

# Linting and analysis
.dart_tool/
build/
coverage/
doc/api/
.pre-commit-config.yaml.bak
.secrets.baseline
EOF

# Create secrets baseline for detect-secrets
echo "🔐 Creating secrets baseline..."
if [ ! -f .secrets.baseline ]; then
    echo "{}" > .secrets.baseline
fi

# Run initial analysis
echo "🔍 Running initial analysis..."
flutter analyze

# Run initial formatting
echo "🎨 Running initial formatting..."
flutter format .

# Run initial tests
echo "🧪 Running initial tests..."
flutter test

echo "✅ Linting system setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Run 'pre-commit run --all-files' to check all files"
echo "2. Run 'flutter analyze' to check for issues"
echo "3. Run 'flutter test' to run tests"
echo "4. Run 'flutter format .' to format code"
echo ""
echo "🔧 Available commands:"
echo "- 'pre-commit run --all-files': Run all pre-commit hooks"
echo "- 'pre-commit run <hook-name>': Run specific hook"
echo "- 'flutter analyze': Run static analysis"
echo "- 'flutter test': Run tests"
echo "- 'flutter format .': Format code"
echo ""
echo "📚 Documentation:"
echo "- CODE_REVIEW_STANDARDS.md: Code review guidelines"
echo "- LINTING_RULES.md: Linting rules documentation"
echo "- analysis_options.yaml: Static analysis configuration"
echo "- .pre-commit-config.yaml: Pre-commit hooks configuration"
echo ""
echo "🎉 Happy coding!"
