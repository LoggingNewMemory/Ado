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

    # --- 2. BUILD NORMAL-HI-RES ZIP ---
    if [ -f "module.prop" ]; then
        cp "module.prop" "module.prop.tmp"
        sed "s/^name=.*$/name=${ORIGINAL_NAME} [Normal-Hi-Res]/" "module.prop.tmp" > "module.prop"
        rm "module.prop.tmp"
    fi
    if [ -f "system.prop" ]; then
        cp "system.prop" "../$BUILD_DIR/system.prop.original"
        echo "" >> "system.prop"
        cat "../Hi-Res.prop" >> "system.prop"
    fi
    ZIP_NAME_NHR="${MODULE_ID}-${VERSION}-Normal-Hi-Res.zip"
    ZIP_PATH_NHR="../$BUILD_DIR/$ZIP_NAME_NHR"
    zip -q -r "$ZIP_PATH_NHR" ./*
    echo "Created: $ZIP_NAME_NHR"

    # Restore system.prop for next builds
    if [ -f "../$BUILD_DIR/system.prop.original" ]; then
        mv "../$BUILD_DIR/system.prop.original" "system.prop"
    fi

    # --- 3. BUILD ENHANCED ZIP ---
    if [ -f "module.prop" ]; then
        cp "module.prop" "module.prop.tmp"
        sed "s/^name=.*$/name=${ORIGINAL_NAME} [Enhanced]/" "module.prop.tmp" > "module.prop"
        rm "module.prop.tmp"
    fi
    if [ -f "system.prop" ]; then
        cp "system.prop" "../$BUILD_DIR/system.prop.original"
        echo "" >> "system.prop"
        cat "../Enhanced.prop" >> "system.prop"
    fi
    if [ -f "AdoKang/OdoruPonpokorin.sh" ]; then
        cp "AdoKang/OdoruPonpokorin.sh" "../$BUILD_DIR/OdoruPonpokorin.sh.original"
        cat << 'INNER_EOF' >> "AdoKang/OdoruPonpokorin.sh"

# ENHANCED: Override media processing and aggressive debug disabling
setprop debug.audio.hal 0
setprop debug.audio.policy 0
for pid in $(pidof audioserver); do
    ionice -c 1 -n 0 -p $pid
done
INNER_EOF
    fi
    if [ -d "../Enhanced_Files" ]; then
        cp -a "../Enhanced_Files/"* . 2>/dev/null || true
    fi
    ZIP_NAME_ENHANCED="${MODULE_ID}-${VERSION}-Enhanced.zip"
    ZIP_PATH_ENHANCED="../$BUILD_DIR/$ZIP_NAME_ENHANCED"
    zip -q -r "$ZIP_PATH_ENHANCED" ./*
    echo "Created: $ZIP_NAME_ENHANCED"

    # --- 4. BUILD ENHANCED-HI-RES ZIP ---
    if [ -f "module.prop" ]; then
        cp "module.prop" "module.prop.tmp"
        sed "s/^name=.*$/name=${ORIGINAL_NAME} [Enhanced-Hi-Res]/" "module.prop.tmp" > "module.prop"
        rm "module.prop.tmp"
    fi
    if [ -f "system.prop" ]; then
        echo "" >> "system.prop"
        cat "../Hi-Res.prop" >> "system.prop"
    fi
    ZIP_NAME_EHR="${MODULE_ID}-${VERSION}-Enhanced-Hi-Res.zip"
    ZIP_PATH_EHR="../$BUILD_DIR/$ZIP_NAME_EHR"
    zip -q -r "$ZIP_PATH_EHR" ./*
    echo "Created: $ZIP_NAME_EHR"

    # Restore system.prop for next build
    if [ -f "../$BUILD_DIR/system.prop.original" ]; then
        cp "../$BUILD_DIR/system.prop.original" "system.prop"
        echo "" >> "system.prop"
        cat "../Enhanced.prop" >> "system.prop"
    fi

    # --- 5. BUILD ENHANCED-MAX-HI-RES ZIP ---
    if [ -f "module.prop" ]; then
        cp "module.prop" "module.prop.tmp"
        sed "s/^name=.*$/name=${ORIGINAL_NAME} [Enhanced-Max-Hi-Res]/" "module.prop.tmp" > "module.prop"
        rm "module.prop.tmp"
    fi
    if [ -f "system.prop" ]; then
        echo "" >> "system.prop"
        cat "../Max-Hi-Res.prop" >> "system.prop"
    fi
    ZIP_NAME_EMHR="${MODULE_ID}-${VERSION}-Enhanced-Max-Hi-Res.zip"
    ZIP_PATH_EMHR="../$BUILD_DIR/$ZIP_NAME_EMHR"
    zip -q -r "$ZIP_PATH_EMHR" ./*
    echo "Created: $ZIP_NAME_EMHR"

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
            bash Modular/FlashToDevice.sh "$BUILD_DIR/$ZIP_NAME_EMHR" "$BUILD_DIR"
        fi
    else
        # Interactive mode for flashing
        read -p "Flash directly to connected device via ADB? (y/N): " DO_ADB_FLASH
        DO_ADB_FLASH=${DO_ADB_FLASH,,}
        if [[ "$DO_ADB_FLASH" == "y" || "$DO_ADB_FLASH" == "yes" ]]; then
            echo ""
            echo "Which version do you want to flash?"
            echo "1) Normal ($ZIP_NAME)"
            echo "2) Normal-Hi-Res ($ZIP_NAME_NHR)"
            echo "3) Enhanced ($ZIP_NAME_ENHANCED)"
            echo "4) Enhanced-Hi-Res ($ZIP_NAME_EHR)"
            echo "5) Enhanced-Max-Hi-Res ($ZIP_NAME_EMHR)"
            read -p "Select (1-5): " FLASH_SELECTION
            
            if [ -f "Modular/FlashToDevice.sh" ]; then
                if [ "$FLASH_SELECTION" == "5" ]; then
                    bash Modular/FlashToDevice.sh "$BUILD_DIR/$ZIP_NAME_EMHR" "$BUILD_DIR"
                elif [ "$FLASH_SELECTION" == "4" ]; then
                    bash Modular/FlashToDevice.sh "$BUILD_DIR/$ZIP_NAME_EHR" "$BUILD_DIR"
                elif [ "$FLASH_SELECTION" == "3" ]; then
                    bash Modular/FlashToDevice.sh "$BUILD_DIR/$ZIP_NAME_ENHANCED" "$BUILD_DIR"
                elif [ "$FLASH_SELECTION" == "2" ]; then
                    bash Modular/FlashToDevice.sh "$BUILD_DIR/$ZIP_NAME_NHR" "$BUILD_DIR"
                else
                    bash Modular/FlashToDevice.sh "$BUILD_DIR/$ZIP_NAME" "$BUILD_DIR"
                fi
            fi
        fi
    fi

    if [ "$SENDTOTELEGRAM" == "1" ]; then
        if [ -f "Modular/SendToTelegram.sh" ]; then
            bash Modular/SendToTelegram.sh "$MODULE_ID" "$VERSION" "$BUILD_DIR/$ZIP_NAME"
            bash Modular/SendToTelegram.sh "$MODULE_ID" "$VERSION" "$BUILD_DIR/$ZIP_NAME_NHR"
            bash Modular/SendToTelegram.sh "$MODULE_ID" "$VERSION" "$BUILD_DIR/$ZIP_NAME_ENHANCED"
            bash Modular/SendToTelegram.sh "$MODULE_ID" "$VERSION" "$BUILD_DIR/$ZIP_NAME_EHR"
            bash Modular/SendToTelegram.sh "$MODULE_ID" "$VERSION" "$BUILD_DIR/$ZIP_NAME_EMHR"
        fi
    fi
}

welcome
SECONDS=0  # Start timing
build_modules
success