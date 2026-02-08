settings put global audio_safe_volume_state 0
settings put global bluetooth_a2dp_supports_optional_codecs_enabled 1
settings put global bluetooth_a2dp_src_codec_priority 1000000
resetprop ro.audio.flinger_standby_time_ms 3000
resetprop ro.audio.monitorRotation true
resetprop vendor.audio.offload.buffer.size.kb 64