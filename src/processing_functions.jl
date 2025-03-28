function gettemp(f)
    a = split(f, ".")
    b = split(a[1], "_")
    return @>> string(b[4]) * "." * String(a[2]) parse(Float64)
end

function getdatetime(f)
    a = split(f, ".")
    b = split(a[1], "_")
    return DateTime(String(b[3]), Dates.DateFormat("yyyymmddTHHMMSS"))
end

function extract_filename_data(bp; warmup = false)
    allfiles = @>> readdir(bp) filter(f -> f[end-2:end] == "jpg")
    allT = map(gettemp, allfiles)
    allDateTime = map(getdatetime, allfiles)
    ii = (warmup == false) ? allT .< 1.0 : ((allT .< 4.0) .& (allT .> -1.0))
    files, t, T = allfiles[ii], allDateTime[ii], allT[ii]
    return files, t, T
end

function get_centers(files, scale)
    im1, im2 = load(files[1]), load(files[end])

    im1f = imfilter(im1, Kernel.gaussian(2.5))
    im2f = imfilter(im2, Kernel.gaussian(2.5))

    b = (Gray.(im1f) - Gray.(im2f))

    edges = detect_edges(b, Canny(spatial_scale = scale))
    dx, dy = imgradients(b, KernelFactors.ando5)
    iphase = phase(dx, dy)
    centers, radii = hough_circle_gradient(Bool.(edges), iphase, 20:35)
    return centers, radii, im1, edges
end

function drawcircles(centers, image)
    newimage = deepcopy(image)
    map(centers) do c
        ImageDraw.draw!(
            newimage,
            Ellipse(CirclePointRadius(c[2], c[1], 20; thickness = 15, fill = false)),
            RGB{N0f8}(1, 0, 0),
        )
    end
    return restrict(restrict(newimage))
end

function drawlines(ii, ims)
    map(1:length(ii)) do i
        if ii[i] == false
            n = Int(floor((i - 1) / 21)) + 1
            x1 = (i - 1) % 7
            y1 = Int(floor((i - 1) / 7)) % 3
            p1 = CartesianIndex(x1 * 100 + 50, y1 * 400 + 1)
            p2 = CartesianIndex(x1 * 100 + 50, y1 * 400 + 300)
            tmpimg = RGB{N0f8}.(ims[n])
            ImageDraw.draw!(tmpimg, LineSegment(p1, p2), RGB{N0f8}(1, 1, 1))
            ims[n] .= tmpimg
        end
    end
    return nothing
end

function tile_image(image, center; tilesize = 100)
    l_bound = round(center[1] - tilesize / 2)
    r_bound = round(center[1] + tilesize / 2) - 1
    t_bound = round(center[2] - tilesize / 2)
    b_bound = round(center[2] + tilesize / 2) - 1
    n, m = size(image)

    lb = (l_bound < 1) ? 1 : Int(l_bound)
    rb = (r_bound > n) ? n : Int(r_bound)
    tb = (t_bound < 1) ? 1 : Int(t_bound)
    bb = (b_bound > m) ? m : Int(b_bound)

    return Gray.(image[lb:rb, tb:bb])
end

function tile_stack(bp, files, centers)
    println("Step 2: Loading and tiling files. A progress bar will appear shortly.")

    return @showprogress map(files) do file
        image = load(bp * file)
        tiles = map(center -> tile_image(image, center), centers)
    end
end

findmax(x::Vector{Nothing}) = [nothing, nothing]

function freeze_events(tstack)
    println("Step 3: Searching for freeze events.")

    function morphology(im1, im2)
        ii = abs.(Float64.(im1) .- Float64.(im2)) .> 0.05
        bg = zeros(100, 100)
        bg[ii] .= 1
        return sum(bg)
    end

    return @showprogress map(1:length(tstack[1])) do j
        f = map(i -> morphology(tstack[i][j], tstack[i+1][j]), 1:length(tstack)-1)
        Base.findmax(f[.~isnothing.(f)])[2]
    end
end

function parsestack(freezeindex)
    map(1:length(freezeindex)) do i
        try
            hcat(
                tstack[freezeindex[i]-2][i],
                tstack[freezeindex[i]][i],
                tstack[freezeindex[i]+2][i],
            )
        catch
            Gray.(zeros(100, 300))
        end
    end
end

function validatestack(freezeindex; j = 7)
    st = parsestack(freezeindex)
    n = length(st)
    ims = map(0:Int(floor(n / j))) do k
        i = (k + 1) * j > n ? n : (k + 1) * j
        if k * j + 1 <= i
            whitetiles = mapfoldl(x -> Gray.(ones(100, 100)), vcat, (k*j+1):i)
            im = hcat(vcat(st[(k*j+1):i]...), whitetiles)
        else
            im = mapfoldl(x -> Gray.(ones(100, 100)), vcat, 1:j)
        end
        a, b = size(im)
        if a < j * 100
            im = vcat(im, Gray.(ones(j * 100 - a, 400)))
        end
        im
    end

    n = length(ims)
    return map(1:3:n) do i
        if (i + 3 - 1) < n
            hcat(ims[i:i+3-1]...)
        else
            tmp = hcat(ims[i:end]...)
            a, b = size(tmp)
            hcat(tmp, Gray.(ones(j * 100, 1200 - b)))
        end
    end
end

function INP(T, Vdrop)
    f = collect(1:length(T)) ./ length(T)
    I = (-1.0 .* (log.(1.0 .- f))) ./ Vdrop
    Cin = I ./ 1.0
    return DataFrame(T = reverse(sort(T)), f = f, Cin = Cin)
end
