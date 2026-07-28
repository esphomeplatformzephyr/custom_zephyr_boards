# custom_zephyr_boards

Out-of-tree Zephyr board definitions, used as an ESPHome `zephyr: board_source:`
root so these boards work with the stock Zephyr SDK -- no need to fork or patch
Zephyr itself.

## Usage

Point an ESPHome `platform: zephyr` config at this repo and select one of the
boards below by name:

```yaml
zephyr:
  variant: ESP32
  board: esp32_devkit_procpu_only
  board_source:
    type: local
    path: /home/mc/dev/custom_zephyr_boards
```

Each board directory follows Zephyr's standard board-porting layout
(`board.yml`, `Kconfig`, `Kconfig.<board>`, `Kconfig.sysbuild`, `board.cmake`,
`<board>_<qualifier>.{dts,yaml,defconfig}`, pinctrl `.dtsi`,
`support/openocd.cfg`), so each one is a drop-in replacement for the matching
upstream board -- same SoC and hardware, just a different Kconfig/devicetree
default that upstream doesn't ship.

## Boards

### esp32_devkit_procpu_only

Same hardware as upstream's `esp32_devkitc`, but with a single, unified flash
partition table instead of upstream's default AMP layout (which splits flash
into separate procpu/appcpu partitions for two independent firmware images).
ESPHome only ever builds one firmware image, for the PRO_CPU -- the original
ESP32's second core (APP_CPU) is never started, since Zephyr's `WIFI_ESP32`
driver requires `!SMP` (see upstream issue
[zephyrproject-rtos/zephyr#56011](https://github.com/zephyrproject-rtos/zephyr/issues/56011)
for why SMP has never been reliable on Xtensa ESP32). Using upstream's AMP
partition table would waste flash on an appcpu partition that's never
flashed or used.

### esp32c6_devkitc_n4

Same hardware as upstream's `esp32c6_devkitc`, corrected for the 4MB (N4)
flash SKU. Upstream's board definition assumes a larger flash size; boards
in this repo select `SOC_ESP32_C6_WROOM_1U_N4` so the flash partition table
matches the actual chip.

### adafruit_feather_nrf52840_mcuboot_usb

Same hardware as upstream's `adafruit_feather_nrf52840`, corrected for
MCUboot with USB CDC-ACM serial recovery. Upstream's stock partition table
gives `boot_partition` only 48 KB, which doesn't fit MCUboot once the USB
CDC-ACM stack and ECDSA-P256 signing are linked in (measured overflow during
hardware bring-up was ~12 KB even with ECDSA-P256, which is far smaller than
the default RSA-2048). A 60 KB `boot_partition` (matching the ESP32-family
variants' own convention -- see `partitions_0x1000_default_8M.dtsi`'s
`DT_SIZE_K(60)`) was tried first and confirmed by an actual build to link,
but with only 380 bytes to spare (61,060 / 61,440 bytes, 99.38% used) -- too
thin a margin to be worth saving 4 KB over. `boot_partition` is grown to
64 KB instead, with 8 KB taken from each of the two app slots (`slot0`/
`slot1`, now 464 KB each instead of 472 KB); `storage_partition` is
untouched. No `scratch_partition` is defined -- the `move` and `offset`
MCUboot swap methods don't need one, and this board's default OTA swap
method is `offset`, not `scratch`.

The board also declares a USB CDC-ACM devicetree node (`zephyr,cdc-acm-uart`)
that upstream's board doesn't -- needed for MCUboot's serial recovery to have
something to talk to. This isn't a new pattern: the sibling
`adafruit_itsybitsy_nrf52840` board in mainline Zephyr already ships the same
`#include <../boards/common/usb/cdc_acm_serial.dtsi>` for the same reason.

## Why these aren't upstream Zephyr boards

None of these boards describe different physical hardware from their
upstream counterpart -- each is the same board with a different
Kconfig/devicetree default (partition table layout, flash size). Zephyr's
board-contribution process expects that kind of difference to be a **board
revision** of the existing board (e.g. `esp32_devkitc@procpu_only`), not a
separate board directory -- but a revision has to live inside the same board
directory as the board it revises, which means editing the in-tree
`esp32_devkitc`/`esp32c6_devkitc`/`adafruit_feather_nrf52840` board files
directly. That requires a Zephyr fork, not an out-of-tree `BOARD_ROOT`.
Keeping these as standalone out-of-tree boards here avoids that fork for
what is otherwise a one-file Kconfig/partition difference.
