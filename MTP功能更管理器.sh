#!/bin/bash
# Anbernic CubeXX MTP Manager
. /mnt/mod/ctrl/configs/functions &>/dev/null 2>&1

progdir=$(cd $(dirname $0); pwd)
MTPBIN="${progdir}/mtp/umtprd"
MTPCONF="${progdir}/mtp/umtprd.conf"
UDC_NAME="5100000.udc-controller"

function prepare_mtp_gadget() {
    # Force clean previous state
    echo "" > /sys/kernel/config/usb_gadget/g1/UDC 2>/dev/null
    sleep 0.5
    umount -l /dev/ffs.mtp 2>/dev/null
    find /sys/kernel/config/usb_gadget/g1/configs -type l -delete 2>/dev/null
    find /sys/kernel/config/usb_gadget/g1 -depth -type d -not -path "/sys/kernel/config/usb_gadget/g1" -exec rmdir {} \; 2>/dev/null
    rmdir /sys/kernel/config/usb_gadget/g1 2>/dev/null

    # Create config symlink
    mount -o remount,rw / 2>/dev/null 
    mkdir -p /etc/umtprd
    ln -sf "$MTPCONF" /etc/umtprd/umtprd.conf

    # Setup USB Gadget ConfigFS
    mkdir -p /sys/kernel/config/usb_gadget/g1/strings/0x409
    echo 0x1d6b > /sys/kernel/config/usb_gadget/g1/idVendor
    echo 0x0100 > /sys/kernel/config/usb_gadget/g1/idProduct
    echo "Anbernic" > /sys/kernel/config/usb_gadget/g1/strings/0x409/manufacturer
    echo "RG CubeXX" > /sys/kernel/config/usb_gadget/g1/strings/0x409/product

    mkdir -p /sys/kernel/config/usb_gadget/g1/functions/ffs.mtp
    mkdir -p /sys/kernel/config/usb_gadget/g1/configs/c.1/strings/0x409
    ln -sf /sys/kernel/config/usb_gadget/g1/functions/ffs.mtp /sys/kernel/config/usb_gadget/g1/configs/c.1/

    # Mount FunctionFS
    mkdir -p /dev/ffs.mtp
    mount -t functionfs mtp /dev/ffs.mtp
}

function enable_mtp() {
    [ -z ${1} ] && mpv $rotate_28 --really-quiet --fs --image-display-duration=1 "${progdir}/res/mtpon-${LANG_CUR}.png"
    prepare_mtp_gadget
    chmod +x "$MTPBIN"
    "$MTPBIN" & 
    sleep 1
    echo "$UDC_NAME" > /sys/kernel/config/usb_gadget/g1/UDC
}

function disable_mtp() {
    [ -z ${1} ] && mpv $rotate_28 --really-quiet --fs --image-display-duration=1 "${progdir}/res/mtpoff-${LANG_CUR}.png"
    echo "" > /sys/kernel/config/usb_gadget/g1/UDC 2>/dev/null
    pkill -f umtprd
    umount -l /dev/ffs.mtp 2>/dev/null
    rm -f /etc/umtprd/umtprd.conf
    sync
}

function tmp_mtp() {
    [ -z ${1} ] && mpv $rotate_28 --really-quiet --fs --image-display-duration=6000 "${progdir}/res/mtptmp-${LANG_CUR}.png" &
    prepare_mtp_gadget
    chmod +x "$MTPBIN"
    "$MTPBIN" & 
    sleep 1
    echo "$UDC_NAME" > /sys/kernel/config/usb_gadget/g1/UDC
}

# Key listener logic
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
                if ((mtp_tmp_flag)); then 
                    pkill -f mpv; 
                    disable_mtp $1; 
                    user_quit; fi
            fi
        ;;
        (${B_KEY})
            if [[ "${line}" =~ ${RELEASE} ]]; then
                if ((mtp_tmp_flag)) && [ -z ${1} ]; then
                    mtp_tmp_flag=0
                    pkill -f mpv
                    tmp_mtp $1
                fi
            fi
        ;;
        (${Y_KEY})
            if [[ "${line}" =~ ${RELEASE} ]]; then
                if ((mtp_tmp_flag)); then 
                    pkill -f mpv; 
                    enable_mtp $1; 
                    user_quit; fi
            fi
        ;;
        (${FUNC_KEY_EVENT})
            if [[ "${line}" =~ ${RELEASE} ]]; then
                if ((mtp_tmp_flag)); then 
                    user_quit;
                else 
                    pkill -f mpv; 
                    disable_mtp $1; 
                    user_quit; fi
            fi
        ;;
    esac
done