[ ! "$MODPATH" ] && MODPATH=${0%/*}
# destination
MODAPCS=`find $MODPATH -type f -name *policy*.conf`
MODAPXS=`find $MODPATH -type f -name *policy*.xml`
MODAPIS=`find $MODPATH -type f -name *audio*platform*info*.xml`
MODMPS=`find $MODPATH -type f -name *mixer*paths*.xml`
# function
patch_audio_format_pcm() {
# patch audio policy conf
for MODAPC in $MODAPCS; do
  if ! grep -q deep_buffer_24 $MODAPC; then
    sed -i '/^outputs/a\
  deep_buffer_24 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED|AUDIO_FORMAT_PCM_8_24_BIT\
    sampling_rates 44100|48000|88200|96000|128000|176400|192000|352800|384000\
    bit_width 24\
    app_type 69940\
  }' $MODAPC
  fi
  if ! grep -q default_24bit $MODAPC; then
    sed -i '/^outputs/a\
  default_24bit {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED|AUDIO_FORMAT_PCM_8_24_BIT\
    sampling_rates 44100|48000|88200|96000|128000|176400|192000|352800|384000\
    bit_width 24\
    app_type 69937\
  }' $MODAPC
  fi
  if ! grep -q deep_buffer_32 $MODAPC; then
    sed -i '/^outputs/a\
  deep_buffer_32 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates 44100|48000|88200|96000|128000|176400|192000|352800|384000\
    bit_width 32\
    app_type 69940\
  }' $MODAPC
  fi
  if ! grep -q default_32bit $MODAPC; then
    sed -i '/^outputs/a\
  default_32bit {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates 44100|48000|88200|96000|128000|176400|192000|352800|384000\
    bit_width 32\
    app_type 69937\
  }' $MODAPC
  fi
  if ! grep -q deep_buffer_float $MODAPC; then
    sed -i '/^outputs/a\
  deep_buffer_float {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates 44100|48000|88200|96000|128000|176400|192000|352800|384000\
    app_type 69940\
  }' $MODAPC
  fi
  if ! grep -q default_float $MODAPC; then
    sed -i '/^outputs/a\
  default_float {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates 44100|48000|88200|96000|128000|176400|192000|352800|384000\
    app_type 69937\
  }' $MODAPC
  fi
done
# patch audio policy xml
for MODAPX in $MODAPXS; do
  sed -i '/AUDIO_OUTPUT_FLAG_DEEP_BUFFER/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_24_BIT_PACKED"\
                             samplingRates="44100,48000,88200,96000,128000,176400,192000,352800,384000"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>\
                    <profile name="" format="AUDIO_FORMAT_PCM_8_24_BIT"\
                             samplingRates="44100,48000,88200,96000,128000,176400,192000,352800,384000"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>' $MODAPX
  sed -i '/AUDIO_OUTPUT_FLAG_PRIMARY/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_24_BIT_PACKED"\
                             samplingRates="44100,48000,88200,96000,128000,176400,192000,352800,384000"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>\
                    <profile name="" format="AUDIO_FORMAT_PCM_8_24_BIT"\
                             samplingRates="44100,48000,88200,96000,128000,176400,192000,352800,384000"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>' $MODAPX
  sed -i '/AUDIO_OUTPUT_FLAG_DEEP_BUFFER/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_32_BIT"\
                             samplingRates="44100,48000,88200,96000,128000,176400,192000,352800,384000"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>' $MODAPX
  sed -i '/AUDIO_OUTPUT_FLAG_PRIMARY/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_32_BIT"\
                             samplingRates="44100,48000,88200,96000,128000,176400,192000,352800,384000"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>' $MODAPX
  sed -i '/AUDIO_OUTPUT_FLAG_DEEP_BUFFER/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_FLOAT"\
                             samplingRates="44100,48000,88200,96000,128000,176400,192000,352800,384000"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>' $MODAPX
  sed -i '/AUDIO_OUTPUT_FLAG_PRIMARY/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_FLOAT"\
                             samplingRates="44100,48000,88200,96000,128000,176400,192000,352800,384000"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>' $MODAPX
done
}
# patch audio format pcm
patch_audio_format_pcm
# patch audio platform info
for MODAPI in $MODAPIS; do
  if ! grep -q '<bit_width_configs>' $MODAPI; then
    sed -i '/<audio_platform_info>/a\
    <bit_width_configs>\
        <device name="SND_DEVICE_OUT_HEADPHONES" bit_width="24"/>\
        <device name="SND_DEVICE_OUT_SPEAKER" bit_width="24"/>\
    </bit_width_configs>' $MODAPI
  fi
  if ! grep -q '<device name="SND_DEVICE_OUT_SPEAKER" bit_width=' $MODAPI; then
    sed -i '/<bit_width_configs>/a\
        <device name="SND_DEVICE_OUT_SPEAKER" bit_width="24"/>' $MODAPI
  fi
  if ! grep -q '<device name="SND_DEVICE_OUT_HEADPHONES" bit_width=' $MODAPI; then
    sed -i '/<bit_width_configs>/a\
        <device name="SND_DEVICE_OUT_HEADPHONES" bit_width="24"/>' $MODAPI
  fi
  sed -i 's|<device name="SND_DEVICE_OUT_HEADPHONES" bit_width="16"|<device name="SND_DEVICE_OUT_HEADPHONES" bit_width="24"|g' $MODAPI
  sed -i 's|<device name="SND_DEVICE_OUT_SPEAKER" bit_width="16"|<device name="SND_DEVICE_OUT_SPEAKER" bit_width="24"|g' $MODAPI
  sed -i 's|<device name="SND_DEVICE_OUT_HEADPHONES" bit_width="24"|<device name="SND_DEVICE_OUT_HEADPHONES" bit_width="32"|g' $MODAPI
  sed -i 's|<device name="SND_DEVICE_OUT_SPEAKER" bit_width="24"|<device name="SND_DEVICE_OUT_SPEAKER" bit_width="32"|g' $MODAPI
#s16  sed -i 's|<device name="SND_DEVICE_OUT_SPEAKER" bit_width="24"|<device name="SND_DEVICE_OUT_SPEAKER" bit_width="16"|g' $MODAPI
#s16  sed -i 's|<device name="SND_DEVICE_OUT_SPEAKER" bit_width="32"|<device name="SND_DEVICE_OUT_SPEAKER" bit_width="16"|g' $MODAPI
  sed -i 's|<device name="SND_DEVICE_OUT_SPEAKER" bit_width="16"|<device name="SND_DEVICE_OUT_SPEAKER" bit_width="24"|g' $MODAPI
  sed -i 's|<device name="SND_DEVICE_OUT_SPEAKER" bit_width="32"|<device name="SND_DEVICE_OUT_SPEAKER" bit_width="24"|g' $MODAPI
done
# patch mixer path
for MODMP in $MODMPS; do
  if ! grep -q hph-highquality-mode $MODMP; then
    sed -i '/<\/mixer>/i\
    <path name="hph-highquality-mode">\
    <\/path>\' $MODMP
  fi
done
