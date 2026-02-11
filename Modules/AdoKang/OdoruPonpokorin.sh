#!/system/bin/sh
settings put global audio_safe_volume_state 0
settings put global bluetooth_a2dp_supports_optional_codecs_enabled 1
settings put global bluetooth_a2dp_src_codec_priority 1000000

for pid in $(pidof audioserver); do renice -n -20 -p $pid; done
for pid in $(pidof com.android.bluetooth); do renice -n -20 -p $pid; done