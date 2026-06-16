#!/bin/bash

MODULES_DIR="Modules"
BUILD_DIR="Build"

# Check if megumi.sh exists and load configuration
TELEGRAM_ENABLED=false
if [ -f "megumi.sh" ]; then
    source megumi.sh
    TELEGRAM_ENABLED=true
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

# Function to send file to Telegram
send_to_telegram() {
    local file_path="$1"
    local caption="$2"
    local chat_id="$3"

    if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
        echo "Error: TELEGRAM_BOT_TOKEN is not set in megumi.sh!"
        return 1
    fi

    if [ -z "$chat_id" ]; then
        echo "Error: Chat ID is empty!"
        return 1
    fi

    echo "Uploading $(basename "$file_path") to chat ID: $chat_id..."

    # Send document to Telegram
    response=$(curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendDocument" \
        -F "chat_id=$chat_id" \
        -F "document=@$file_path" \
        -F "caption=$caption")

    # Check if upload was successful
    if echo "$response" | grep -q '"ok":true'; then
        echo "✓ Successfully uploaded $(basename "$file_path") to $chat_id"
        return 0
    else
        echo "✗ Failed to upload $(basename "$file_path") to $chat_id"
        echo "Response: $response"
        return 1
    fi
}

# Function to send message to Telegram
send_message_to_telegram() {
    local message="$1"
    local chat_id="$2"

    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$chat_id" ]; then
        return 1
    fi

    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$chat_id" \
        -d "text=$message" \
        -d "parse_mode=Markdown" > /dev/null
}

# Function to display available groups and get selection
select_telegram_groups() {
    local available_groups=()
    local group_names=()

    # Parse TELEGRAM_GROUPS array
    if [ ${#TELEGRAM_GROUPS[@]} -eq 0 ]; then
        echo "No Telegram groups configured in megumi.sh"
        return 1
    fi

    echo ""
    echo "Available Telegram groups:"
    echo "--------------------------"

    local index=1
    for group in "${TELEGRAM_GROUPS[@]}"; do
        # Parse group entry: "GROUP_NAME:CHAT_ID"
        local group_name=$(echo "$group" | cut -d':' -f1)
        local chat_id=$(echo "$group" | cut -d':' -f2)

        available_groups+=("$chat_id")
        group_names+=("$group_name")

        echo "$index. $group_name ($chat_id)"
        ((index++))
    done

    echo "a. All groups"
    echo "0. Cancel"
    echo ""

    while true; do
        read -p "Select groups (comma-separated numbers, 'a' for all, or '0' to cancel): " selection
        selection=${selection,,}  # Convert to lowercase

        if [[ "$selection" == "0" ]]; then
            return 1
        elif [[ "$selection" == "a" || "$selection" == "all" ]]; then
            SELECTED_GROUPS=("${available_groups[@]}")
            SELECTED_GROUP_NAMES=("${group_names[@]}")
            return 0
        else
            # Parse comma-separated selections
            SELECTED_GROUPS=()
            SELECTED_GROUP_NAMES=()
            IFS=',' read -ra SELECTIONS <<< "$selection"

            local valid=true
            for sel in "${SELECTIONS[@]}"; do
                sel=$(echo "$sel" | tr -d '[:space:]')  # Remove whitespace
                if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le ${#available_groups[@]} ]; then
                    local idx=$((sel-1))
                    SELECTED_GROUPS+=("${available_groups[$idx]}")
                    SELECTED_GROUP_NAMES+=("${group_names[$idx]}")
                else
                    echo "Invalid selection: $sel"
                    valid=false
                    break
                fi
            done

            if [ "$valid" = true ] && [ ${#SELECTED_GROUPS[@]} -gt 0 ]; then
                return 0
            fi
        fi

        echo "Please enter valid selections."
    done
}

# Function to prompt for changelog
prompt_changelog() {
    echo ""
    read -p "Give changelog? (Y/N): " ADD_CHANGELOG
    ADD_CHANGELOG=${ADD_CHANGELOG,,}  # Convert to lowercase

    if [[ "$ADD_CHANGELOG" == "y" || "$ADD_CHANGELOG" == "yes" ]]; then
        echo ""
        echo "Enter changelog (press Ctrl+D or type 'END' on a new line when finished):"
        echo "---"

        CHANGELOG=""
        while IFS= read -r line; do
            if [[ "$line" == "END" ]]; then
                break
            fi
            if [ -n "$CHANGELOG" ]; then
                CHANGELOG+=$'\n'
            fi
            CHANGELOG+="$line"
        done

        if [ -n "$CHANGELOG" ]; then
            echo "---"
            echo "Changelog captured successfully!"
            return 0
        else
            echo "No changelog entered."
            return 1
        fi
    else
        return 1
    fi
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

# Function to prompt for Telegram posting
prompt_telegram_post() {
    echo ""
    read -p "Post to Telegram groups? (y/N): " POST_TO_TELEGRAM
    POST_TO_TELEGRAM=${POST_TO_TELEGRAM,,}  # Convert to lowercase

    if [[ "$POST_TO_TELEGRAM" == "y" || "$POST_TO_TELEGRAM" == "yes" ]]; then
        return 0
    else
        return 1
    fi
}

build_modules() {
    rm -rf "$BUILD_DIR"/*

    read -p "Enter Version (e.g., V1.0): " VERSION

    while true; do
        read -p "Enter Build Type (LAB/RELEASE): " BUILD_TYPE
        BUILD_TYPE=${BUILD_TYPE^^}
        if [[ "$BUILD_TYPE" == "LAB" || "$BUILD_TYPE" == "RELEASE" ]]; then
            break
        fi
        echo "Invalid input. Please enter LAB or RELEASE."
    done

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

    # Check if Telegram is enabled
    if [ "$TELEGRAM_ENABLED" = true ]; then
        # Prompt for Telegram posting
        if prompt_telegram_post; then
            # Prompt for changelog
            HAS_CHANGELOG=false
            if prompt_changelog; then
                HAS_CHANGELOG=true
            fi

            # Select groups to post to
            if select_telegram_groups; then
                echo ""
                echo "Uploading to selected Telegram groups..."

                # Create a summary message
                SUMMARY_MESSAGE="🚀 *Yamada Module Build Complete*%0A%0A"
                SUMMARY_MESSAGE+="📦 *Module:* $MODULE_ID (Normal & Enhanced)%0A"
                SUMMARY_MESSAGE+="🏷️ *Version:* $VERSION%0A"
                SUMMARY_MESSAGE+="🔧 *Build Type:* $BUILD_TYPE%0A"

                # Add changelog if provided
                if [ "$HAS_CHANGELOG" = true ] && [ -n "$CHANGELOG" ]; then
                    # URL encode the changelog for Telegram
                    ENCODED_CHANGELOG=$(echo "$CHANGELOG" | sed 's/%/%25/g; s/ /%20/g; s/!/%21/g; s/"/%22/g; s/#/%23/g; s/\$/%24/g; s/&/%26/g; s/'\''/%27/g; s/(/%28/g; s/)/%29/g; s/\*/%2A/g; s/+/%2B/g; s/,/%2C/g; s/-/%2D/g; s/\./%2E/g; s/\//%2F/g; s/:/%3A/g; s/;/%3B/g; s/</%3C/g; s/=/%3D/g; s/>/%3E/g; s/?/%3F/g; s/@/%40/g; s/\[/%5B/g; s/\\/%5C/g; s/\]/%5D/g; s/\^/%5E/g; s/_/%5F/g; s/`/%60/g; s/{/%7B/g; s/|/%7C/g; s/}/%7D/g; s/~/%7E/g')
                    # Replace newlines with %0A for Telegram
                    ENCODED_CHANGELOG=$(echo "$ENCODED_CHANGELOG" | tr '\n' ' ' | sed 's/ /%0A/g')
                    SUMMARY_MESSAGE+=%0A%0A"📝 *Changelog:*%0A$ENCODED_CHANGELOG"
                fi

                SUMMARY_MESSAGE+=%0A%0A"Files uploading below... ⬇️"

                local upload_success=0
                local total_groups=${#SELECTED_GROUPS[@]}
                local upload_total=$(( total_groups * 2 ))

                # Loop through selected groups
                for i in "${!SELECTED_GROUPS[@]}"; do
                    local chat_id="${SELECTED_GROUPS[$i]}"
                    local group_name="${SELECTED_GROUP_NAMES[$i]}"

                    echo ""
                    echo "📤 Posting to: $group_name"

                    # Send summary message first
                    send_message_to_telegram "$SUMMARY_MESSAGE" "$chat_id"

                    # Upload Normal ZIP
                    if [ -f "$BUILD_DIR/$ZIP_NAME" ]; then
                        caption="📱 $MODULE_ID - $VERSION ($BUILD_TYPE)"
                        if send_to_telegram "$BUILD_DIR/$ZIP_NAME" "$caption" "$chat_id"; then
                            ((upload_success++))
                        else
                            FAILURE_MESSAGE="❌ *Upload Failed*%0A%0AThere was an issue uploading the Normal module to $group_name."
                            send_message_to_telegram "$FAILURE_MESSAGE" "$chat_id"
                        fi
                    else
                        echo "Error: Normal ZIP file not found at $BUILD_DIR/$ZIP_NAME"
                    fi

                    # Upload Enhanced ZIP
                    if [ -f "$BUILD_DIR/$ZIP_NAME_ENHANCED" ]; then
                        caption_enhanced="📱 $MODULE_ID - $VERSION ($BUILD_TYPE) [ENHANCED]"
                        if send_to_telegram "$BUILD_DIR/$ZIP_NAME_ENHANCED" "$caption_enhanced" "$chat_id"; then
                            ((upload_success++))
                        else
                            FAILURE_MESSAGE="❌ *Upload Failed*%0A%0AThere was an issue uploading the ENHANCED module to $group_name."
                            send_message_to_telegram "$FAILURE_MESSAGE" "$chat_id"
                        fi
                    else
                        echo "Error: ENHANCED ZIP file not found at $BUILD_DIR/$ZIP_NAME_ENHANCED"
                    fi
                    
                    # Final success message for this group
                    COMPLETION_MESSAGE="✅ *Upload Complete!*%0A%0ABoth modules processed for $group_name."
                    send_message_to_telegram "$COMPLETION_MESSAGE" "$chat_id"
                done

                echo ""
                echo "📊 Upload Summary:"
                echo "✅ Successful: $upload_success/$upload_total files"
                echo "❌ Failed: $((upload_total - upload_success))/$upload_total files"

            else
                echo "Telegram upload cancelled."
            fi
        else
            echo "Skipping Telegram upload."
        fi
    else
        echo ""
        echo "Post to telegram disabled, please setup megumi.sh and configure TELEGRAM_GROUPS array"
    fi
}

welcome
SECONDS=0  # Start timing
build_modules
success