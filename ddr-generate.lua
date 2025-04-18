#!/usr/bin/env lua5.4
-- SPDX-License-Identifier: GPL-2.0-only
--[[
--	ddr-generate.lua
--	Script to generate TH1520 DDR firmwares used by mainline U-Boot
--	Copyright (c) 2025 Yao Zi <ziyao@disroot.org>
--]]

local string		= require "string";
local table		= require "table";
local io		= require "io";

local src = assert(dofile(assert(arg[1]), 'r'));
local buf = {};

local function
append(data)
	table.insert(buf, data);
end

--[[
	File Format: all fields are in little-endian

struct th1520_ddr_fw {
	uint64_t magic;		// "\x48\x54\x41\x45\x44\x44\x52\x44"
				// ("THEADDDR")
	#define DDR_MAGIC		0x4452444445415448

	uint8_t type;
	#define DDR_TYPE_LPDDR4		0
	#define DDR_TYPE_LPDDR4X	1

	uint8_t ranknum;
	uint8_t bitwidth;
	uint8_t freq;
	#define DDR_FREQ_2133		0
	#define DDR_FREQ_3200		1
	#define DDR_FREQ_3733		2
	#define DDR_FREQ_4266		3

	uint8_t reserved[8];

	uint32_t cfgnum;
	union th1520_ddr_cfg {
		uint32_t opaddr;

		#define DDR_CFG_OP_MASK		GENMASK(31, 24)
		#define DDR_CFG_ADDR_MASK	GENMASK(23, 0)

		#define TH1520_DDR_CFG_PHY0	0
		#define TH1520_DDR_CFG_PHY1	1
		#define TH1520_DDR_CFG_PHY	2
		#define TH1520_DDR_CFG_WAITFW0	4
		#define TH1520_DDR_CFG_WAITFW1	5

		struct th1520_ddr_phy {
			uint32_t opaddr;
			uint16_t data;
		} phy;

		#define TH1520_DDR_CFG_RANGE	3
		struct th1520_ddr_range {
			uint32_t opaddr;
			uint32_t num;
			uint16_t data[];
		} range;
	} cfg[];
};
--]]

local ddrtypes = {
	["lpddr4"]	= 0,
	["lpddr4x"]	= 1,
};
local ddrtype = assert(ddrtypes[src.type]);

assert(src.ranknum == 1 or src.ranknum == 2);

assert(src.bitwidth == 32 or src.bitwidth == 64);

local ddrfreqs = {
	[2166]		= 0,
	[3200]		= 1,
	[3733]		= 2,
	[4266]		= 3,
};
local ddrfreq = assert(ddrfreqs[src.freq]);

append(("<c8 I1 I1 I1 I1 xxxxxxxxI4"):
       pack("THEADDDR", ddrtype, src.ranknum, src.bitwidth, ddrfreq, #src.cfg));

local ddrcfgs = {
	["phy0"]	= function(cfg)
		append(("<I4I2"):pack(0 << 24 | cfg.addr, cfg.data));
	end,
	["phy1"]	= function(cfg)
		append(("<I4I2"):pack(1 << 24 | cfg.addr, cfg.data));
	end,
	["phy"]	= function(cfg)
		append(("<I4I2"):pack(2 << 24 | cfg.addr, cfg.data));
	end,
	["range"] = function(cfg)
		append(("<I4I4"):pack(3 << 24 | cfg.addr, #cfg.data));

		for _, d in ipairs(cfg.data) do
			append(("<I2"):pack(d));
		end
	end,
	["waitphy0"] = function(cfg)
		append(("<I4I2"):pack(4 << 24, 0));
	end,
	["waitphy1"] = function(cfg)
		append(("<I4I2"):pack(5 << 24, 0));
	end,
};

for _, cfg in ipairs(src.cfg) do
	ddrcfgs[cfg.op](cfg);
end

assert(io.open(arg[2], 'w')):write(table.concat(buf));
