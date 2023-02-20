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
using Interpolations
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

if Sys.iswindows()
    bp = dir.value * "\\"
else
    bp = dir.value * "/"
end

files, t, T = extract_filename_data(bp; warmup = true)      # get selected files, times, and temperatures

include("dropdetection.jl")

tstack = tile_stack(bp, files, centers)      # make tile stack and write summary figure
cs = centers

ims = mapreduce(vcat, 1:length(tstack[1])) do j
    mapreduce(i -> tstack[i][j], hcat, 1:length(t))
end
n,m = size(ims)
itp = interpolate((T,), 100*(0:length(T)-1),  Gridded(Linear()))
extp = extrapolate(itp, Line())


# Level 2 output data
if Sys.iswindows()
    a = split(bp, "\\")
    outpath =
        mapfoldl(i -> String(a[i]) * "\\", *, 1:length(a)-3) *
        "level 2\\" *
        String(a[end-1]) *
        "\\"
    minipath = split(dir.value, "\\") |> x -> String(x[end-1]) * "\\" * String(x[end])
else
    a = split(bp, "/")
    outpath =
        mapfoldl(i -> String(a[i]) * "/", *, 1:length(a)-3) *
        "level 2/" *
        String(a[end-1]) *
        "/"
    minipath = split(dir.value, "/") |> x -> String(x[end-1]) * "/" * String(x[end])
end

read(`mkdir -p $outpath`)
xt = [-2, -1,0,1,2,3,4]
p = plot(ims, xticks = (extp(xt), xt), yticks = ([0], ""), xlabel = "Temperature (°C)", size = (m,n+250), bottom_margin = 250px,xtickfontsize=72, xlabelfontsize = 72)
savefig(p, outpath * "quicklook.png")
FileIO.save(outpath * "dropcenters.jpg", drawcircles(cs, image))