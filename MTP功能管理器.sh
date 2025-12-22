#!/bin/bash
# Anbernic CubeXX MTP Manager

. /mnt/mod/ctrl/configs/functions &>/dev/null 2>&1

progdir=$(cd $(dirname $0); pwd)

# Backend: uMTP-Responder v1.6.8
MTPBIN="${progdir}/mtp/umtprd"
MTPCONF="${progdir}/mtp/umtprd.conf" 

# Fetch variables
UDC_NAME=$(ls /sys/class/udc | head -n 1)
MANUFACTURER=$(cat /etc/hostname 2>/dev/null)
DEVICE_MODEL=$(cat /mnt/vendor/oem/board.ini 2>/dev/null)
FIRMWARE_VER=$(cat /mnt/vendor/oem/version.ini 2>/dev/null)
SERIAL_NUM=$(xargs -n 1 -a /proc/cmdline 2>/dev/null | sed -n 's/^snum=//p')


function disable_mtp() {
    # Physical disconnect
    [ -d /sys/kernel/config/usb_gadget/g1 ] && echo "" > /sys/kernel/config/usb_gadget/g1/UDC 2>/dev/null
    
    # Kill process
    pkill -f umtprd 2>/dev/null
    sleep 0.5
    
    # Unmount FFS
    umount -l /dev/ffs.mtp 2>/dev/null
    
    # Cleanup ConfigFS
    if [ -d /sys/kernel/config/usb_gadget/g1 ]; then
        find /sys/kernel/config/usb_gadget/g1 -depth -type d -not -path "/sys/kernel/config/usb_gadget/g1" -exec rmdir {} \; 2>/dev/null
        rmdir /sys/kernel/config/usb_gadget/g1 2>/dev/null
    fi
    
    [ -z "${1}" ] && mpv $rotate_28 --really-quiet --fs --image-display-duration=1 "${progdir}/res/mtpoff-${LANG_CUR}.png"
    sync
}

# Config update
function update_mtp_conf() {
    mount -o remount,rw / 2>/dev/null
    mkdir -p /etc/umtprd

    cp "$progdir/mtp/umtprd.conf" /etc/umtprd/umtprd.conf

    local TARGET="/etc/umtprd/umtprd.conf"

    sed -i \
        -e "s|^usb_vendor_id .*|usb_vendor_id \"0x1d6b\"|" \
        -e "s|^usb_product_id .*|usb_product_id \"0x0100\"|" \
        -e "s|^serial .*|serial \"$SERIAL_NUM\"|" \
        -e "s|^manufacturer .*|manufacturer \"$MANUFACTURER\"|" \
        -e "s|^product .*|product \"$DEVICE_MODEL\"|" \
        -e "s|^firmware_version .*|firmware_version \"$FIRMWARE_VER\"|" \
        "$TARGET"

    local sd2_content
    if mountpoint -q /mnt/sdcard 2>/dev/null; then
        sd2_content='storage "/mnt/sdcard" "SD2" "rw"'
    else
        sd2_content='# SD2 not mounted'
    fi

    sed -i "s|__SD2_ENTRY__|$sd2_content|" "$TARGET"
}

function enable_mtp() {
    disable_mtp 1

    [ -z "${1}" ] && mpv $rotate_28 --really-quiet --fs --image-display-duration=1 "${progdir}/res/mtpon-${LANG_CUR}.png"
    update_mtp_conf

    # Gadget setup
    local GADGET="/sys/kernel/config/usb_gadget/g1"
    mkdir -p "$GADGET/strings/0x409" "$GADGET/configs/c.1/strings/0x409"
    echo 0x1d6b > "$GADGET/idVendor"
    echo 0x0100 > "$GADGET/idProduct"
    echo 500 > "$GADGET/configs/c.1/MaxPower"
    echo "$SERIAL_NUM" > "$GADGET/strings/0x409/serialnumber"
    echo "$MANUFACTURER" > "$GADGET/strings/0x409/manufacturer"
    echo "$DEVICE_MODEL" > "$GADGET/strings/0x409/product"

    # FFS setup
    mkdir -p "$GADGET/functions/ffs.mtp"
    ln -sf "$GADGET/functions/ffs.mtp" "$GADGET/configs/c.1/"
    mkdir -p /dev/ffs.mtp
    mount -t functionfs mtp /dev/ffs.mtp


    # Start binary
    chmod +x "$MTPBIN"
    "$MTPBIN" & 
    sleep 1
    echo "$UDC_NAME" > "$GADGET/UDC"
}

function tmp_mtp() {
    disable_mtp 1
    [ -z "${1}" ] && mpv $rotate_28 --really-quiet --fs --image-display-duration=6000 "${progdir}/res/mtptmp-${LANG_CUR}.png" &
    enable_mtp 1
}

# Input loop
mtp_tmp_flag=1
pkill -f mpv
pkill -f evtest
mpv $rotate_28 --really-quiet --fs --image-display-duration=6000 "${progdir}/res/mtp-${LANG_CUR}.png" &

get_devices
(
     for INPUT_DEVICE in ${INPUT_DEVICES[@]}; do
        evtest "${INPUT_DEVICE}" 2>&1 &
     done
     wait
) | while read line; do
    case $line in
        (${A_KEY})
            if [[ "${line}" =~ ${RELEASE} ]]; then
                if ((mtp_tmp_flag)); then pkill -f mpv; disable_mtp "$1"; user_quit; fi
            fi
        ;;
        (${B_KEY})
            if [[ "${line}" =~ ${RELEASE} ]]; then
                if ((mtp_tmp_flag)) && [ -z "${1}" ]; then
                    mtp_tmp_flag=0
                    pkill -f mpv
                    tmp_mtp "$1"
                fi
            fi
        ;;
        (${Y_KEY})
            if [[ "${line}" =~ ${RELEASE} ]]; then
                if ((mtp_tmp_flag)); then pkill -f mpv; enable_mtp "$1"; user_quit; fi
            fi
        ;;
        (${FUNC_KEY_EVENT})
            if [[ "${line}" =~ ${RELEASE} ]]; then
                if ((mtp_tmp_flag)); then user_quit;
                else pkill -f mpv; disable_mtp "$1"; user_quit; fi
            fi
        ;;
    esac
done