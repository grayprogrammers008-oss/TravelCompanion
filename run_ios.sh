#!/bin/bash

# Run iOS app with proper UTF-8 encoding
# This fixes CocoaPods encoding issues

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

echo "🚀 Starting Travel Crew iOS app..."
echo "✅ UTF-8 encoding set"
echo ""

flutter run
