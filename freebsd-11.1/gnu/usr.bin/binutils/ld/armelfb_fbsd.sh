# $FreeBSD: stable/11/gnu/usr.bin/binutils/ld/armelfb_fbsd.sh 245101 2013-01-06 07:14:04Z andrew $
#XXX: This should be used once those bits are merged back in the FSF repo.
#. ${srcdir}/emulparams/armelf_fbsd.sh
#
#OUTPUT_FORMAT="elf32-bigarm"
. ${srcdir}/emulparams/armelf.sh
. ${srcdir}/emulparams/elf_fbsd.sh
TARGET2_TYPE=got-rel
MAXPAGESIZE=0x8000
GENERATE_PIE_SCRIPT=yes

unset STACK_ADDR
unset EMBEDDED
OUTPUT_FORMAT="elf32-bigarm"
