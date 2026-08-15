# SPDX-License-Identifier: Apache-2.0

# Arduino's own DFU bootloader (bootloaders/NANOR4/dfu_nano.hex in
# arduino/ArduinoCore-renesas), confirmed real VID:PID from that repo's boards.txt
# (nanor4.upload.vid/pid) -- entered via double-tap reset, separate USB enumeration
# from the running application (2341:0074).
#
# NOT --dfuse: the bootloader's alt=0 interface reports itself via a DfuSe-format
# descriptor ("@CodeFlash /0x00000000/8*2Ka,120*2Kg", confirmed via `dfu-util
# --list`), which looks like a real ST DfuSe device, but isn't -- dfu-util itself
# warns "DfuSe option used on non-DfuSe device". Confirmed real, flaky failures
# using --dfuse against this bootloader: one run hung forever on the write after
# a successful ERASE_PAGE special command, another STALLed (LIBUSB_ERROR_PIPE)
# on ERASE_PAGE itself. This bootloader does not reliably support DfuSe's
# SET_ADDRESS_POINTER/ERASE_PAGE special commands.
#
# Plain (non-DfuSe) dfu-util always writes sequentially starting at the
# interface's own reported base address (0x0), not the address the image was
# actually linked for (0x4000, this board's zephyr,code-partition). ESPHome's
# own zephyr component pads the .bin with leading 0x4000 bytes before
# flashing via plain dfu-util to compensate -- see zephyr/__init__.py's
# "host == DFU" upload path.
board_runner_args(dfu-util "--pid=2341:0374" "--alt=0")
board_runner_args(pyocd "--target=r7fa4m1ab")

include(${ZEPHYR_BASE}/boards/common/dfu-util.board.cmake)
include(${ZEPHYR_BASE}/boards/common/pyocd.board.cmake)
