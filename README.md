# custom_zephyr_boards

Out-of-tree Zephyr board definitions, used as an ESPHome `zephyr: board_source:`
root so a board works with the stock Zephyr SDK -- no need to fork or patch
Zephyr itself.

This repo is currently empty of actual boards. A board that only differs from
an existing upstream board by a Kconfig/devicetree default -- a corrected
partition table, for example -- doesn't need a board definition at all; it
can be handled directly in ESPHome config via `zephyr: overlays:` (see the
[Zephyr platform docs](https://esphome.io/components/zephyr/#overlays)),
which patches a stock upstream board's devicetree without needing anything
in this repo. Prefer `overlays:` for a partition-table change, a devicetree
node the stock board doesn't declare, or any other Kconfig/devicetree-only
difference from an existing upstream board.

## When a board belongs here instead

`overlays:` can only patch what's already declared somewhere in a board's
devicetree -- it can't invent new hardware. A board belongs in this repo
when it's *not* just a config-default difference from an existing upstream
board, for example:

- A chip mainline Zephyr doesn't support yet.
- A genuinely different pin-control/pinmux scheme, not just a different
  peripheral enabled or disabled.
- Vendor peripherals absent from mainline Zephyr entirely.

If you're unsure which case you're in, check whether the delta could be
expressed as devicetree overlay text (`/delete-node/` plus a redefinition,
or a new node under an existing bus) -- if so, it belongs in ESPHome's
`overlays:`, not here.

## Usage

Point an ESPHome `zephyr: board_source:` at this repo and select a board by
name:

```yaml
zephyr:
  variant: ESP32
  board: my_custom_board
  board_source:
    type: local
    path: /home/me/custom_zephyr_boards
```

## Adding a board

Each board directory follows Zephyr's standard board-porting layout:

```
boards/<vendor>/<board>/
├── board.yml
├── board.cmake
├── Kconfig
├── Kconfig.<board>
├── Kconfig.sysbuild
├── <board>_<qualifier>.dts
├── <board>_<qualifier>.yaml
├── <board>_<qualifier>_defconfig
├── <board>-pinctrl.dtsi
└── support/
    └── openocd.cfg
```

- **board.yml**: Board identity -- name, vendor, the SoC(s) it targets, and any qualifiers
  (e.g. `procpu`/`appcpu` for an AMP core split).
- **board.cmake**: How `west flash`/`west debug` talk to the board (runner selection, e.g. `openocd`
  or `jlink`).
- **Kconfig / Kconfig.\<board\> / Kconfig.sysbuild**: Board-level Kconfig defaults. `Kconfig.sysbuild`
  sets sysbuild-level choices (e.g. `BOOTLOADER_MCUBOOT` as the default bootloader for this board).
- **\<board\>_\<qualifier\>.dts**: The board's devicetree -- SoC dtsi include, pin assignments,
  peripheral `status`/`chosen` nodes, and the flash partition table.
- **\<board\>_\<qualifier\>.yaml**: Board metadata Zephyr's build system reads (RAM/flash size, supported
  features) -- distinct from `board.yml`, which is west's own board-identity file.
- **\<board\>_\<qualifier\>_defconfig**: Kconfig defaults specific to this board target, layered on top
  of `Kconfig.defconfig`.
- **\<board\>-pinctrl.dtsi**: Pin-control (`pinctrl`) node definitions referenced by the main `.dts`.
- **support/openocd.cfg**: OpenOCD configuration, if the board uses OpenOCD as its flash/debug runner.

A board here should be a drop-in replacement for the closest matching upstream board where one exists
-- same SoC, only the parts that genuinely differ (pinctrl, missing Kconfig symbols, vendor drivers)
need their own files.
