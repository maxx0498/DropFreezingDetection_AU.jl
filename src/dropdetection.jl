Godot = @task _ -> false

gui = GtkBuilder(filename = "../gui/centers.glade")  # Load GUI

cvs = gui["Image"]
cvs1 = gui["Image1"]
wnd = gui["main"]
c = canvas(UserUnit)
d = canvas(UserUnit)

push!(cvs, c)
push!(cvs1, d)

imgsig = Signal(RGB.(rand(100,100)))
redraw = Gtk.draw(c, imgsig) do cnvs, image
    copy!(cnvs, image)
    :DONE  # 
end

imgsig1 = Signal(Gray.(rand(100,100)))
redraw1 = Gtk.draw(d, imgsig1) do cnvs, image
    copy!(cnvs, image)
    :DONE  # 
end

recalcevent = Signal(1)

fff = map(recalcevent) do _
    sleep(1)
    println("Step 1: Calculating drop centers. Please be patient.")
    scale = get_gtk_property(gui["scale"], :value, Float64)
    global centers, radii, image, edges = get_centers(bp .*  files, scale)
    push!(imgsig, drawcircles(centers, image))
    push!(imgsig1, edges)
    showall(wnd)
end

Gtk.showall(wnd)

clickevent = Signal(CartesianIndex(0, 0))
pb = map(clickevent) do c
    coords = CartesianIndex(Int(round(4.0 * c[2])), Int(round(4.0 * c[1])))
    if get_gtk_property(gui["adddrops"], :state, Bool) == true
        push!(centers, coords)
    else
        x, y = map(x -> x[2], centers), map(x -> x[1], centers)
        kdtree = KDTree(1.0 .* hcat(x, y)')
        idx, dists = nn(kdtree, [coords[2], coords[1]])
        deleteat!(centers, idx)
    end
    push!(imgsig, drawcircles(centers, image))
    :DONE
end
deleteat!(centers, length(centers))

signal_connect(cvs, "button-press-event") do widget, event
    push!(clickevent, CartesianIndex(Int(round(event.x)), Int(round(event.y))))
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

da = gui["deleteall"]
signal_connect(da, "clicked") do widget, others...
    deleteat!(centers, 1:length(centers))
    push!(imgsig, image)
end

rb = gui["recalculate"]
signal_connect(rb, "clicked") do widget, others...
   hide(wnd)
   push!(recalcevent, 2)
end

wait(Godot)
