@echo off
REM Setup script for Chatify linting system (Windows)
REM This script installs and configures all linting tools and pre-commit hooks

echo 🚀 Setting up Chatify linting system...

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed. Please install Flutter first.
    exit /b 1
)

REM Check if Dart is installed
dart --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Dart is not installed. Please install Dart first.
    exit /b 1
)

echo ✅ Flutter and Dart are installed

REM Install Flutter dependencies
echo 📦 Installing Flutter dependencies...
flutter pub get

REM Install pre-commit if not already installed
python -m pip show pre-commit >nul 2>&1
if %errorlevel% neq 0 (
    echo 📦 Installing pre-commit...
    python -m pip install pre-commit
) else (
    echo ✅ pre-commit is already installed
)

REM Install pre-commit hooks
echo 🔧 Installing pre-commit hooks...
pre-commit install

REM Install additional Flutter tools
echo 📦 Installing Flutter tools...
flutter pub global activate dartdoc
flutter pub global activate coverage

REM Create .gitignore entries for linting
echo 📝 Updating .gitignore...
echo. >> .gitignore
echo # Linting and analysis >> .gitignore
echo .dart_tool/ >> .gitignore
echo build/ >> .gitignore
echo coverage/ >> .gitignore
echo doc/api/ >> .gitignore
echo .pre-commit-config.yaml.bak >> .gitignore
echo .secrets.baseline >> .gitignore

REM Create secrets baseline for detect-secrets
echo 🔐 Creating secrets baseline...
if not exist .secrets.baseline (
    echo {} > .secrets.baseline
)

REM Run initial analysis
echo 🔍 Running initial analysis...
flutter analyze

REM Run initial formatting
echo 🎨 Running initial formatting...
flutter format .

REM Run initial tests
echo 🧪 Running initial tests...
flutter test

echo ✅ Linting system setup complete!
echo.
echo 📋 Next steps:
echo 1. Run 'pre-commit run --all-files' to check all files
echo 2. Run 'flutter analyze' to check for issues
echo 3. Run 'flutter test' to run tests
echo 4. Run 'flutter format .' to format code
echo.
echo 🔧 Available commands:
echo - 'pre-commit run --all-files': Run all pre-commit hooks
echo - 'pre-commit run ^<hook-name^>': Run specific hook
echo - 'flutter analyze': Run static analysis
echo - 'flutter test': Run tests
echo - 'flutter format .': Format code
echo.
echo 📚 Documentation:
echo - CODE_REVIEW_STANDARDS.md: Code review guidelines
echo - LINTING_RULES.md: Linting rules documentation
echo - analysis_options.yaml: Static analysis configuration
echo - .pre-commit-config.yaml: Pre-commit hooks configuration
echo.
echo 🎉 Happy coding!
pause
