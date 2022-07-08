using PackageCompiler

create_sysimage(
    [
        :Colors,
        :Statistics,
        :Dates,
        :CSV,
        :DataFrames,
        :FileIO,
        :Printf,
        :Plots,
        :Images,
        :ImageDraw,
        :ImageFiltering,
        :ImageEdgeDetection,
        :ImageBinarization,
        :ImageFeatures,
        :JpegTurbo,
        :NearestNeighbors,
        :ProgressMeter,
        :Lazy,
    ],
    sysimage_path = "sys_daq.so",
    precompile_execution_file="main.jl"
)
