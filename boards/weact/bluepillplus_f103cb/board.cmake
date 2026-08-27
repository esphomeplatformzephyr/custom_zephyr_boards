# SPDX-License-Identifier: Apache-2.0

# openocd is the default: hardware-verified over the board's SWD header
# (support/openocd.cfg targets a generic external ST-Link -- this board has
# no onboard debug probe). stm32flash/jlink are alternates -- stm32flash
# goes through the STM32F103's own ROM bootloader over USART1 instead
# (AN2606: F1 medium-density parts support only USART1, no native USB DFU
# like F4/F7); enter it by holding BOOT0, tapping NRST, then releasing
# BOOT0 after ~0.5s (WeAct's own HDK/README.md "How to Enter ISP"
# procedure) -- the USB-C port is application-only (PA11/PA12 wired to the
# USB peripheral), not a bootloader path.
#
# keep first
board_runner_args(stm32flash "--baud-rate=115200")
board_runner_args(jlink "--device=STM32F103CB" "--speed=4000")

# keep first
include(${ZEPHYR_BASE}/boards/common/openocd-stm32.board.cmake)
include(${ZEPHYR_BASE}/boards/common/stm32flash.board.cmake)
include(${ZEPHYR_BASE}/boards/common/jlink.board.cmake)
