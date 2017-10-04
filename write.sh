avrdude -c usbasp -p t2313 -B 10 -U flash:w:lutilo.hex:i
# B (us) > 1 / freq * 4
# -U lfuse:w:0x42:m
# -V - don't verify
# E:FF, H:DF, L:46 - internal 128 kHz osc / 8 = 16 kHz
# E:FF, H:DF, L:C6 - internal 128 kHz osc
# E:FF, H:DF, L:42 - internal 4 MHz / 8 osc = 500 kHz
# E:FF, H:DF, L:C4 - internal 8 MHz osc
# E:FF, H:DF, L:DD - external 3-8 MHz osc
