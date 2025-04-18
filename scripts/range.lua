#!/usr/bin/env lua5.4

-- SPDX-License-Identifier: GPL-2.0-only
--[[
--	Dirty script for converting large arrays (iccm and dccm data) with
--	format like
--		const short int iccm_array[] = {
--		0x114,
--		0x514,
--		};
--	to a formatted Lua array.
--
--	Copyright (c) 2025 Yao Zi <ziyao@disroot.org>
--]]

local width = 0;
io.stdout:write "\t\t\t\t";
for line in io.stdin:lines() do
	local data = line:match("(0x[0-9a-z]+),");
	assert(data, ("failed to parse line '%s'"):format(line));

	io.stdout:write(data);
	if width ~= 0 and width % 6 == 0 then
		io.stdout:write ",\n\t\t\t\t";
	else
		io.stdout:write ", ";
	end
	width = width + 1;
end
io.stdout:write '\n';
