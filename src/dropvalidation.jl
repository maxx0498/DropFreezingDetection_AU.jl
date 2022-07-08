Godot = @task _ -> false

gui = GtkBuilder(filename = "../gui/validate.glade")

cvs = gui["Image"]
wnd = gui["main"]
c = canvas(UserUnit)
push!(cvs, c)
Gtk.showall(wnd)

imgsig = Signal(ims[1])
redraw = Gtk.draw(c, imgsig) do cnvs, image
    copy!(cnvs, image)
end

nframes = length(ims)
set_gtk_property!(gui["adjustment1"], :upper, nframes)
frame = gui["frame"]
signal_connect(frame, "changed") do widget, others...
    x = get_gtk_property(frame, :value, Int)
    push!(imgsig, ims[x])
end

clickevent = Signal(CartesianIndex(0, 0))
n = Signal(1)
signal_connect(cvs, "button-press-event") do widget, event
    xin = Int(round(event.x))
    yin = Int(round(event.y))
    if (clickevent.value[1] ≠ 0) && (clickevent.value[2] ≠ 0)
        nframe = get_gtk_property(frame, :value, Int)
        base = (nframe - 1) * 3 * 7
        k = base + Int(ceil(yin / 100)) + (Int(ceil(xin / 400)) - 1) * 7
        global ims = validatestack(freezeindex)
        if get_gtk_property(gui["adddrops"], :state, Bool) == false
            ii[k] = false
        else
            ii[k] = true
        end
        drawlines(ii, ims)
        x = get_gtk_property(frame, :value, Int)
        push!(imgsig, ims[x])
    end
    push!(clickevent, CartesianIndex(xin, yin))
end

fb = gui["finishbutton"]
signal_connect(fb, "clicked") do widget, others...
    destroy(wnd)
    schedule(Godot)
end

wnd1 = gui["help"]
hb =  gui["helpbutton"]
signal_connect(hb, "clicked") do widget, others...
    showall(wnd1)
end

he = gui["helpexit"]
signal_connect(he, "clicked") do widget, others...
    hide(wnd1)
end

wait(Godot)
