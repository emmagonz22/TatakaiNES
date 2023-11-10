

.export background
.proc background

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

.incbin "background.chr"