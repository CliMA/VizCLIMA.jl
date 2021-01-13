# Third-party Interactive Software

- There are various third party packages that enable instant 3D interactive visualisation, slicing and animations of our data (NetCDF format by default), as well as conversion to other data formats.

## Packages
  - [ParaView](https://www.paraview.org): 3D visualisation, slicing and simple data manipulation, handles VTK files and can convert data to CSV and other formats.
  - [VisIt](https://visitusers.org/index.php?title=Main_Page): similar to ParaView
  - [Panoply](https://www.giss.nasa.gov/tools/panoply/): summarises geospatial information of the global geospatial data
  - [Ncview](http://meteora.ucsd.edu/~pierce/ncview_home_page.html): useful for a quick check of geospatial data on the Caltech cluster. It can handle large data files more easily than most other packages.
  - [Houdini](https://www.sidefx.com/products/houdini/): useful for more sophisticated representation of 3D turbulence and powerful data interpolation. Used by our Hollywood colleagues for CGI.

## Examples from ParaView: Dry Held-Suarez spinup using ClimateMachine.jl (v0.1.0)

![alt text](https://lenkanovak.github.io/images/animated.gif "temperature cross-section with atmosphere thickness blown up")

[link](https://lenkanovak.github.io/images/animated.gif)

![alt text](https://lenkanovak.github.io/images/animated_smoke_3_b.gif "temperature and wind")
[link](https://lenkanovak.github.io/images/animated_smoke_3_b.gif)

![alt text](https://lenkanovak.github.io/images/hairy.gif "snapshot of zonal wind: clip and streamlines")
[link](https://lenkanovak.github.io/images/hairy.gif)

## Example from Houdini: Cumulus cloud simulating the BOMEX case using ClimateMachine.jl (v0.1.0)
![alt text](https://lenkanovak.github.io/images/houdini.mp4 "BOMEX simulation: data from Akshay Sridhar")
[link](https://lenkanovak.github.io/images/houdini.mp4)

