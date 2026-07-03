#!/bin/bash
set -e

echo "========================================================="
echo "   Deep SCI (Deep Spam Call Identified) iOS App Bootstrap"
echo "========================================================="

# Check for XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen not found. Attempting to install via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo "Error: Homebrew is not installed. Please install Homebrew or install XcodeGen manually."
        exit 1
    fi
else
    echo "✓ XcodeGen is already installed."
fi

# Create resource folders if they don't exist
mkdir -p DeepSCI/Assets.xcassets/AppIcon.appiconset
mkdir -p DeepSCIDirectory

# Generate project
echo "Generating Xcode project using xcodegen..."
xcodegen generate

echo "========================================================="
echo "✓ Setup Completed! Project files generated successfully."
echo "  You can now open: DeepSCI.xcodeproj"
echo "========================================================="
