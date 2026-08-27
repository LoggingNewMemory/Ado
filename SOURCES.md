# Audio Tweaks Sources & References

This document indexes the origin of the audio properties and tweaks used in the Ado Audio Module. Because the majority of Android audio routing and decoding is handled by proprietary vendor hardware (like Qualcomm DSPs), many of these properties are primarily found inside **vendor-specific device trees** rather than the generic Android Open Source Project (AOSP) repository.

Below is a categorized list of sources and repositories where these properties originate and are actively used.

---

## 1. LineageOS Device Trees (GitHub)
Most of the `vendor.audio.*` tweaks are standard Qualcomm Audio HAL configurations. They are extensively documented in the `vendor.prop` files of custom ROMs like LineageOS to enable high-fidelity software decoding and routing.

*   **Properties:**
    *   `vendor.audio.flac.sw.decoder.24bit`
    *   `vendor.audio.use.sw.alac.decoder`
    *   `vendor.audio.use.sw.ape.decoder`
    *   `vendor.audio.capture.pcm.24bit.enable`
    *   `vendor.audio.capture.pcm.32bit.enable`
    *   `persist.vendor.audio_hal.dsp_bit_width_enforce_mode`
*   **Source:** [LineageOS GitHub - Xiaomi SM8250 Common Tree (vendor.prop)](https://github.com/LineageOS/android_device_xiaomi_sm8250-common/blob/lineage-21/vendor.prop#L20-L24)
*   **Source:** [LineageOS GitHub - OnePlus SM8250 Common Tree](https://github.com/LineageOS/android_device_oneplus_sm8250-common/blob/lineage-21/vendor.prop)

---

## 2. Qualcomm CodeAurora Forum (CAF) Audio HAL
Properties related to offloading, buffer sizes, speaker protection, HDR recording, and the Fluence SDK originate from Qualcomm's proprietary Audio HAL (Hardware Abstraction Layer). These are parsed directly by the DSP binaries and HAL layer.

*   **Properties:**
    *   `vendor.audio.offload.buffer.size.kb`
    *   `vendor.audio.offload.multiaac.enable`
    *   `ro.vendor.audio.sdk.fluencetype`
    *   `vendor.audio.spkr_prot.enable`
    *   `vendor.audio.hdr.record.enable`
    *   `vendor.audio.tunnel.encode`
    *   `vendor.audio.feature.a2dp_offload.enable`
    *   `vendor.audio.hal.output.suspend.supported`
    *   `persist.vendor.audio.hw.binder.size_kbyte`
    *   `persist.vendor.audio.fluence.voicemode`
    *   `persist.vendor.audio.fluence.speaker`
    *   `persist.vendor.audio.ras.enabled`
    *   `persist.vendor.audio.delta.refresh`
    *   `persist.vendor.bt.a2dp_offload_cap`
*   **Source:** Parsed in the Qualcomm `hardware/qcom/audio` repository. You can view the parsing logic in custom ROM mirrors of CAF: [LineageOS QCOM Audio HAL](https://github.com/LineageOS/android_hardware_qcom_audio)

---

## 3. AOSP Core Frameworks (cs.android.com)
The properties that dictate how the Android OS itself handles memory, resampling, audio mixing, and spatializer are verifiable directly on [Android Code Search](https://cs.android.com).

*   **Property:** `ro.af.client_heap_size_kbyte`
    *   **Description:** Allocates the shared memory heap for audio tracks.
    *   **Source:** Parsed in [AudioFlinger.cpp](https://cs.android.com/android/platform/superproject/main/+/main:frameworks/av/services/audioflinger/AudioFlinger.cpp;l=400?q=ro.af.client_heap_size_kbyte).
*   **Property:** `af.resampler.quality`
    *   **Description:** Selects AudioFlinger resampler algorithm. Value `4` = VERY_HIGH_QUALITY (Kaiser windowed-sinc filter) — the highest meaningful value.
    *   **Source:** Enum defined in [AudioResampler.h](https://cs.android.com/android/platform/superproject/main/+/main:frameworks/av/media/libaudioprocessing/AudioResampler.h).
*   **Property:** `af.fast_track_multiplier`
    *   **Description:** Multiplies the number of AudioFlinger fast-track slots. Range: [1, 2].
    *   **Source:** Parsed in [AudioFlinger.cpp](https://cs.android.com/android/platform/superproject/main/+/main:frameworks/av/services/audioflinger/AudioFlinger.cpp).
*   **Property:** `ro.audio.ignore_effects`
    *   **Description:** Forcefully bypasses software audio effects.
    *   **Source:** Parsed in [AudioPolicyManager.cpp](https://cs.android.com/android/platform/superproject/main/+/main:frameworks/av/services/audiopolicy/managerdefault/AudioPolicyManager.cpp?q=ro.audio.ignore_effects).
*   **Property:** `audio.offload.multiple.enabled`
    *   **Description:** Allows multiple concurrent hardware-offloaded audio tracks.
    *   **Source:** Audio framework system properties parsing.
*   **Property:** `ro.audio.spatializer_enabled`
    *   **Description:** Initializes the Android Spatializer service (Android 12+).
    *   **Source:** [Spatializer.cpp](https://cs.android.com/android/platform/superproject/main/+/main:frameworks/av/services/audioflinger/Spatializer.cpp).
*   **Property:** `audio.spatial.headtracking.enabled`
    *   **Description:** Enables head-tracking-aware spatial audio (Android 13+).
    *   **Source:** [Android Spatial Audio developer guide](https://developer.android.com/media/audio/spatial).
*   **Property:** `audio.sys.noisy.broadcast.delay`
    *   **Description:** Delay (ms) before firing `ACTION_AUDIO_BECOMING_NOISY` on headphone unplug. Allows media apps to pause gracefully before audio reroutes to speaker.
    *   **Source:** [AudioService.java](https://cs.android.com/android/platform/superproject/main/+/main:frameworks/base/services/core/java/com/android/server/audio/AudioService.java).
*   **Properties:** `audio.safemedia.bypass`, `audio.safemedia.force`
    *   **Description:** Bypass the EU/regulatory safe-volume warning at the system property level.
    *   **Source:** Android Settings framework / [Audio Misc Settings module](https://github.com/yzyhk904/audio-misc-settings).
*   **Properties:** `ro.config.media_vol_steps`, `ro.config.vc_call_vol_steps`
    *   **Description:** Controls number of volume steps for media and voice call streams. Default: 15 and 7 respectively.
    *   **Source:** Android AudioService volume step configuration.
*   **Property:** `ro.audio.usb.period_us`
    *   **Description:** USB audio hardware period in microseconds. Controls buffer chunk size to USB DACs. `5333` ≈ 5.3ms — balances low latency and stability.
    *   **Source:** Seen in LineageOS USB DAC-capable device trees; [Audio Misc Settings](https://github.com/yzyhk904/audio-misc-settings).

---

## 4. AAUDIO Low-Latency Framework
Properties for the Android AAudio API's MMAP (Memory Mapped) low-latency path.

*   **Properties:**
    *   `aaudio.mmap_policy` — `2` = AUTO (try MMAP, fallback to legacy)
    *   `aaudio.mmap_exclusive_policy` — `2` = AUTO (try exclusive direct-buffer path)
    *   `aaudio.hw_burst_min_usec` — `2000` μs = sweet spot for modern Snapdragon
*   **Source:** [Android AAudio developer documentation](https://developer.android.com/ndk/guides/audio/aaudio/aaudio)
*   **Source:** [Google Oboe library full guide](https://github.com/google/oboe/blob/main/docs/FullGuide.md)
*   **Source:** [AOSP AudioClient.cpp — mmap_policy parsing](https://cs.android.com/android/platform/superproject/main/+/main:frameworks/av/media/libaudioclient/AudioClient.cpp)

---

## 5. High-Res Bluetooth Audio Tweaks
Bluetooth properties to enable higher bitrates, codec offload, and disable absolute volume for finer amplifier control.

*   **Properties:**
    *   `persist.bluetooth.sbc_hd_higher_bitrate` — SBC XQ/HD dual-channel up to ~595 kbps
    *   `persist.bluetooth.disableabsvol` — prevents BT device from overriding phone system volume
    *   `persist.bluetooth.a2dp_ldac.default_quality_mode` — `3` in Hi-Res builds = 990 kbps max quality LDAC
    *   `ro.bluetooth.a2dp_offload.supported` — offloads A2DP encoding to DSP
    *   `persist.vendor.bt.a2dp_offload_cap` — declares eligible codecs for DSP offload (AAC, aptX, aptX HD, LDAC)
    *   `persist.bluetooth.aptx.hd` — enables aptX HD codec negotiation
    *   `vendor.audio.feature.a2dp_offload.enable` — explicit vendor-stack A2DP offload flag
*   **Source:** Android Bluetooth system properties framework; [LineageOS android_device_oneplus_sm8250-common vendor.prop](https://github.com/LineageOS/android_device_oneplus_sm8250-common/blob/lineage-21/vendor.prop)
*   **Source:** [AOSP Bluetooth stack — A2DP offload caps](https://cs.android.com/android/platform/superproject/main/+/main:packages/modules/Bluetooth/)
*   **Source:** Audio enhancement community discussions on [XDA Developers](https://xdaforums.com/c/android-development-and-hacking.9/)

---

## 6. Android AIDL Audio HAL Architecture (Android 13+)
The `OdoruPonpokorin.sh` service script applies real-time priority to audio processes. Android 13+ migrated from HIDL to AIDL HAL, introducing new process names.

*   **AIDL process names targeted:**
    *   `android.hardware.audio-service`
    *   `android.hardware.audio-service.ndk`
    *   `android.hardware.audio-service.aidl`
*   **Source:** [Android AIDL Audio HAL migration docs](https://source.android.com/docs/core/audio/aidl_architecture)
*   **Source:** [Android Dynamic Performance Framework (ADPF)](https://developer.android.com/games/sdk/adpf)

---

## 7. Module Specification (Magisk / KernelSU / APatch)
The `module.prop` file uses keys defined by root framework specifications.

*   **Keys used:** `id`, `name`, `version`, `versionCode`, `author`, `description`, `minMagisk`, `banner`
*   **Source:** [Magisk Module Developer Guide](https://topjohnwu.github.io/Magisk/guides.html)
*   **Source:** [KernelSU Module Docs](https://kernelsu.org/guide/module.html)
*   **Source:** [APatch Module Docs](https://apatch.dev)
