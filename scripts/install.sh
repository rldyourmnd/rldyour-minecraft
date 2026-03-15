#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"

cd "$SERVER_DIR"

# Load environment
if [[ -f .env ]]; then
    source .env
fi

FORGE_VERSION="${FORGE_VERSION:-1.12.2-14.23.5.2860}"
JAVA="${JAVA_PATH:-java}"

# Check Java version
echo "Checking Java version..."
JAVA_VER=$("$JAVA" -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1-2)
if [[ "$JAVA_VER" != "1.8" ]]; then
    echo "ERROR: Java 8 is required for Minecraft 1.12.2 Forge."
    echo "Detected: $JAVA_VER"
    echo "Set JAVA_PATH in .env to point to a Java 8 installation."
    exit 1
fi
echo "Java 8 detected. OK."

# Download Forge installer
INSTALLER="forge-${FORGE_VERSION}-installer.jar"
INSTALLER_URL="https://maven.minecraftforge.net/net/minecraftforge/forge/${FORGE_VERSION}/forge-${FORGE_VERSION}-installer.jar"

if [[ ! -f "$INSTALLER" ]]; then
    echo "Downloading Forge ${FORGE_VERSION} installer..."
    curl -L -o "$INSTALLER" "$INSTALLER_URL"
    echo "Download complete."
else
    echo "Forge installer already exists. Skipping download."
fi

# Install Forge server
echo "Installing Forge server..."
"$JAVA" -jar "$INSTALLER" --installServer
echo "Forge server installed."

# Clean up installer
rm -f "$INSTALLER" "${INSTALLER}.log"

# Accept EULA
echo "eula=true" > eula.txt
echo "EULA accepted."

# Create directories if missing
mkdir -p config mods backups

# Set up .env if not exists
if [[ ! -f .env ]]; then
    cp .env.example .env
    echo "Created .env from .env.example. Review and adjust settings."
fi

echo ""
echo "Installation complete!"
echo "  1. Place mods in the mods/ directory"
echo "  2. Review server.properties"
echo "  3. Adjust .env for RAM and Java settings"
echo "  4. Run: ./scripts/start.sh"
