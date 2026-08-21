#!/bin/bash

#========================
# NON INTERACTIVE MODE
# Remove this for interactive mode
# 1 = Enable | 0 = Disable
#========================
export MODULEVERSION="4.0"
export FLASHTODEVICE="1"
export SENDTOTELEGRAM="0"

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

build_modules() {
    rm -rf "$BUILD_DIR"/*

    if [ -n "$MODULEVERSION" ]; then
        VERSION="$MODULEVERSION"
        echo "Version: $VERSION"
    else
        read -p "Enter Version (e.g., V1.0): " VERSION
    fi

    # --- C Compilation ---
    if [ -f "Modular/CompileCusingNDK.sh" ]; then
        bash Modular/CompileCusingNDK.sh
        if [ $? -ne 0 ]; then
            echo "Error during C compilation. Aborting."
            exit 1
        fi
    fi

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
    ZIP_NAME="${MODULE_ID}-${VERSION}-Normal.zip"
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
        echo "" >> "system.prop"
        cat "../Enhanced.prop" >> "system.prop"
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

    # Inject Hi-Res file modifications for ENHANCED
    if [ -d "../Enhanced_Files" ]; then
        cp -a "../Enhanced_Files/"* . 2>/dev/null || true
    fi

    ZIP_NAME_ENHANCED="${MODULE_ID}-${VERSION}-Enhanced.zip"
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

    # Clean up Hi-Res file modifications from Modules dir
    if [ -d "../Enhanced_Files" ]; then
        rm -f copy.sh audio.txt post-fs-data.sh direct_patch.sh
    fi

    cd ..

    # --- ADB Flash / Telegram Logic ---
    if [ "$FLASHTODEVICE" == "1" ]; then
        if [ -f "Modular/FlashToDevice.sh" ]; then
            bash Modular/FlashToDevice.sh "$BUILD_DIR/$ZIP_NAME_ENHANCED" "$BUILD_DIR"
        fi
    else
        # Interactive mode for flashing
        read -p "Flash directly to connected device via ADB? (y/N): " DO_ADB_FLASH
        DO_ADB_FLASH=${DO_ADB_FLASH,,}
        if [[ "$DO_ADB_FLASH" == "y" || "$DO_ADB_FLASH" == "yes" ]]; then
            echo ""
            echo "Which version do you want to flash?"
            echo "1) Normal ($ZIP_NAME)"
            echo "2) Enhanced ($ZIP_NAME_ENHANCED)"
            read -p "Select (1/2): " FLASH_SELECTION
            
            if [ -f "Modular/FlashToDevice.sh" ]; then
                if [ "$FLASH_SELECTION" == "2" ]; then
                    bash Modular/FlashToDevice.sh "$BUILD_DIR/$ZIP_NAME_ENHANCED" "$BUILD_DIR"
                else
                    bash Modular/FlashToDevice.sh "$BUILD_DIR/$ZIP_NAME" "$BUILD_DIR"
                fi
            fi
        fi
    fi

    if [ "$SENDTOTELEGRAM" == "1" ]; then
        if [ -f "Modular/SendToTelegram.sh" ]; then
            bash Modular/SendToTelegram.sh "$MODULE_ID" "$VERSION" "$BUILD_DIR/$ZIP_NAME_ENHANCED"
            bash Modular/SendToTelegram.sh "$MODULE_ID" "$VERSION" "$BUILD_DIR/$ZIP_NAME"
        fi
    fi
}

welcome
SECONDS=0  # Start timing
build_modules
success