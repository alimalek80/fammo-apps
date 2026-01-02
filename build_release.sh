#!/bin/bash

# FAMMO - Play Store Release Build Script
# This script builds the app bundle for Play Store submission

set -e

echo "🚀 FAMMO Play Store Release Build"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if key.properties exists
if [ ! -f "android/key.properties" ]; then
    echo -e "${RED}❌ Error: android/key.properties not found!${NC}"
    echo "Please create android/key.properties from android/key.properties.example"
    exit 1
fi

echo -e "${GREEN}✓ Key properties found${NC}"

# Clean previous builds
echo ""
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo ""
echo "📦 Getting dependencies..."
flutter pub get

# Run build
echo ""
echo "🔨 Building release app bundle..."
flutter build appbundle --release

# Check if build was successful
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    echo ""
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo ""
    echo "📁 App Bundle location:"
    echo "   build/app/outputs/bundle/release/app-release.aab"
    echo ""
    echo "📊 Bundle size:"
    ls -lh build/app/outputs/bundle/release/app-release.aab
    echo ""
    echo -e "${YELLOW}📝 Next steps:${NC}"
    echo "   1. Go to Google Play Console: https://play.google.com/console"
    echo "   2. Select your app or create a new one"
    echo "   3. Go to Release > Production > Create new release"
    echo "   4. Upload the .aab file"
    echo "   5. Add release notes from: android/fastlane/metadata/android/en-US/changelogs/1.txt"
    echo "   6. Review and roll out"
else
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi
