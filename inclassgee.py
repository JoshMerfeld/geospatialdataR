# load libraries
import ee
import geopandas as gpd

ee.Authenticate()
ee.Initialize(project="ee-geefolder")

# let's load the shapefile
shape = gpd.read_file("week7files/kgrid.shp")
# make sure it is in lat/lon (project it)
shape = shape.to_crs("EPSG:4326")
# let's get the total bounds for the shapefile
bounds = shape.total_bounds
bounds

# Let's look at NDVI
ndvi = ee.ImageCollection("MODIS/061/MOD13A3")

# we can use "print" and "getInfo()" to look at more information
# If the above call worked correctly, you should see a bunch of information printed in the console
print(ndvi.getInfo())

# We can also filter the collection by date. Let's look only at january 2019 (the same year as the IHS5)
ndvi = ndvi.filterDate("2019-01-01", "2019-01-31")

# for assets that have many bands (raster layers), we can select the specific ones we want:
ndvi = ndvi.select("NDVI")
# finally, just make sure we have an IMAGE, not an image collection
ndvi = ndvi.mean()


# let's create a bounding box in earth engine. Note the syntax (xmin, ymin, xmax, ymax)
# this does not accept an array (which is what bounds was), so we will extract the individual components
# Also note that indexing in python starts at 0, not 1! bounds[0] gives the first value in the array
bbox = ee.Geometry.BBox(bounds[0], bounds[1], bounds[2], bounds[3])


task = ee.batch.Export.image.toDrive(image=ndvi,
    description="krndvi",
    scale=1000, # set scale the same as the raster's resolution (you can find this on GEE)
    region=bbox,
    crs="EPSG:4326",
    fileFormat="GeoTIFF")
# start the task. You must do this for GEE to actually run the command.
task.start()
# can check the status of the task
task.status()







# land classification
lc = ee.ImageCollection("COPERNICUS/Landcover/100m/Proba-V-C3/Global")

# Only 2021
lc = lc.filterDate("2019-01-01", "2019-12-31")
# just make sure we have an IMAGE, not an image collection
lc = lc.first()
# let's try something different: download the discrete_classification only
lc = lc.select("discrete_classification")

task = ee.batch.Export.image.toDrive(image=lc,
    description="krlc",
    scale=100, # Let's do 100 (for time and memory)
    region=bbox,
    crs="EPSG:4326",
    fileFormat="GeoTIFF")
task.start()
task.status()



lcinfo = lc.getInfo()
type(lcinfo)
lcinfo





