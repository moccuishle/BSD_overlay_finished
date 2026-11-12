/* kernel.ld - link the BSD45 kernel as a plain ELF32 at KERNBASE. */
ENTRY(start)
SECTIONS
{
    . = 0xFE001000;
    .text : {
        *(.text*)
    }
    _etext = .;
    . = ALIGN(4096);
    .data : {
        *(.data*)
        *(.rodata*)
        *(.rdata*)
    }
    _edata = .;
    . = ALIGN(4096);
    .bss : {
        *(.bss*)
        *(COMMON)
    }
    _end = .;
}
