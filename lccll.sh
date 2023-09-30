#!/bin/bash
CONFIG_FILE="$HOME/.llcconfig.txt"
HWID_FILE="$HOME/.lunarclient/launcher-cache/hwid-private-do-not-share"
HOSTS_FILE="/etc/hosts"
LUNAR_WEBSOCKET="127.0.0.1 websocket.lunarclient.com"

if [ ! -e "$CONFIG_FILE" ]; then
    echo "LUNAR_WIDTH=1280" >> "$CONFIG_FILE"
    echo "LUNAR_HEIGHT=720" >> "$CONFIG_FILE"
    echo "JRE_INSTALLED=false" >> "$CONFIG_FILE"
    echo "WEBSOCKET=0" >> "$CONFIG_FILE"
fi

while IFS='=' read -r key value; do
    case "$key" in
        "LUNAR_WIDTH")
            LUNAR_WIDTH="$value"
            ;;
        "LUNAR_HEIGHT")
            LUNAR_HEIGHT="$value"
            ;;
        "JRE_INSTALLED")
            JRE_INSTALLED="$value"
            ;;
        "WEBSOCKET")
            WEBSOCKET="$value"
            ;;
    esac
done < "$CONFIG_FILE"

# function to download files
download_file() {
    local url="$1"
    local output_dir="$2"
    local filename="$(basename "$url")"
    curl -s -o "$output_dir/$filename" "$url"
}

# function to prompt for password using AppleScript
get_password() {
    osascript -e 'text returned of (display dialog "Enter your password:" default answer "" with hidden answer buttons {"OK"} default button "OK")'
}

password=$(get_password)

# function to unblock lunars websocket
unblock_lunar_websocket() {
    echo "$password" | sudo tee "$HOSTS_FILE" >/dev/null <<-EOF
    $(grep -v "$LUNAR_WEBSOCKET" "$HOSTS_FILE")
EOF
    echo "Lunar's Websocket unblocked."
}

menu() {
    clear 
    echo "lccll - lunar client command line launcher"
    echo "Created by unethical"
    echo "https://discord.gg/vhJ8Dsp9qa"
    echo
    echo "1) Block HWID: $(if [ "$HWID" == "0" ]; then echo "Enabled"; else echo "Disabled"; fi)"
    echo "2) Block Websocket: $(if [ "$WEBSOCKET" == "1" ]; then echo "Enabled"; else echo "Disabled"; fi)"
    echo "3) Set Window Size (Current: $LUNAR_WIDTH x $LUNAR_HEIGHT)"
    echo "4) Download GraalVM (Installed: $JRE_INSTALLED)"
    echo "5) Run Lunar Client"
    echo "6) Exit"
    echo
    read -p "Enter the corresponding number and press Enter: " input
}

LAUNCHER_VERSION=$(curl -s https://launcherupdates.lunarclientcdn.com/latest.yml | grep -o 'version: [^ ]*' | awk '{print $2}')

# Main Menu Loop
while true; do
    menu

    case "$input" in
        "1")
            # Block/Unblock HWID
            if [ "$HWID" == "0" ]; then
                if [ -f "$HWID_FILE" ]; then
                    read -r HWID < "$HWID_FILE"
                else
                    echo "HWID not found. HWID will remain blocked."
                fi
            else
                HWID="0"
            fi
            ;;

        "2")
            # Block/Unblock Websocket
            if [ "$WEBSOCKET" == "0" ]; then
                echo "$password" | sudo -S echo "Password entered." # Test sudo access
                echo "$LUNAR_WEBSOCKET" | sudo tee -a "$HOSTS_FILE"
                echo "Lunar's Websocket blocked."
                echo "WEBSOCKET=1" > "$CONFIG_FILE" # Update the configuration file
                WEBSOCKET="1"
            else
                unblock_lunar_websocket
                echo "WEBSOCKET=0" > "$CONFIG_FILE" # Update the configuration file
                WEBSOCKET="0"
            fi
            ;;

        "3")
            # Set Window Size
            clear
            read -p "LUNAR_WIDTH=Window width (e.g., 1920): " LUNAR_WIDTH
            read -p "LUNAR_HEIGHT=Window height (e.g., 1080): " LUNAR_HEIGHT
            echo "LUNAR_WIDTH=$LUNAR_WIDTH" > "$CONFIG_FILE"
            echo "LUNAR_HEIGHT=$LUNAR_HEIGHT" >> "$CONFIG_FILE"
            ;;

        "4")
            # Download and install GraalVM
            if [ -d "$JAVA_INSTALL_DIR" ] || [ "$JRE_INSTALLED" == "true" ]; then
                echo "JRE_INSTALLED=true" >> "$CONFIG_FILE"
                echo "JRE is already installed."
            else
                JAVA_URL="https://download.oracle.com/java/17/latest/jdk-17_macos-aarch64_bin.tar.gz"
                JAVA_INSTALL_DIR="$HOME/jdk-17.0.8.jdk/Contents/Home/bin/java"
                echo "Downloading and installing JDK 17"
                download_file "$JAVA_URL" "$HOME"
                tar -xzf "$HOME/$(basename "$JAVA_URL")" -C "$HOME"
                mv "$HOME/jdk-17" "$JAVA_INSTALL_DIR"
                echo "JRE_INSTALLED=true" >> "$CONFIG_FILE"
            fi
            ;;

        "5")
            # Run Lunar Client
            clear
            echo "Running Lunar Client.."

            if [ -d "$JAVA_INSTALL_DIR" ] || [ "$JRE_INSTALLED" == "true" ]; then
                LUNAR_JRE="$JAVA_INSTALL_DIR"
            else
                LUNAR_JRE="$HOME/.lunarclient/jre/558a15eabb214bf8845d7f0993a02d9cc101324f/zulu17.34.19-ca-jre17.0.3-macosx_aarch64/zulu-17.jre/Contents/Home/bin/java"
            fi

            LUNAR_JVM_ARGS="--add-modules jdk.naming.dns --add-exports jdk.naming.dns/com.sun.jndi.dns=java.naming -Djna.boot.library.path=natives -Dlog4j2.formatMsgNoLookups=true --add-opens java.base/java.io=ALL-UNNAMED -Djava.library.path=natives -Dlog4j2.formatMsgNoLookups=true -Xmx3G -Xms3G -Xmn1G -XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+AlwaysActAsServerClassMachine -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+UseNUMA -XX:AllocatePrefetchStyle=3 -XX:NmethodSweepActivity=1 -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M -XX:NonProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:+PerfDisableSharedMem -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority -XX:+EagerJVMCI -XX:+UseG1GC -XX:MaxGCPauseMillis=37 -XX:+PerfDisableSharedMem -XX:G1HeapRegionSize=16M -XX:G1NewSizePercent=23 -XX:G1ReservePercent=20 -XX:SurvivorRatio=32 -XX:G1MixedGCCountTarget=3 -XX:G1HeapWastePercent=20 -XX:InitiatingHeapOccupancyPercent=10 -XX:G1RSetUpdatingPauseTimePercent=0 -XX:MaxTenuringThreshold=1 -XX:G1SATBBufferEnqueueingThresholdPercent=30 -XX:G1ConcMarkStepDurationMillis=5.0 -XX:G1ConcRSHotCardLimit=16 -XX:G1ConcRefinementServiceIntervalMillis=150 -XX:GCTimeRatio=99"
            LUNAR_CLASSPATH="lunar-lang.jar:lunar-emote.jar:lunar.jar:optifine-0.1.0-SNAPSHOT-all.jar:v1_8-0.1.0-SNAPSHOT-all.jar:common-0.1.0-SNAPSHOT-all.jar:genesis-0.1.0-SNAPSHOT-all.jar"
            LUNAR_MAIN_CLASS="com.moonsworth.lunar.genesis.Genesis"
            ICHOR_EXT_FILE="OptiFine_v1_8.jar"

            cd "$HOME/.lunarclient/offline/multiver"

            "$LUNAR_JRE" \
                $LUNAR_JVM_ARGS \
                -cp "$LUNAR_CLASSPATH" \
                $LUNAR_MAIN_CLASS \
                --version 1.8.9 \
                --accessToken 0 \
                --assetIndex 1.8 \
                --userProperties {} \
                --gameDir "$HOME/.minecraft" \
                --texturesDir "$HOME/.lunarclient/textures" \
                --width $LUNAR_WIDTH \
                --height $LUNAR_HEIGHT \
                --workingDirectory . \
                --classpathDir . \
                --ichorClassPath "lunar-lang.jar,lunar-emote.jar,lunar.jar,optifine-0.1.0-SNAPSHOT-all.jar,v1_8-0.1.0-SNAPSHOT-all.jar,common-0.1.0-SNAPSHOT-all.jar,genesis-0.1.0-SNAPSHOT-all.jar" \
                --ichorExternalFiles OptiFine_v1_8.jar \
                --installationId 0 \
                --hwid $HWID \
                --launcherVersion $LAUNCHER_VERSION
            
            # Unblock WebSocket if necessary
            if [ $WEBSOCKET -eq 0 ]; then
                unblock_lunar_websocket
            fi

            read -p "Press Enter to continue..."
            ;;

        "6")
            # Exit
            exit 0
            ;;
        
        *)
            echo "Invalid choice."
            read -p "Press Enter to continue..."
            ;;
    esac
done
