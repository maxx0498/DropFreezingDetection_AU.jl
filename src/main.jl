using Gtk
using GtkReactive
using Colors
using Statistics
using Dates
using CSV
using DataFrames
using FileIO
using Printf
using Plots
using Plots.PlotMeasures
using Images
using ImageDraw
using ImageFiltering
using ImageEdgeDetection
using ImageBinarization
using ImageFeatures
using JpegTurbo
using NearestNeighbors
using ProgressMeter
using Lazy: @>, @>>

import Base.findmax

include("processing_functions.jl")

dir = Signal("")
operator = Signal("")
sample = Signal("")
date = Signal(Date(2000, 1, 1))
dropV = Signal(1.0)
cr = Signal(1.0)

include("greeter.jl")

bp = dir.value * "/"
files, t, T = extract_filename_data(bp)      # get selected files, times, and temperatures

include("dropdetection.jl")

tstack = tile_stack(bp, files, centers)      # make tile stack and write summary figure
freezeindex = freeze_events(tstack)          # find freeze events in each stack
triplets = parsestack(freezeindex)           # stack of triplet validation images
ii = trues(length(freezeindex))              # Include list
ims = validatestack(freezeindex)             # frames for validation in GUI

include("dropvalidation.jl")

# Level 2 output data
a = split(bp, "/")
outpath = mapfoldl(i -> String(a[i])*"/", *, 1:length(a)-3) * "level 2/" * String(a[end-1]) * "/"
read(`mkdir -p $outpath`)
ts = t[freezeindex[ii.==true]]
Ts = T[freezeindex[ii.==true]]
cs = centers[ii.==true]

summary_image = map(i -> hcat(i...), tstack) |> x -> vcat(x...)
discardedimg = vcat(triplets[ii.==false]...)
acceptimg = vcat(triplets[ii.==true]...)
xs = map(c -> c[1], cs)
ys = map(c -> c[2], cs) 
df = @> DataFrame(T = Ts, timestamp = ts, xpos = xs, ypos = ys) sort(rev = true)

inp = INP(Ts, dropV.value)
p1 = plot(inp.T, inp.Cin, yscale = :log10, ylim = (1e3, 1e7), xlim = (-35, 0), color = :black, label = "", xlabel = "Temperature (°C)", ylabel = "INP (# L⁻¹)")
p2 = plot(inp.T, inp.f, xlim = (-35, 0), xlabel = "Temperature (°C)", ylabel = "Activated fraction (-)", color = :black, label = "")
p = plot(p1, p2, layout = grid(1,2), size = (700,300), left_margin = 20px, bottom_margin = 20px, left_largin = 10px)

minipath = split(dir.value, "/") |> x -> String(x[end-1]) * "/" * String(x[end])

open(outpath*"metadata.txt", "w") do f
    println(f, "NC State Cold-Stage: Metadata File")
    @>> @sprintf("Raw Data Directory: %s", minipath) println(f)
    @>> @sprintf("Sample Description: %s", sample.value) println(f)
    @>> @sprintf("Data Originator: %s", operator.value) println(f)
    @>> @sprintf("Date Collected: %s", Dates.format(date.value, "yyyy-mm-dd")) println(f)
    @>> @sprintf("Stage Cooling Rate: %.1f K/min", cr.value) println(f)
    @>> @sprintf("Drop Volume: %.1e L", dropV.value) println(f)
    @>> @sprintf("Number Accepted Drops: %i", length(Ts)) println(f)
end

FileIO.save(outpath*"dropmoasic.jpg", summary_image)
FileIO.save(outpath*"dropcenters.jpg", drawcircles(cs, image))
FileIO.save(outpath*"accepteddrops.jpg", acceptimg)
if size(discardedimg)[1] > 10
    FileIO.save(outpath*"discardedrops.jpg", discardedimg)
end
df |> CSV.write(outpath*"dropdata.csv")
inp |> CSV.write(outpath*"spectrum.csv")
savefig(p, outpath*"quicklook.png")

include("exit.jl")
