#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only

die() {
	echo "$@" 2>&1
	exit 1
}

inputFile="$1"
patchFile="$2"
outputFile="$3"

[ "$inputFile" ] || die "No input file speicifed"
[ "$patchFile" ] || die "No target PT_GNU_STACK size specified"
[ "$outputFile" ] || die "No output file specified"

[ -f "$inputFile" ] || die "$inputFile: No such file or directory"
[ -f "$patchFile" ] || die "$patchFile: No such file or directory"

calc() {
	bc <<-EOF
	$1
	EOF
}

# $1: data as string
# $2: bytes
to_binary_le() {
	_d="$1"
	_i=0
	while [ "$_i" -lt "$2" ]; do
		# shellcheck disable=SC2059
		printf "\x$(calc "obase=16; $_d % 256")"
		_d="$(calc "$_d / 256")"
		_i="$((_i + 1))"
	done
}

# $1: offset
writen() {
	dd of="$outputFile" oflag=direct conv=notrunc bs=1 seek="$1" status=none
}

# typedef struct {
#	unsigned char e_ident[EI_NIDENT];	// 0
#		// EI_CLASS = 4
# 	uint16_t      e_type;			// 16
#	uint16_t      e_machine;		// 18
#	uint32_t      e_version;		// 20
#	ElfN_Addr     e_entry;			// 24
#	ElfN_Off      e_phoff;			// 28
#	ElfN_Off      e_shoff;			// 32
#	uint32_t      e_flags;			// 36
#	uint16_t      e_ehsize;			// 40
#	uint16_t      e_phentsize;		// 42
#	uint16_t      e_phnum;			// 44
#	uint16_t      e_shentsize;		// 46
#	uint16_t      e_shnum;			// 48
#	uint16_t      e_shstrndx;		// 50
# } ElfN_Ehdr;
# sizeof(Elf32_Ehdr) = 52 bytes

echo -ne $'\x7f'"ELF" > $outputFile
echo -ne $'\x1' >> "$outputFile"		# ELFCLASS32
echo -ne $'\x1' >> "$outputFile"		# ELFDATA2LSB
echo -ne $'\x1' >> "$outputFile"		# EV_CURRENT
echo -ne $'\xff' >> "$outputFile"		# ELFOSABI_STANDALONE

to_binary_le 2 2 | writen 16			# ET_EXEC
to_binary_le 243 2 | writen 18			# EM_RISCV
to_binary_le 1 2 | writen 20			# EV_CURRENT
to_binary_le $((0xffef8c00)) 4 | writen 24	# e_entry
to_binary_le 52 4 | writen 28			# e_phoff
to_binary_le 0 4 | writen 32			# e_shoff
to_binary_le 0 4 | writen 36			# e_flags
to_binary_le 52 2 | writen 40			# e_ehsize
to_binary_le 32 2 | writen 42			# e_phentsize
to_binary_le 1 2 | writen 44			# e_phnum
to_binary_le 40 2 | writen 46			# e_shentsize
to_binary_le 0 2 | writen 48			# e_shnum
to_binary_le 0 2 | writen 50			# e_shstrndx

# typedef struct {
#	uint32_t   p_type;		// 0	(52)
#	Elf32_Off  p_offset;		// 4	(56)
#	Elf32_Addr p_vaddr;		// 8	(60)
#	Elf32_Addr p_paddr;		// 12	(64)
#	uint32_t   p_filesz;		// 16	(68)
#	uint32_t   p_memsz;		// 20	(72)
#	uint32_t   p_flags;		// 24	(76)
#	uint32_t   p_align;		// 28	(80)
# } Elf32_Phdr;
# sizeof(Elf32_Phdr) = 32 bytes

inputSize="$(stat -c '%s' "$inputFile")" || die "failed to stat '$inputFile'"

to_binary_le 1 4 | writen 52			# PT_LOAD
to_binary_le 84 4 | writen 56			# p_offset
						# sizeof(Ehdr) + sizeof(Phdr)
to_binary_le $((0xffef8000)) 4 | writen 60	# p_vaddr
to_binary_le $((0xffef8000)) 4 | writen 64	# p_paddr
to_binary_le "$inputSize" 4 | writen 68		# p_filesz
to_binary_le "$inputSize" 4 | writen 72		# p_memsz
to_binary_le 5 4 | writen 76			# PF_R | PF_X
to_binary_le 4096 4 | writen 80			# p_align

cat "$inputFile" >> "$outputFile"
dd if="$patchFile" of="$outputFile" bs=84 seek=1 conv=notrunc status=none
