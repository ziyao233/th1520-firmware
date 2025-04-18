#!/usr/bin/env lua5.4

-- SPDX-License-Identifier: GPL-2.0-only
--[[
--	Dirty script for converting calls to dddr_phy{0,1,}_reg_wr() to formatted
--	firmware entries.
--	Copyright (c) 2025 Yao Zi <ziyao@disroot.org>
--]]

for line in io.lines() do
	local op;
	if line:match("ddr_phy1_reg_wr") then
		op = "phy1";
	elseif line:match("ddr_phy0_reg_wr") then
		op = "phy0";
	elseif line:match("ddr_phy_reg_wr") then
		op = "phy";
	else
		error(("Cannot parse the line: %s"):format(line));
	end

	local addr, data = line:match("(0x[0-9a-f]+),(0x[0-9a-f]+)");
	if not addr or not data then
		error(("Cannot parse the line %s"):format(line));
	end

	print(("\t\t{ op = \"%s\", addr = 0x%x, data = 0x%x },"):
	      format(op, addr, data));
end
