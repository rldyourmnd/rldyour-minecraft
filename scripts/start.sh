#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"

cd "$SERVER_DIR"

# Load environment
if [[ ! -f .env ]]; then
    echo "ERROR: .env not found. Run scripts/install.sh first."
    exit 1
fi
source .env

MIN_RAM="${MIN_RAM:-4G}"
MAX_RAM="${MAX_RAM:-4G}"
JAVA="${JAVA_PATH:-java}"
SERVER_JAR="${SERVER_JAR:-forge-1.12.2-14.23.5.2860.jar}"

# Check server JAR exists
if [[ ! -f "$SERVER_JAR" ]]; then
    echo "ERROR: $SERVER_JAR not found. Run scripts/install.sh first."
    exit 1
fi

# Check Java version
JAVA_VER=$("$JAVA" -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1-2)
if [[ "$JAVA_VER" != "1.8" ]]; then
    echo "WARNING: Java 8 is recommended for 1.12.2 Forge. Detected: $JAVA_VER"
fi

echo "Starting rldyourmcrft server..."
echo "  RAM: ${MIN_RAM} - ${MAX_RAM}"
echo "  JAR: ${SERVER_JAR}"
echo ""

# Aikar's optimized JVM flags for Minecraft servers
exec "$JAVA" \
    -Xms${MIN_RAM} \
    -Xmx${MAX_RAM} \
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:MaxGCPauseMillis=200 \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+DisableExplicitGC \
    -XX:+AlwaysPreTouch \
    -XX:G1NewSizePercent=30 \
    -XX:G1MaxNewSizePercent=40 \
    -XX:G1HeapRegionSize=8M \
    -XX:G1ReservePercent=20 \
    -XX:G1HeapWastePercent=5 \
    -XX:G1MixedGCCountTarget=4 \
    -XX:InitiatingHeapOccupancyPercent=15 \
    -XX:G1MixedGCLiveThresholdPercent=90 \
    -XX:G1RSetUpdatingPauseTimePercent=5 \
    -XX:SurvivorRatio=32 \
    -XX:+PerfDisableSharedMem \
    -XX:MaxTenuringThreshold=1 \
    -Dusing.aikars.flags=https://mcflags.emc.gs \
    -Dfml.queryResult=confirm \
    -jar "$SERVER_JAR" \
    nogui
