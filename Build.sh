#!/bin/bash

MODULES_DIR="Modules"
BUILD_DIR="Build"

# Check if megumi.sh exists and load configuration
if [ -f "megumi.sh" ]; then
    source megumi.sh
fi

mkdir -p "$BUILD_DIR"

welcome() {
    clear
    echo "---------------------------------"
    echo "      Yamada Module Builder      "
    echo "---------------------------------"
    echo ""
}

success() {
    echo "---------------------------------"
    echo "    Build Process Completed      "
    printf "     Ambatukam : %s seconds\n" "$SECONDS"
    echo "---------------------------------"
}

# Function to flash module directly via ADB
flash_via_adb() {
    local zip_path="$1"
    local zip_name=$(basename "$zip_path")
    local remote_path="/data/local/tmp/$zip_name"
    local local_script="$BUILD_DIR/tmp_install.sh"
    local remote_script="/data/local/tmp/tmp_install.sh"

    echo ""
    echo "---------------------------------"
    echo "      Direct ADB Flashing        "
    echo "---------------------------------"

    # Check if adb is available
    if ! command -v adb >/dev/null 2>&1; then
        echo "❌ Error: 'adb' is not installed or not in PATH."
        return 1
    fi

    # Check if a device is connected
    local device_state=$(adb get-state 2>/dev/null)
    if [ "$device_state" != "device" ]; then
        echo "❌ Error: No device connected or device unauthorized."
        return 1
    fi

    # Check for Shell Root Access explicitly
    echo "🔎 Checking root access..."
    local root_check=$(adb shell su -c 'id -u' 2>/dev/null | tr -d '\r' | tr -d ' ')
    if [ "$root_check" != "0" ]; then
        echo "❌ Error: Please Grant \"Shell\" Root Access in Your Root Manager."
        return 1
    fi

    echo "📲 Pushing $zip_name to /data/local/tmp/..."
    if ! adb push "$zip_path" "$remote_path"; then
        echo "❌ Error: Failed to push file to device."
        return 1
    fi

    # 1. Create the installation script locally to avoid ADB multiline escaping issues
    cat << 'EOF' > "$local_script"
TARGET_ZIP="$1"

if command -v ksud >/dev/null 2>&1; then
    echo "✅ Detected: KernelSU Based"
    echo "📦 Installing module..."
    ksud module install "$TARGET_ZIP"
elif command -v magisk >/dev/null 2>&1; then
    echo "✅ Detected: Magisk Based"
    echo "📦 Installing module..."
    magisk module install "$TARGET_ZIP"
elif command -v apd >/dev/null 2>&1; then
    echo "✅ Detected: APatch"
    echo "📦 Installing module..."
    apd module install "$TARGET_ZIP"
else
    echo "❌ Error: No supported root manager found."
    rm -f "$TARGET_ZIP"
    exit 1
fi

echo "🧹 Cleaning up temporary files..."
rm -f "$TARGET_ZIP"
echo "✅ Flashing process completed on device!"
EOF

    # 2. Push the script to the device
    adb push "$local_script" "$remote_script" >/dev/null 2>&1

    echo "🔄 Flashing module via root manager..."
    # 3. Execute the script cleanly (no newlines to confuse su)
    adb shell su -c "sh '$remote_script' '$remote_path'"

    # 4. Clean up the script file on both ends
    adb shell rm -f "$remote_script"
    rm -f "$local_script"

    # Optional prompt to reboot the device
    echo ""
    read -p "Do you want to reboot the device now? (y/N): " REBOOT_DEV
    if [[ "${REBOOT_DEV,,}" == "y" || "${REBOOT_DEV,,}" == "yes" ]]; then
        echo "Rebooting device... 👋"
        adb reboot
    fi
    echo "---------------------------------"
}

# Function to prompt for ADB push and flash
prompt_adb_flash() {
    echo ""
    read -p "Flash directly to connected device via ADB? (y/N): " DO_ADB_FLASH
    DO_ADB_FLASH=${DO_ADB_FLASH,,}

    if [[ "$DO_ADB_FLASH" == "y" || "$DO_ADB_FLASH" == "yes" ]]; then
        return 0
    else
        return 1
    fi
}

build_modules() {
    rm -rf "$BUILD_DIR"/*

    VERSION="3.0"
    BUILD_TYPE="LAB"

    cd "$MODULES_DIR" || exit 1
    MODULE_ID=$(grep "^id=" "module.prop" | cut -d'=' -f2 | tr -d '[:space:]')
    ORIGINAL_NAME=$(grep "^name=" "module.prop" | cut -d'=' -f2 | tr -d '\r')

    # Update Version natively
    if [ -f "module.prop" ]; then
        cp "module.prop" "module.prop.tmp"
        sed "s/^version=.*$/version=$VERSION/" "module.prop.tmp" > "module.prop"
        rm "module.prop.tmp"
    fi

    if [ -f "customize.sh" ]; then
        cp "customize.sh" "customize.sh.tmp"
        sed "s/^ui_print \"Version : .*$/ui_print \"Version : $VERSION\"/" "customize.sh.tmp" > "customize.sh"
        rm "customize.sh.tmp"
    fi

    # --- 1. BUILD NORMAL ZIP ---
    ZIP_NAME="${MODULE_ID}-${VERSION}-${BUILD_TYPE}.zip"
    ZIP_PATH="../$BUILD_DIR/$ZIP_NAME"
    zip -q -r "$ZIP_PATH" ./*
    echo "Created: $ZIP_NAME"

    # --- 2. BUILD ENHANCED ZIP ---
    # Update module.prop for ENHANCED
    if [ -f "module.prop" ]; then
        cp "module.prop" "module.prop.tmp"
        sed "s/^name=.*$/name=${ORIGINAL_NAME} [ENHANCED]/" "module.prop.tmp" > "module.prop"
        rm "module.prop.tmp"
    fi

    # Append to system.prop for ENHANCED
    if [ -f "system.prop" ]; then
        # Backup outside the module directory so it doesn't get zipped
        cp "system.prop" "../$BUILD_DIR/system.prop.original"
        
        # Add the properties with a leading empty line
        cat << 'EOF' >> "system.prop"

###################
# ADO ENHANCED START
###################

af.resampler.quality=4
ro.af.client_heap_size_kbyte=10240
vendor.audio.offload.buffer.size.kb=1024
audio.offload.multiple.enabled=true
vendor.audio.offload.passthrough=true
ro.audio.ignore_effects=true
ro.audio.samplerate=192000
ro.vendor.audio.sdk.fluencetype=fluencepro
persist.vendor.audio.hw.binder.size_kbyte=1024
vendor.audio.hal.output.suspend.supported=false
EOF
    fi

    # Append to OdoruPonpokorin.sh for ENHANCED
    if [ -f "AdoKang/OdoruPonpokorin.sh" ]; then
        cp "AdoKang/OdoruPonpokorin.sh" "../$BUILD_DIR/OdoruPonpokorin.sh.original"
        
        cat << 'EOF' >> "AdoKang/OdoruPonpokorin.sh"

# ENHANCED: Override media processing and aggressive debug disabling
setprop debug.audio.hal 0
setprop debug.audio.policy 0
for pid in $(pidof audioserver); do
    ionice -c 1 -n 0 -p $pid
done
EOF
    fi

    ZIP_NAME_ENHANCED="${MODULE_ID}-${VERSION}-${BUILD_TYPE}-ENHANCED.zip"
    ZIP_PATH_ENHANCED="../$BUILD_DIR/$ZIP_NAME_ENHANCED"
    zip -q -r "$ZIP_PATH_ENHANCED" ./*
    echo "Created: $ZIP_NAME_ENHANCED"

    # --- CLEANUP ---
    # Restore module.prop back to normal
    if [ -f "module.prop" ]; then
        cp "module.prop" "module.prop.tmp"
        sed "s/^name=.*$/name=${ORIGINAL_NAME}/" "module.prop.tmp" > "module.prop"
        rm "module.prop.tmp"
    fi

    # Restore system.prop back to normal and delete the backup file
    if [ -f "../$BUILD_DIR/system.prop.original" ]; then
        mv "../$BUILD_DIR/system.prop.original" "system.prop"
    fi

    if [ -f "../$BUILD_DIR/OdoruPonpokorin.sh.original" ]; then
        mv "../$BUILD_DIR/OdoruPonpokorin.sh.original" "AdoKang/OdoruPonpokorin.sh"
    fi

    cd ..

    # --- ADB Flash Prompt ---
    if prompt_adb_flash; then
        echo ""
        echo "Which version do you want to flash?"
        echo "1) Normal ($ZIP_NAME)"
        echo "2) Enhanced ($ZIP_NAME_ENHANCED)"
        read -p "Select (1/2): " FLASH_SELECTION
        
        if [ "$FLASH_SELECTION" == "2" ]; then
            flash_via_adb "$BUILD_DIR/$ZIP_NAME_ENHANCED"
        else
            flash_via_adb "$BUILD_DIR/$ZIP_NAME"
        fi
    fi

}

welcome
SECONDS=0  # Start timing
build_modules
success