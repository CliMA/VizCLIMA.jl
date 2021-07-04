import numpy as np
import netCDF4 as nc
import argparse
import os

"""
Apr30 2020
collect_stats.py loops in the output directory "path" and collects all
netDCF files for a given diagnostics into a single netDCF file named:
Stats.diagnstic_type.simname.nc
here diagnstic_type is the key word diagnostic type that appears in the output files,
simname is the simualtion name (HelzSouarez, Bomex ..)

EXAMPLE:
                   diagnstic_type   path
python collect_stats.py Default     /Users/yaircohen/Documents/CLIMA_out/CLIMA_PyCLES_LES/Bomex/
"""

def main():
    parser = argparse.ArgumentParser(prog='CLIMA')
    parser.add_argument("diagnstic_type")
    parser.add_argument("path")
    args = parser.parse_args()
    diagnstic_type = args.diagnstic_type
    directory = args.path
    varlist = {}
    shapelist = {}
    file_list = os.listdir(directory)
    num_files = -1
    # loop to get the length of the simtime as the number of files in the diagnostic_type
    for filename in sorted(os.listdir(directory)):
        if filename.endswith(".nc") and diagnstic_type in filename:
            num_files += 1

    # get the list of variables and thier shapes from the first file in the diagnostic type
    for filename in sorted(os.listdir(directory)):
        if filename.endswith(".nc") and diagnstic_type in filename:
            fullfilename = directory+filename
            data = nc.Dataset(fullfilename, 'r')
            _z  = data.variables['z']
            _t  = data.variables['simtime']
            num_files = np.max([num_files,float(filename[-5:-3])])
            for varname in data.variables:
                varlist = np.append(varlist,varname)
                shapelist = np.append(shapelist,np.shape(data.variables[varname])[0])
            break

    varlist = varlist[1:]
    shapelist = shapelist[1:]
    s = filename.find('_')
    outputname = directory+'Stats.'+filename[0:s]+'.'+diagnstic_type+'.nc'
    output = nc.Dataset(outputname, "w", format="NETCDF4")
    output.createDimension('z', len(_z))
    output.createDimension('t',num_files)
    output.createGroup("variables")
    profiles_grp = output.groups["variables"]

    for i in range(len(varlist)):
        varname = varlist[i]
        varshape = shapelist[i]
        if varname == 'z':
            data1 = nc.Dataset(directory+file_list[-3],'r')
            z = profiles_grp.createVariable(varname,'f4',('z'))
            _z = data1.variables['z']
            z[:] = _z[:]
        else:
            add_var_netcdf(varname,directory,profiles_grp,output, varshape, outputname, diagnstic_type)

    output.close()

def add_var_netcdf(varname,directory,profiles_grp,output, varshape, outputname, diagnstic_type):

    J=0.0
    if varshape>1:
        tmpvar = profiles_grp.createVariable(varname,'f4',('t','z'))
        file_list = os.listdir(directory)
        for filename in sorted(os.listdir(directory)):
            if filename.endswith(".nc") and filename != outputname and diagnstic_type in filename:
                fullfilename = directory+filename
                data = nc.Dataset(fullfilename, 'r')
                try:
                    var = data.variables[varname]
                    if J==0.0:
                        _tmpvar = var
                        J +=1.0
                    else:
                        _tmpvar = np.vstack([_tmpvar ,var])
                        J +=1.0
                except:
                    pass
        tmpvar[:,:] = _tmpvar[:,:]

    else:
        tmpvar = profiles_grp.createVariable(varname,'f4',('t'))
        file_list = os.listdir(directory)
        for filename in sorted(os.listdir(directory)):
            if filename.endswith(".nc") and filename != outputname and diagnstic_type in filename:
                fullfilename = directory+filename
                data = nc.Dataset(fullfilename, 'r')
                try:
                    var = data.variables[varname]
                    if J==0.0:
                        _tmpvar = var
                        J +=1.0
                    else:
                        _tmpvar = np.hstack([_tmpvar ,var])
                        J +=1.0
                except:
                    pass
        tmpvar[:] = _tmpvar[:]
    return

if __name__ == '__main__':
    main()