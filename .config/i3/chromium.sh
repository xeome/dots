chromium \
--use-gl=egl \
--use-vulkan \
--enable-accelerated-video-decoder \
--enable-features=VaapiVideoDecoder,UseChromeOSDirectVideoDecoder \
--ozone-platform=x11 \
--ignore-gpu-blocklist \
--disable-gpu-driver-bug-workaround & disown
