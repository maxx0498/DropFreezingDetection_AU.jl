Godot = @task _ -> false

gui = GtkBuilder(filename = "../gui/exit.glade")

cvs = gui["Image"]
wnd = gui["main"]
c = canvas(UserUnit)
push!(cvs, c)
Gtk.showall(wnd)

figimg = load(outpath*"quicklook.png")
imgsig = Signal(figimg)
redraw = Gtk.draw(c, imgsig) do cnvs, image
    copy!(cnvs, image)
end

fb = gui["finishbutton"]
signal_connect(fb, "clicked") do widget, others...
    destroy(wnd)
    schedule(Godot)
end

wait(Godot)
