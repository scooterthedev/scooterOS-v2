SECTIONS
{
    . = 0x7C00;
    .boot : { *(.boot) }
    
    . = 0x1000;
    .kernel : { *(.kernel) }
}
