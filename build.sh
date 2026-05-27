#!/bin/bash
set -e

echo "========================================"
echo "  OpenChess Arena - APK Build Script"
echo "========================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check prerequisites
check_prereqs() {
    echo -e "\n${YELLOW}[1/5] Checking prerequisites...${NC}"

    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}Flutter SDK not found. Installing...${NC}"
        cd /tmp
        wget -q --show-progress https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.2-stable.tar.xz
        tar xf flutter_linux_3.22.2-stable.tar.xz
        export PATH="$PATH:/tmp/flutter/bin"
        echo 'export PATH="$PATH:/tmp/flutter/bin"' >> ~/.bashrc
        echo -e "${GREEN}Flutter installed!${NC}"
    else
        echo -e "${GREEN}Flutter $(flutter --version | head -1)${NC}"
    fi

    if ! command -v java &> /dev/null; then
        echo -e "${RED}Java not found. Install Java 17+:${NC}"
        echo "sudo apt install openjdk-17-jdk"
        exit 1
    fi
    echo -e "${GREEN}Java $(java -version 2>&1 | head -1)${NC}"

    if [ -z "$ANDROID_HOME" ]; then
        echo -e "${YELLOW}ANDROID_HOME not set. Setting to default...${NC}"
        export ANDROID_HOME=~/Android/Sdk
        mkdir -p $ANDROID_HOME
    fi
    echo -e "${GREEN}ANDROID_HOME=$ANDROID_HOME${NC}"
}

setup_android_sdk() {
    echo -e "\n${YELLOW}[2/5] Setting up Android SDK...${NC}"

    if [ ! -f "$ANDROID_HOME/platforms/android-34/android.jar" ]; then
        echo "Installing Android SDK platforms..."
        yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platforms;android-34" "build-tools;34.0.0" 2>/dev/null || {
            echo "Downloading command line tools..."
            cd /tmp
            wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
            unzip -q commandlinetools-linux-*.zip
            mkdir -p $ANDROID_HOME/cmdline-tools
            mv cmdline-tools $ANDROID_HOME/cmdline-tools/latest
            yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platforms;android-34" "build-tools;34.0.0"
        }
        echo -e "${GREEN}Android SDK installed!${NC}"
    else
        echo -e "${GREEN}Android SDK already configured${NC}"
    fi
}

install_deps() {
    echo -e "\n${YELLOW}[3/5] Installing dependencies...${NC}"

    cd "$(dirname "$0")/flutter_app"

    echo "Running flutter pub get..."
    flutter pub get

    cd ../backend
    echo "Installing backend npm packages..."
    npm install

    echo -e "${GREEN}Dependencies installed!${NC}"
}

prepare_build() {
    echo -e "\n${YELLOW}[4/5] Preparing build...${NC}"

    cd "$(dirname "$0")/flutter_app"

    echo "Creating Android local properties..."
    echo "sdk.dir=$ANDROID_HOME" > android/local.properties
    echo "flutter.sdk=$(which flutter | sed 's|/bin/flutter||')" >> android/local.properties

    if [ ! -f "android/app/google-services.json" ]; then
        echo -e "${YELLOW}WARNING: google-services.json not found!${NC}"
        echo -e "${YELLOW}Create a Firebase project and download the config file.${NC}"
        echo -e "${YELLOW}Place it at: flutter_app/android/app/google-services.json${NC}"
        echo "Creating placeholder config for development..."
        cat > android/app/google-services.json << 'EOF'
{
  "project_info": {
    "project_number": "000000000000",
    "project_id": "openchess-arena",
    "storage_bucket": "openchess-arena.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:000000000000:android:0000000000000000",
        "android_client_info": {
          "package_name": "com.openchess.arena"
        }
      },
      "api_key": [{ "current_key": "YOUR_API_KEY" }]
    }
  ]
}
EOF
    fi

    flutter clean
    echo -e "${GREEN}Build prepared!${NC}"
}

build_apk() {
    echo -e "\n${YELLOW}[5/5] Building APK...${NC}"

    cd "$(dirname "$0")/flutter_app"

    echo "Building release APK (this may take 5-10 minutes)..."
    flutter build apk --release --split-per-abi

    echo -e "\n${GREEN}========================================"
    echo "  BUILD COMPLETE!"
    echo "========================================"
    echo -e "${NC}"
    echo "APK files:"
    ls -lh build/app/outputs/flutter-apk/*.apk 2>/dev/null || echo "Check build/app/outputs/flutter-apk/"

    echo -e "\n${YELLOW}Install on device:${NC}"
    echo "flutter install"
}

# Main
cd "$(dirname "$0")"
check_prereqs
setup_android_sdk
install_deps
prepare_build
build_apk

echo -e "\n${GREEN}Done!${NC}"
