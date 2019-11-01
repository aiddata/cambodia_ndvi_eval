

working_dir = '/sciclone/home20/cbaehr/cambodia_gie/data'
# working_dir = 'C:/Users/cbaehr/Downloads'
# working_dir = "/Users/christianbaehr/Box Sync/cambodia_ndvi_eval/inputData"

# overwrite output files?
overwrite = True

import fiona
import itertools
import math
import numpy as np
import pandas as pd
from shapely.geometry import shape, Point, MultiPoint, MultiPolygon
from shapely.prepared import prep
import csv
from osgeo import gdal, ogr
import sys
import errno
import geopandas
from rasterio import features
from affine import Affine
from rasterstats.io import read_features

# this function is designed to retrieve the raster value at the location of each grid cell. As inputs
# it takes the folder path where the rasters are stored, the actual file names of the raster/s,
# the name of the empty grid object, the name of the longitude variable in the grid, name of the 
# latitude variable in the grid, and the name of the "cell id" variable.
def getValuesAtPoint(indir, rasterfileList, pos, lon, lat, cell_id):
    #gt(2) and gt(4) coefficients are zero, and the gt(1) is pixel width, and gt(5) is pixel height.
    #The (gt(0),gt(3)) position is the top left corner of the top left pixel of the raster.
    for i, rs in enumerate(rasterfileList):
        presValues = []
        gdata = gdal.Open('{}/{}.tif'.format(indir,rs))
        gt = gdata.GetGeoTransform()
        band = gdata.GetRasterBand(1)
        nodata = band.GetNoDataValue()
        x0, y0 , w , h = gt[0], gt[3], gt[1], gt[5]
        data = band.ReadAsArray().astype(np.float)
        params = data.shape
        #free memory
        del gdata
        if i == 0:
            #iterate through the points
            for p in pos.iterrows():
                x = int((p[1][lon] - x0)/w)
                y = int((p[1][lat] - y0)/h)
                if y < params[0] and x < params[1]:
                    val = data[y,x]
                else:
                    val = -9999
                presVAL = [p[1][cell_id], p[1][lon], p[1][lat], val]
                presValues.append(presVAL)
            df = pd.DataFrame(presValues, columns=['cell_id', 'x', 'y', rs])
        else:
            #iterate through the points
            for p in pos.iterrows():
                x = int((p[1][lon] - x0)/w)
                y = int((p[1][lat] - y0)/h)
                if y < params[0] and x < params[1]:
                    val = data[y,x]
                else:
                    val = -9999
                presValues.append(val)
            df[rs] = pd.Series(presValues)
    del data, band
    return df

# read in the "empty" CDB grid. You should have already run the nearest neighbor script on
# this grid, so it should already contain values for mortality (by year) and "distance to village"
grid = pd.read_csv(working_dir+'/nn_grid_cdb.csv')

##################################################

# extracting rasters category by category (i.e. NDVI, then temp, then precip, etc...) to prevent
# crashing

# store names of NDVI raster files
rasters = ['ndvi_'+str(year)+'_5kmbuf' for year in range(2008, 2017)]

# fill temporary dataframe with NDVI raster values
ndvi = getValuesAtPoint(indir=working_dir+'/ndvi_5km', rasterfileList=rasters, pos=grid, lon='lon', lat='lat', cell_id='cell_id')

# merge temporary NDVI dataframe with main grid
full_grid = pd.concat([grid.reset_index(drop=True), ndvi.drop(['cell_id','x','y'], axis=1).reset_index(drop=True)], axis=1)

# delete temporary NDVI dataframe (data is now stored in main grid)
del ndvi

# save main grid
if overwrite:
   full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

##################################################

# store names of temperature raster files
rasters = ['temp_'+str(year) for year in range(2008, 2017)]

# fill temporary dataframe with temperature raster values
temp = getValuesAtPoint(indir=working_dir+'/temperature', rasterfileList=rasters, pos=grid, lon='lon', lat='lat', cell_id='cell_id')

# merge temporary temperature dataframe with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), temp.drop(['cell_id','x','y'], axis=1).reset_index(drop=True)], axis=1)

# delete temporary temperature dataframe
del temp

# save main grid
if overwrite:
    full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

###################################################

# store names of precipitation raster files
rasters = ['precip_'+str(year) for year in range(2008, 2017)]

# fill temporary dataframe with precipitation raster values
precip = getValuesAtPoint(indir=working_dir+'/precipitation', rasterfileList=rasters, pos=grid, lon='lon', lat='lat', cell_id='cell_id')


# merge temporary precipitation dataframe with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), precip.drop(['cell_id','x','y'], axis=1).reset_index(drop=True)], axis=1)

# delete temporary precipitation dataframe
del precip

# save main grid
if overwrite:
    full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

####################################################

# store names of NTL raster files
rasters = ['ntl_'+str(year) for year in range(2008, 2014)]

# fill temporary dataframe with NTL raster values
ntl = getValuesAtPoint(indir=working_dir+'/ntl', rasterfileList=rasters, pos=grid, lon='lon', lat='lat', cell_id='cell_id')

# merge temporary NTL dataframe with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), ntl.drop(['cell_id','x','y'], axis=1).reset_index(drop=True)], axis=1)

# delete temporary NTL dataframe
del ntl

# save main grid
if overwrite:
    full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

####################################################

# using polygon shapefiles with grid cells to assign binary val

# load in Cambodia plantations polygon shapefile
plantations = fiona.open(working_dir+'/plantations/plantations.shp')
# only keep necessary columns
plantations = plantations[0]
# processing plantations data to prepare for merging with grid cells
plantations = shape(plantations['geometry'])
prep_plantations = prep(plantations)

# load in Cambodia economic land concessions polygon shapefile
concessions = fiona.open(working_dir+'/concessions/concessions.shp')
concessions = concessions[0]
# processing concessions data to prepare for merging with grid cells
concessions = shape(concessions['geometry'])
prep_concessions = prep(concessions)

# load in Cambodia protected areas polygon shapefile
protected_areas = fiona.open(working_dir+'/protected_areas/protected_areas.shp')
protected_areas = protected_areas[0]
# processing protected areas data to prepare for merging with grid cells
protected_areas = shape(protected_areas['geometry'])
prep_protected_areas = prep(protected_areas)

# build empty lists to store values indicating whether each grid cell falls within
# one of the categories. If grid cell i lies in a plantation, the corresponding
# index in the plantations_col list will be 1. 0 otherwise
plantations_col = []
concessions_col = []
protected_areas_col = []

# fill the lists with indicator values
for _, row in grid.iterrows():
    c = Point(row['lon'], row['lat'])
    plantations_col.append(prep_plantations.intersects(c))
    concessions_col.append(prep_concessions.intersects(c))
    protected_areas_col.append(prep_protected_areas.intersects(c))

# merge all three lists into a single 3xN dataframe
land_designation = pd.DataFrame()
land_designation.insert(loc=0, column='plantation', value=plantations_col)
land_designation.insert(loc=1, column='concession', value=concessions_col)
land_designation.insert(loc=2, column='protected_area', value=protected_areas_col)

# merge the resulting dataframe in with the main grid dataframe
full_grid = pd.concat([full_grid.reset_index(drop=True), land_designation.reset_index(drop=True)], axis=1)

# delete temporary objects
del plantations, concessions, protected_areas, prep_plantations, prep_concessions, prep_protected_areas

# save main grid
if overwrite:
    full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

#################################################

# fill temporary dataframe with "road distance" raster values. These indicate
# how far a given point is from the nearest road.
road_distance = getValuesAtPoint(indir=working_dir, rasterfileList=['road_distance'], pos=grid, lon='lon', lat='lat', cell_id='cell_id')

# merge temporary road distance dataframe with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), road_distance['road_distance'].reset_index(drop=True)], axis=1)

# delete temporary road distance dataframe
del road_distance

# save main grid
if overwrite:
    full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

####################################################

# open treatment shapefile as geopandas data
treatment = geopandas.read_file(working_dir+'/buf_trt_villages5km/buf_trt_villages5km.shp')

# reformat treatment geometry so it can be merged with main grid
geometry = [Point(xy) for xy in zip(grid.lon, grid.lat)]
crs = {'init': 'epsg:4326'}
gdf = geopandas.GeoDataFrame(grid['cell_id'], crs=crs, geometry=geometry)

# include additional treatment information into GDF with reformatted geometry
treatment_grid = geopandas.sjoin(gdf, treatment[['end_years', 'geometry']], how='left', op='intersects')
treatment_grid = treatment_grid[['cell_id', 'end_years']]

# convert end dates to list to make treatment assignment easier. Also combine duplicated 
# treatment grid cells
treatment_grid = treatment_grid.pivot_table(['end_years'], 'cell_id', aggfunc='|'.join)
treatment_grid = treatment_grid['end_years'].tolist()

# function called "build" designed to split treatment years by vertical bar and compute the 
# number of treatments in each year
def build(year_str):
    j = year_str.split('|')
    return {i:j.count(i) for i in set(j)}

# run the build function over the treatment years grid
year_dicts = list(map(build, treatment_grid))

# convert treatment list to dataframe
treatment = pd.DataFrame(year_dicts)
# NA treatment values are actually untreated, so replace with zero
treatment = treatment.fillna(0)

# if any years not represented in treatment columns, add year and include all zeroes (i.e. no
# villages treated DURING this year)
for i in range(2003, 2019):
    if str(i) not in treatment.columns:
        treatment[str(i)] = 0

# apply the numpy cumsum function to the treatment matrix. This builds a cumulative count
# of treatments over the years, replacing the count of how many treatments a cell received
# in a GIVEN year
treatment = treatment.apply(np.cumsum, axis=1)

# replace treatment column names
treatment.columns = ['trt_'+str(i) for i in range(2003, 2019)]

# only keep 2008-2016 columns for CDB analysis - CDB is only measured during these years
treatment = treatment[['trt_'+str(i) for i in range(2008, 2017)]]

# merge treatment dataframe with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), treatment.reset_index(drop=True)], axis=1)

# delete temporary files
del treatment, treatment_grid

#################################################

# read in Cambodia ADM1 and ADM3 shapefiles
provinces = geopandas.read_file(working_dir+'/KHM_ADM1/KHM_ADM1.shp')
communes = geopandas.read_file(working_dir+'/KHM_ADM3/KHM_ADM3.shp')

# assign province ID to each grid cell
gdf = geopandas.sjoin(gdf, provinces[['id', 'geometry']], how='left', op='intersects')
# assign commune ID to each grid cell
gdf = geopandas.sjoin(gdf.drop(['index_right'],axis=1), communes[['id', 'geometry']], how='left', op='intersects')

# dropping unnecessary columns
gdf = gdf[['id_left', 'id_right']]
# rename gdf columns
gdf.columns = ['province', 'commune']

# merge province and commune information into main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), gdf[['province', 'commune']].reset_index(drop=True)], axis=1)

# delete temporary files
del geometry, gdf, provinces, communes

# save main grid
if overwrite:
    full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

#################################################

#for i in range(1999, 2003):
#    full_grid['trt_'+str(i)] = 0

#for i in list(range(1999, 2001))+[2018]:
#    full_grid['temp_'+str(i)] = 'NA'

#full_grid['precip_2018'] = 'NA'

# add empty NTL columns for 2014-2016 (easier to reshape the panel if time-variant variables have same
# number of year columns)
for i in range(2014, 2017):
	full_grid['ntl_'+str(i)] = 'NA'

# renaming mortality variables
yrs = ['08', '09', '10', '11', '12', '13', '14', '15', '16']
for i in yrs:
	full_grid=full_grid.rename(columns = {'mort'+i:'mort_20'+i})

# specify the names of variables we want to keep
new_names = ['cell_id', 'commune', 'province', 'plantation', 'concession', 'protected_area', 'road_distance', 'distance'] + ['mort_' + str(i) for i in range(2008, 2017)] + ['ndvi_'+str(i)+'_5kmbuf' for i in range(2008, 2017)] + ['trt_' + str(i) for i in range(2008, 2017)] + ['temp_' + str(i) for i in range(2008, 2017)] + ['precip_' + str(i) for i in range(2008, 2017)] + ['ntl_' + str(i) for i in range(2008, 2017)]
full_grid = full_grid[new_names]

# drop observations with missing grid cell value
full_grid.dropna(axis=0, subset=['cell_id'], inplace=True)

# save main grid
if overwrite:
    full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

# find the column indices of time-variant variables
headers = [str(i) for i in range(2008, 2017)]
mort_index = ['mort' in i for i in full_grid.columns]
ndvi_index = ['ndvi' in i for i in full_grid.columns]
trt_index = ['trt' in i for i in full_grid.columns]
temp_index = ['temp' in i for i in full_grid.columns]
precip_index = ['precip' in i for i in full_grid.columns]
ntl_index = ['ntl' in i for i in full_grid.columns]

# clear main grid from memory
del full_grid

# the "pre panel" dataset is in wide form. This loop coverts it to long form, reading in only one row
# at a time to ease memory constraints. Once the line is loaded in, it is flipped from wide to long
# and the result is appended to the new dataset
with open(working_dir+'/pre_panel_cdb.csv') as f, open(working_dir+'/panel_cdb.csv', 'w') as f2:
	# first write column names for the new dataset
    a=f2.write('cell_id,year,commune,province,plantation,concession,protected_area,road_distance,vill_distance,mort,ndvi,trt,temp,precip,ntl\n')
    # for loop goes by line
    for i, line in enumerate(f):
        if i != 0:
            x = line.strip().split(',')
            # first store the time-invariant values
            cell, commune, province, plantation, concession, protected, road_distance, distance = x[0:7]
            # then store each set of time-variant variable values in lists
            mort = list(itertools.compress(x, mort_index))
            ndvi = list(itertools.compress(x, ndvi_index))
            trt = list(itertools.compress(x, trt_index))
            temp = list(itertools.compress(x, temp_index))
            precip = list(itertools.compress(x, precip_index))
            ntl = list(itertools.compress(x, ntl_index))
            # now combine all lists (time-invariant variable values will be repeated) and write out to new dataset
            for year, mort_out, ndvi_out, trt_out, temp_out, precip_out, ntl_out in zip(headers, mort, ndvi, trt, temp, precip, ntl):
                a=f2.write(','.join([cell, year, commune, province, plantation, concession, protected, road_distance, distance, mort_out, ndvi_out, trt_out, temp_out, precip_out, ntl_out])+'\n')







