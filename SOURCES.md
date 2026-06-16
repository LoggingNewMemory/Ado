# Audio Tweaks Sources & References

This document indexes the origin of the audio properties and tweaks used in the Ado Audio Module. Because the majority of Android audio routing and decoding is handled by proprietary vendor hardware (like Qualcomm DSPs), many of these properties are primarily found inside **vendor-specific device trees** rather than the generic Android Open Source Project (AOSP) repository.

Below is a categorized list of sources and repositories where these properties originate and are actively used.

## 1. LineageOS Device Trees (GitHub)
Most of the `vendor.audio.*` tweaks are standard Qualcomm Audio HAL configurations. They are extensively documented in the `vendor.prop` files of custom ROMs like LineageOS to enable high-fidelity software decoding and routing.

*   **Properties:** 
    *   `vendor.audio.flac.sw.decoder.24bit`
    *   `vendor.audio.use.sw.alac.decoder`
    *   `vendor.audio.use.sw.ape.decoder`
*   **Source:** [LineageOS GitHub - Xiaomi SM8250 Common Tree (vendor.prop)](https://github.com/LineageOS/android_device_xiaomi_sm8250-common/blob/lineage-21/vendor.prop#L20-L24)
*   **Source:** [LineageOS GitHub - OnePlus SM8250 Common Tree](https://github.com/LineageOS/android_device_oneplus_sm8250-common/blob/lineage-21/vendor.prop)

## 2. Qualcomm CodeAurora Forum (CAF) Audio HAL
Properties related to offloading, buffer sizes, and the Fluence SDK originate from Qualcomm's proprietary Audio HAL (Hardware Abstraction Layer). These are parsed directly by the DSP binaries and HAL layer.

*   **Properties:** 
    *   `vendor.audio.offload.buffer.size.kb`
    *   `vendor.audio.offload.multiaac.enable`
    *   `ro.vendor.audio.sdk.fluencetype`
*   **Source:** Parsed in the Qualcomm `hardware/qcom/audio` repository. You can view the parsing logic in custom ROM mirrors of CAF: [LineageOS QCOM Audio HAL](https://github.com/LineageOS/android_hardware_qcom_audio)

## 3. AOSP Core Frameworks (cs.android.com)
The properties that dictate how the Android OS itself handles memory and audio mixing are verifiable directly on [Android Code Search](https://cs.android.com).

*   **Property:** `ro.af.client_heap_size_kbyte`
    *   **Description:** Allocates the shared memory heap for audio tracks.
    *   **Source:** Parsed in [AudioFlinger.cpp](https://cs.android.com/android/platform/superproject/main/+/main:frameworks/av/services/audioflinger/AudioFlinger.cpp;l=400?q=ro.af.client_heap_size_kbyte).
*   **Property:** `ro.audio.ignore_effects`
    *   **Description:** Forcefully bypasses software audio effects.
    *   **Source:** Parsed in [AudioPolicyManager.cpp](https://cs.android.com/android/platform/superproject/main/+/main:frameworks/av/services/audiopolicy/managerdefault/AudioPolicyManager.cpp?q=ro.audio.ignore_effects).
*   **Property:** `audio.offload.multiple.enabled`
    *   **Description:** Checks if concurrent hardware offloading is allowed.
    *   **Source:** Audio framework system properties parsing.

## 4. High-Res Bluetooth Audio Tweaks
Bluetooth properties used to force older Bluetooth stacks to utilize higher bitrates and disable absolute volume for finer amplifier control.

*   **Properties:** 
    *   `persist.bluetooth.sbc_hd_higher_bitrate`
    *   `persist.bluetooth.disableabsvol`
*   **Source:** Found in the Android Bluetooth system properties framework and heavily utilized in Android audio enhancement mods (like Viper4Android and JamesDSP forums on XDA Developers).
