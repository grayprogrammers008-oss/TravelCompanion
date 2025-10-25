#!/bin/bash

# =====================================================
# REALTIME TESTING SCRIPT
# Easily test real-time sync on your laptop
# =====================================================

set -e

echo "🧪 Travel Companion - Realtime Testing Script"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found${NC}"
echo ""

# Show available devices
echo -e "${BLUE}📱 Available devices:${NC}"
flutter devices --machine | python3 -m json.tool 2>/dev/null || flutter devices
echo ""

# Ask user to select test mode
echo "Select testing mode:"
echo "1) Two iOS Simulators (requires Mac)"
echo "2) iOS Simulator + Chrome (easiest)"
echo "3) Show me the commands (I'll run manually)"
echo "4) Just run on one device first"
echo ""
read -p "Enter choice [1-4]: " choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}🚀 Starting TWO iOS Simulators...${NC}"
        echo ""

        # List available iOS simulators
        echo "Available iOS Simulators:"
        xcrun simctl list devices available | grep -i iphone || true
        echo ""

        read -p "Enter FIRST simulator name (e.g., 'iPhone 15 Pro'): " sim1
        read -p "Enter SECOND simulator name (e.g., 'iPhone 15'): " sim2

        echo ""
        echo -e "${BLUE}📱 Booting simulators...${NC}"
        xcrun simctl boot "$sim1" 2>/dev/null || echo "  $sim1 already booted"
        xcrun simctl boot "$sim2" 2>/dev/null || echo "  $sim2 already booted"

        echo ""
        echo -e "${GREEN}✅ Simulators ready!${NC}"
        echo ""
        echo -e "${YELLOW}Opening 2 terminal windows...${NC}"
        echo ""

        # Open first terminal
        osascript -e "tell app \"Terminal\" to do script \"cd '$PWD' && flutter run -d '$sim1'\""

        sleep 2

        # Open second terminal
        osascript -e "tell app \"Terminal\" to do script \"cd '$PWD' && flutter run -d '$sim2'\""

        echo -e "${GREEN}✅ Launched! Check the new terminal windows.${NC}"
        ;;

    2)
        echo ""
        echo -e "${YELLOW}🚀 Starting iOS Simulator + Chrome...${NC}"
        echo ""

        echo "Available iOS Simulators:"
        xcrun simctl list devices available | grep -i iphone || true
        echo ""

        read -p "Enter simulator name (e.g., 'iPhone 15 Pro'): " sim1

        echo ""
        echo -e "${BLUE}📱 Booting simulator...${NC}"
        xcrun simctl boot "$sim1" 2>/dev/null || echo "  $sim1 already booted"

        echo ""
        echo -e "${YELLOW}Opening 2 terminal windows...${NC}"
        echo ""

        # Open first terminal - iOS
        osascript -e "tell app \"Terminal\" to do script \"cd '$PWD' && flutter run -d '$sim1'\""

        sleep 2

        # Open second terminal - Chrome
        osascript -e "tell app \"Terminal\" to do script \"cd '$PWD' && flutter run -d chrome\""

        echo -e "${GREEN}✅ Launched! Check the new terminal windows.${NC}"
        ;;

    3)
        echo ""
        echo -e "${BLUE}📋 Manual Commands:${NC}"
        echo ""
        echo "Terminal 1 (iOS):"
        echo -e "${YELLOW}  cd $PWD${NC}"
        echo -e "${YELLOW}  flutter run -d 'iPhone 15 Pro'${NC}"
        echo ""
        echo "Terminal 2 (Chrome or another device):"
        echo -e "${YELLOW}  cd $PWD${NC}"
        echo -e "${YELLOW}  flutter run -d chrome${NC}"
        echo ""
        echo "Or list all devices with:"
        echo -e "${YELLOW}  flutter devices${NC}"
        ;;

    4)
        echo ""
        echo -e "${YELLOW}🚀 Starting on default device...${NC}"
        echo ""
        flutter run
        ;;

    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}📖 Testing Steps:${NC}"
echo "1. Wait for both apps to load"
echo "2. Login on both devices (can use same account or different accounts)"
echo "3. On Device B: Create a new trip"
echo "4. On Device A: Watch for the trip to appear instantly!"
echo ""
echo -e "${GREEN}Look for these console messages:${NC}"
echo "  📡 Creating NEW subscription..."
echo "  ✅ Successfully subscribed to..."
echo "  🔄 Trip change detected..."
echo ""
echo -e "${YELLOW}If you DON'T see these messages, Realtime is not enabled in Supabase!${NC}"
echo "Run: scripts/database/enable_realtime.sql in your Supabase SQL Editor"
echo ""
