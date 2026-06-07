hl.monitor({
    output = "eDP-1",
    mode = "2880x1920@120",
    position = "0x0",
    scale= 1.33334
})

hl.config({
    xwayland = {
      force_zero_scaling = true
    }
})

hl.env("GDK_SCALE","2")
hl.env("XCURSOR_SIZE","32")