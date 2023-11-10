

.export background
.proc background
    LoadPaletteData:
        LDA LoadPaletteData, X
        STA $2007
        INX
        CPX #$20
        BNE LoadPaletteData


.endproc

.segment "RODATA"
palettes: 
    .byte $0f, $12, $23, $27
    .byte $0f, $12, $23, $27
    .byte $0f, $12, $23, $27
    .byte $0f, $12, $23, $27

    .byte $0f, $12, $23, $27
    .byte $0f, $12, $23, $27
    .byte $0f, $12, $23, $27
    .byte $0f, $12, $23, $27

sprites:
    .byte $0f, $12, $23, $27
    .byte $0f, $12, $23, $27
    .byte $0f, $12, $23, $27
    .byte $0f, $12, $23, $27


.segment "CHR"
.incbin "background.chr"