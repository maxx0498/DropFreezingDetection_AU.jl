println("Step 0: Welcome. Please use the GUI to enter the metadata")
Godot = @task _ -> false
gui = GtkBuilder(filename = "../gui/greeter.glade")
wnd = gui["main"]
cyear, cmonth, cday = year(now()), month(now()) - 1, day(now())
set_gtk_property!(gui["datecollected"], :year, cyear)
set_gtk_property!(gui["datecollected"], :month, cmonth)
set_gtk_property!(gui["datecollected"], :day, cday)
Gtk.showall(wnd)

signal_connect(gui["directorybutton"], "button-press-event") do widget, event
    dir = open_dialog("Select Dataset Folder", action = GtkFileChooserAction.SELECT_FOLDER)
    set_gtk_property!(gui["directory"], :text, dir)
end

signal_connect(gui["done"], "button-press-event") do widget, event
    syear = get_gtk_property(gui["datecollected"], :year, Int)
    smonth = get_gtk_property(gui["datecollected"], :month, Int) + 1
    sday = get_gtk_property(gui["datecollected"], :day, Int)
    sdir = get_gtk_property(gui["directory"], :text, String)
    soperator = get_gtk_property(gui["operator"], :text, String)
    stag = get_gtk_property(gui["sampletag"], :text, String)
    svolume = @>> get_gtk_property(gui["dropvolume"], :text, String) parse(Float64)
    scr = @>> get_gtk_property(gui["coolingrat"], :text, String) parse(Float64)
    push!(dropV, svolume)
    push!(cr, scr)
    push!(operator, soperator)
    push!(date, Date(syear, smonth, sday))
    push!(dir, sdir)
    push!(sample, stag)
    schedule(Godot)
    nothing
end

wait(Godot)
destroy(wnd)
sleep(1)
