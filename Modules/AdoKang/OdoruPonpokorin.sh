#!/system/bin/sh
settings put global audio_safe_volume_state 0
settings put global bluetooth_a2dp_supports_optional_codecs_enabled 1
settings put global bluetooth_a2dp_src_codec_priority 1000000

# --- audioserver ---
for pid in $(pidof audioserver); do
    renice -n -20 -p $pid
    chrt -f -p 99 $pid
    ionice -c 1 -n 0 -p $pid
done

# --- Bluetooth ---
for pid in $(pidof com.android.bluetooth); do
    renice -n -20 -p $pid
    chrt -f -p 99 $pid
    ionice -c 1 -n 0 -p $pid
done

# --- HIDL Audio HAL (Android 8–12) ---
for pid in $(pidof android.hardware.audio.service android.hardware.audio.service.mediatek android.hardware.audio@7.1-service android.hardware.audio@7.0-service android.hardware.audio@6.0-service android.hardware.audio@5.0-service android.hardware.audio@4.0-service android.hardware.audio@2.0-service); do
    renice -n -20 -p $pid
    chrt -f -p 99 $pid
    ionice -c 1 -n 0 -p $pid
done

# --- AIDL Audio HAL (Android 13+) ---
for pid in $(pidof android.hardware.audio-service android.hardware.audio-service.ndk android.hardware.audio-service.aidl); do
    renice -n -20 -p $pid
    chrt -f -p 99 $pid
    ionice -c 1 -n 0 -p $pid
done

# --- Media services ---
for pid in $(pidof mediaserver media.codec media.extractor); do
    renice -n -20 -p $pid
    chrt -f -p 99 $pid
    ionice -c 1 -n 0 -p $pid
done

# --- Qualcomm PAL / QTI Audio ---
for pid in $(pidof vendor.qti.hardware.pal@1.0-service vendor.qti.hardware.audio.service android.hardware.bluetooth.audio-service android.hardware.bluetooth.audio@2.1-service); do
    renice -n -20 -p $pid
    chrt -f -p 99 $pid
    ionice -c 1 -n 0 -p $pid
done

# --- MediaTek Audio HAL ---
for pid in $(pidof vendor.mediatek.hardware.audio@6.0-service vendor.mediatek.hardware.audio@5.0-service audio.primary.mt6893 audio.primary.mt6789 audio.primary.mt6983); do
    renice -n -20 -p $pid
    chrt -f -p 99 $pid
    ionice -c 1 -n 0 -p $pid
done