# Standalone VizCLIMA scripts

Here are some examples for stand-alone analysis of `.nc` output:
- General
    - file load & info print ([.jl](https://github.com/LenkaNovak/LenkaNovak.github.io/blob/master/files/gcm-energy-spectra.jl#L37-L41))
    - file splitting ([.jl](https://github.com/LenkaNovak/LenkaNovak.github.io/blob/master/files/extract_subsets_of_ncfiles.jl))
    - performance info table ([.jl](https://github.com/CliMA/VizCLIMA.jl/blob/ln/prep-for-merge/src/scripts/bmark_sweep_targetted_vars_raw.jl#L184-L209))
- GCM
    - basic averaging and slicing([.jl](https://github.com/CliMA/VizCLIMA.jl/blob/ln/prep-for-merge/src/scripts/general-gcm-notebook-setup.jl), [.ipynb](https://github.com/LenkaNovak/LenkaNovak.github.io/blob/master/files/general-gcm-notebook-setup.ipynb))
    - differences between experiments ([.jl](https://github.com/CliMA/VizCLIMA.jl/blob/ln/prep-for-merge/src/scripts/general-gcm-notebook-setup-multi.jl), [.ipynb](https://github.com/LenkaNovak/LenkaNovak.github.io/blob/master/files/general-gcm-notebook-setup-multi.ipynb))
    - 1D and 2D energy spectra ([.jl](https://github.com/LenkaNovak/LenkaNovak.github.io/blob/master/files/gcm-energy-spectra.jl), [.ipynb](https://github.com/LenkaNovak/LenkaNovak.github.io/blob/master/files/spectra_testdel.ipynb))
    - animation: LES simple ([.jl](https://github.com/LenkaNovak/LenkaNovak.github.io/blob/master/files/les-simple-animation.jl), [.ipynb](https://github.com/LenkaNovak/LenkaNovak.github.io/blob/master/files/les-simple-animation.ipynb))
    - animation: multi-run GCM comparisons ([.jl](https://github.com/CliMA/VizCLIMA.jl/blob/ln/prep-for-merge/src/scripts/hier_analysis_bcwave.jl#L97-L133))

- LES
    - vertical profiles ([.jl](https://github.com/CliMA/VizCLIMA.jl/blob/ln/prep-for-merge/src/scripts/default_moist_les.jl))
    - 3D energy spectrum ([.jl](https://github.com/CliMA/VizCLIMA.jl/blob/ln/prep-for-merge/src/scripts/taylorgreen_spectrum.jl))

To apply a Julia script on ClimateMachine.jl output, and convert it into a Jupyter Notebook using Literate, run:

```
VIZCLIMA_HOME=<location-of-your-VizCLIMA.jl>
VIZCLIMA_SCRIPT=<your-VizCLIMA.jl-script>
CLIMA_ANALYSIS=<location-of-your-NetCDF-file(s)>

julia --project=$VIZCLIMA_HOME -e 'using Pkg; Pkg.instantiate(); Pkg.API.precompile()'
VIZCLIMA_LITERATE=$VIZCLIMA_HOME'/src/utils/make_literate.jl'
julia --project=$VIZCLIMA_HOME $VIZCLIMA_LITERATE --input-file $CLIMA_ANALYSIS/$VIZCLIMA_SCRIPT --output-dir $CLIMA_ANALYSIS
```

