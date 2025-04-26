# TH1520 Firmware Collection

This repository collects misc firmwares for TH1520 SoC, most cleaned up from
vendor source code. Currently it contains,

- DDR controller firmware

## DDR controller

The DDR controller supports various configurations of ranks and interface
bitwidth, which requires different firmwares to function,

- Dual-rank LPDDR4X running at 3733MHz, shipped by
  - Sipeed Lichee Pi 4A with 16GiB RAM
  - Milk-V Meles with 16GiB RAM
  - `src/lpddr4x-3733-dualrank.lua`


### Building

With Lua 5.4 installed, run

```shell
$ lua5.4 ddr-generate.lua <FIRMARE_SRC> <OUTPUT_BINARY>
```

e.g.

```shell
$ lua5.4 ddr-generate.lua src/lpddr4x-3733-dualrank.lua lpddr4x-3733-dualrank.bin
```

DDR firmwares are extracted from PHY initialization code of vendor U-Boot,
which contains both misc register configuration and firmware for PHY
Microcontroller Unit (PMU).

Note: PMU is a special ARCv2 MCU integrated in the DDR controller. It runs
two different programs to train the PHY twice, called 1D and 2D training.
