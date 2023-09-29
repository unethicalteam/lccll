#!/bin/bash

download_file() {
    local url="$1"
    local output_dir="$2"
    local filename="$(basename "$url")"
    curl -s -o "$output_dir/$filename" "$url"
}

GRAAL_SETUP_FILE="$HOME/.graallcsetup.txt"
JAVA_URL="https://download.oracle.com/java/17/latest/jdk-17_macos-aarch64_bin.tar.gz"
JAVA_INSTALL_DIR="$HOME/jdk-17.0.8.jdk/Contents/Home"
LUNAR_OFFLINE_DIR="$HOME/.lunarclient/offline/multiver"
HOSTS_FILE="/etc/hosts"

#  Block Lunar's Websocket
block_lunar_websocket() {
    local LUNAR_BLOCKER="127.0.0.1 websocket.lunarclientprod.com"

    read -p "Do you want to block Lunar's Websocket? (y/n): " block_choice

    if [[ $block_choice == "y" || $block_choice == "Y" ]]; then
        local password=$(get_password)
        echo "$password" | sudo -S echo "Password entered." # Test sudo access
        echo "$LUNAR_BLOCKER" | sudo tee -a "$HOSTS_FILE"
        echo "Lunar's Websocket blocked."
        return 0 # Return success
    else
        echo "Lunar's Websocket is not blocked."
        return 1 # Return failure
    fi
}

# Unblock Lunar's Websocket
unblock_lunar_websocket() {
    echo "$password" | sudo tee "$HOSTS_FILE" >/dev/null <<-EOF
    $(grep -v "$LUNAR_BLOCKER" "$HOSTS_FILE")
EOF
    echo "Lunar's Websocket unblocked."
}

# Prompt for password using AppleScript
get_password() {
    osascript -e 'text returned of (display dialog "Enter your password:" default answer "" with hidden answer buttons {"OK"} default button "OK")'
}

# Check if JDK is already installed
if [ -f "$GRAAL_SETUP_FILE" ]; then
    echo "JRE is already installed, skipping installation"
else
    echo "Downloading and installing JDK 17"
    download_file "$JAVA_URL" "$HOME"
    tar -xzf "$HOME/$(basename "$JAVA_URL")" -C "$HOME"
    mv "$HOME/jdk-17" "$JAVA_INSTALL_DIR"
    echo "JRE is installed" > "$GRAAL_SETUP_FILE"
fi

websocket_blocked=0
block_lunar_websocket || websocket_blocked=1

echo Running Lunar Client...

LAUNCHER_VERSION=$(curl -s https://launcherupdates.lunarclientcdn.com/latest.yml | grep -o 'version: [^ ]*' | awk '{print $2}')
LUNAR_CLASSPATH=lunar-lang.jar:lunar-emote.jar:lunar.jar:optifine-0.1.0-SNAPSHOT-all.jar:v1_8-0.1.0-SNAPSHOT-all.jar:common-0.1.0-SNAPSHOT-all.jar:genesis-0.1.0-SNAPSHOT-all.jar
LUNAR_MAIN_CLASS=com.moonsworth.lunar.genesis.Genesis
LUNAR_JVM_ARGS="--add-modules jdk.naming.dns --add-exports jdk.naming.dns/com.sun.jndi.dns=java.naming -Djna.boot.library.path=natives -Dlog4j2.formatMsgNoLookups=true --add-opens java.base/java.io=ALL-UNNAMED -Djava.library.path=natives -Dlog4j2.formatMsgNoLookups=true -Xmx3G -Xms3G -Xmn1G -XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+AlwaysActAsServerClassMachine -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+UseNUMA -XX:AllocatePrefetchStyle=3 -XX:NmethodSweepActivity=1 -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M -XX:NonProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:+PerfDisableSharedMem -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority -XX:+EagerJVMCI -XX:+UseG1GC -XX:MaxGCPauseMillis=37 -XX:+PerfDisableSharedMem -XX:G1HeapRegionSize=16M -XX:G1NewSizePercent=23 -XX:G1ReservePercent=20 -XX:SurvivorRatio=32 -XX:G1MixedGCCountTarget=3 -XX:G1HeapWastePercent=20 -XX:InitiatingHeapOccupancyPercent=10 -XX:G1RSetUpdatingPauseTimePercent=0 -XX:MaxTenuringThreshold=1 -XX:G1SATBBufferEnqueueingThresholdPercent=30 -XX:G1ConcMarkStepDurationMillis=5.0 -XX:G1ConcRSHotCardLimit=16 -XX:G1ConcRefinementServiceIntervalMillis=150 -XX:GCTimeRatio=99"

cd "$LUNAR_OFFLINE_DIR"

"$JAVA_INSTALL_DIR/bin/java" \
    $LUNAR_JVM_ARGS \
    -cp "$LUNAR_CLASSPATH" \
    $LUNAR_MAIN_CLASS \
    --version 1.8.9 \
    --accessToken 0 \
    --assetIndex 1.8 \
    --userProperties {} \
    --gameDir "$HOME/.minecraft" \
    --texturesDir "$HOME/.lunarclient/textures" \
    --width 1280 \
    --height 720 \
    --workingDirectory . \
    --classpathDir . \
    --ichorClassPath "lunar-lang.jar,lunar-emote.jar,lunar.jar,optifine-0.1.0-SNAPSHOT-all.jar,v1_8-0.1.0-SNAPSHOT-all.jar,common-0.1.0-SNAPSHOT-all.jar,genesis-0.1.0-SNAPSHOT-all.jar" \
    --ichorExternalFiles OptiFine_v1_8.jar \
    --installationId 0 \
    --hwid 0 \
    --launcherVersion $LAUNCHER_VERSION

if [ $websocket_blocked -eq 0 ]; then
    unblock_lunar_websocket
fi
