using NCDatasets

# data folders
data_folder = "/central/scratch/bischtob/gcm_dcmip31/netcdf/"
combined_file = "/central/scratch/bischtob/gcm_dcmip31/netcdf/combined.nc"
analysis_folder = "/central/scratch/bischtob/gcm_dcmip31/analysis/"

# check if combined file extist, otherwise create it
if !isfile(combined_file)
    files = sort(readdir(data_folder, join=true))
    ds_out = NCDataset(combined_file, "c")

    # Set up two distinct variable classes as they have
    # different sizes
    ds =   ds = NCDataset(files[1], "r")
    vars_grid = ["long", "lat", "level"]
    vars_physical = setdiff(keys(ds), vars_grid)

    # Dimensions from grid variables
    for var in vars_grid
        ds_out.dim[var] = length(ds[var])
    end

    # Declare & fill grid variables
    for var in vars_grid
        ncvar = defVar(ds_out, var, eltype(ds[var]), (var,), attrib=ds[var].attrib)
        ncvar[:] = ds[var][:]
    end

    # Read and aggregate physical variables
    var_dict = Dict(var => [] for var in vars_physical)
    for file in files
        ds_tmp = NCDataset(file, "r")
        for var in vars_physical
            push!(var_dict[var], ds_tmp[var][:])
        end
    end
    var_dict = Dict(var => vcat(var_dict[var]...) for var in vars_physical)

    # Set time dimension, declare & fill time variable
    var = "time"
    ds_out.dim[var] = length(var_dict[var])
    ncvar = defVar(ds_out, var, eltype(ds[var]), (var,), attrib=ds[var].attrib)
    ncvar[:] = var_dict[var]

    # Declare & fill physical variables
    for var in setdiff(vars_physical, ["time"])
        ncvar = defVar(ds_out, var, eltype(ds[var]), ("time", "long", "lat", "level"), attrib=ds[var].attrib)
        ncvar[:] = var_dict[var]
    end
end
