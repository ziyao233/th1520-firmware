# TH1520 Firmware Collection

This repository collects misc firmwares for TH1520 SoC, most cleaned up from
vendor source code. Currently it contains,

- DDR controller firmware
- AON (Always ON) firmware, running on the E902 core

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

## AON Firmware

Currently AON-firmware-related U-Boot facilities are still working in progress!

The AON firmware implements various functions through mailbox RPC call,
including power-domain-management, PMIC control, watchdog. It also takes care
of the process of suspension and resumption, and thus must be loaded ahead of
the kernel for suspending-to-disk operation.

### Official-Released Binaries

To support different board types with different PMICs with a single binary,
some official AON firmware reserves a configuration header before the real
entry point (offset `0xc00` from the image header), which must be correctly
filled before loading the firmware.

As far as we know, AON firmware that requires a configuration header always
starts with `AON_CONFIG` as file magic, which could be distinguished with

```shell
$ xxd <PATH_TO_AON_FIRMWARE> | head -n 1
```

and checking whether the output contains `AON_CONFIG`.

Since the offical released firmware doesn't come with a clear license that
permits redistribution and modification, no binary derived from it is contained
in this repository. Instead, the script `aon-generate.sh` applies the
configuration header to a firmware, and converts it to ELF format. The result
ELF file has correct program headers and entry address, and is suitable to be
directly loaded to the E902 core.

#### Building

To build the ELF version of AON firmware,

```shell
$ ./aon-generate.sh <BINARY_AON_FIRMWARE> <AON_CONF_PATCH> <OUTPUT_FILE>
```

e.g.

```shell
$ ./aon-generate light_aon_fpga.bin bin/lpi4a-aon.patch.bin lpi4a-aon.elf
```

Configuration of PMIC may vary from board to board, and different configuration
header patch must be used,

- Dual PMIC (`DA9063` + `DA9121`), regulators arranged as on LPi4A board
  - `bin/lpi4a-aon.patch.bin

The script has been tested against firmware binary found at

- [revyos/th1520-boot-firmware](https://github.com/revyos/th1520-boot-firmware):
  compatible
- [XUANTIE-RV/xuantie-yocto](https://github.com/XUANTIE-RV/xuantie-yocto):
  incompatible, this firmware
  (`meta-light/recipes-bsp/opensbi/opensbi/light_aon_fpga.bin`) doesn't even
  use a configuration header.

### Open-Source Firmware Build

Source of the AON firmware has been released
[here](https://github.com/revyos/aon), though without any license information.
Replacing the offical binary with the open-sourced one could be a future work.

### Note about the E902 Co-processor

This is a RV32EMC MMU-less 2-stage in-order core for SoC management purpose,
supporting both machine and user mode. Please ensure you use `E` base
instruction set instead of `I` when building firmware for it.
