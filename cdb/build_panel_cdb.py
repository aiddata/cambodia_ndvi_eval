

working_dir = '/sciclone/home20/cbaehr/cambodia_gie/inputData'
out_dir = '/sciclone/home20/cbaehr/cambodia_gie/processedData'

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

# load in empty grid
grid = pd.read_csv(working_dir+'/nn_grid_cdb.csv')

##################################################

# list of file names for NDVI rasters
rasters = ['ndvi_'+str(year)+'_5kmbuf' for year in range(2003, 2017)]

# extract NDVI raster values for each grid cell
ndvi = getValuesAtPoint(indir=working_dir+'/ndvi_5km', rasterfileList=rasters, pos=grid, lon='lon', lat='lat', cell_id='cell_id')

# merge NDVI data with main grid
full_grid = pd.concat([grid.reset_index(drop=True), ndvi.drop(['cell_id','x','y'], axis=1).reset_index(drop=True)], axis=1)

#if overwrite:
#   full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

###

# list of file names for temperature rasters
rasters = ['temp_'+str(year) for year in range(2003, 2017)]

# extract temperature raster values for each grid cell
temp = getValuesAtPoint(indir=working_dir+'/temperature', rasterfileList=rasters, pos=grid, lon='lon', lat='lat', cell_id='cell_id')

# merge temperature data with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), temp.drop(['cell_id','x','y'], axis=1).reset_index(drop=True)], axis=1)

#if overwrite:
#    full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

###

# list of file names for precipitation rasters
rasters = ['precip_'+str(year) for year in range(2003, 2017)]

# extract precipitation raster values for each grid cell
precip = getValuesAtPoint(indir=working_dir+'/precipitation', rasterfileList=rasters, pos=grid, lon='lon', lat='lat', cell_id='cell_id')

# merge precipitation data with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), precip.drop(['cell_id','x','y'], axis=1).reset_index(drop=True)], axis=1)

#if overwrite:
#    full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

###

# list of file names for nighttime lights rasters
rasters = ['ntl_'+str(year) for year in range(2003, 2014)]

# extract nighttime lights raster values for each grid cell
ntl = getValuesAtPoint(indir=working_dir+'/ntl', rasterfileList=rasters, pos=grid, lon='lon', lat='lat', cell_id='cell_id')

# merge nighttime lights data with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), ntl.drop(['cell_id','x','y'], axis=1).reset_index(drop=True)], axis=1)

del ndvi, temp, precip, ntl

#if overwrite:
#    full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

####################################################

# load plantations shapefile and prepare to merge with grid
plantations = fiona.open(working_dir+'/plantations/plantations.shp')
plantations = plantations[0]
plantations = shape(plantations['geometry'])
prep_plantations = prep(plantations)

# load concessions shapefile and prepare to merge with grid
concessions = fiona.open(working_dir+'/concessions/concessions.shp')
concessions = concessions[0]
concessions = shape(concessions['geometry'])
prep_concessions = prep(concessions)

# load protected areas shapefile and prepare to merge with grid
protected_areas = fiona.open(working_dir+'/protected_areas/protected_areas.shp')
protected_areas = protected_areas[0]
protected_areas = shape(protected_areas['geometry'])
prep_protected_areas = prep(protected_areas)

# create empty lists to store land designation dummies
plantations_col = []
concessions_col = []
protected_areas_col = []

# iterate through each grid cell to determine whether it intersects a plantation,
# concession, or PA
for _, row in grid.iterrows():
    c = Point(row['lon'], row['lat'])
    plantations_col.append(prep_plantations.intersects(c))
    concessions_col.append(prep_concessions.intersects(c))
    protected_areas_col.append(prep_protected_areas.intersects(c))

# create empty df to store land designation dummies
land_designation = pd.DataFrame()
land_designation.insert(loc=0, column='plantation', value=plantations_col)
land_designation.insert(loc=1, column='concession', value=concessions_col)
land_designation.insert(loc=2, column='protected_area', value=protected_areas_col)

# merge land designation df with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), land_designation.reset_index(drop=True)], axis=1)

del plantations, concessions, protected_areas, prep_plantations, prep_concessions, prep_protected_areas

#if overwrite:
#    full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

#################################################

# load in road distance rasters and extract road distance values for each grid cell
road_distance = getValuesAtPoint(indir=working_dir, rasterfileList=['road_distance'], pos=grid, lon='lon', lat='lat', cell_id='cell_id')

# merge road distance data with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), road_distance['road_distance'].reset_index(drop=True)], axis=1)

del road_distance

#if overwrite:
#    full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

####################################################

# load in treatment shapefile as geopandas data
treatment = geopandas.read_file(working_dir+'/buf_trt_villages3km/buf_trt_villages3km.shp')

# process treatment geometry and convert to geoDataFrame
geometry = [Point(xy) for xy in zip(grid.lon, grid.lat)]
crs = {'init': 'epsg:4326'}
gdf = geopandas.GeoDataFrame(grid['cell_id'], crs=crs, geometry=geometry)

# join treatment data with grid cells. Each grid cell will be assigned a number of 
# treatments and when each treatment project was completed
treatment_grid = geopandas.sjoin(gdf, treatment[['end_years', 'geometry']], how='left', op='intersects')
treatment_grid = treatment_grid[['cell_id', 'end_years']]

# break up treatment information by year
treatment_grid = treatment_grid.pivot_table(['end_years'], 'cell_id', aggfunc='|'.join)
treatment_grid = treatment_grid['end_years'].tolist()

# this function converts treatment info from string to numeric
def build(year_str):
    j = year_str.split('|')
    return {i:j.count(i) for i in set(j)}

# apply function to treatment data
year_dicts = list(map(build, treatment_grid))

# convert treatment data to pandas df
treatment = pd.DataFrame(year_dicts)
treatment = treatment.fillna(0)

# fill any empty years with zero values
for i in range(2003, 2019):
    if str(i) not in treatment.columns:
        treatment[str(i)] = 0

# convert treatment count to cumulative count
treatment = treatment.apply(np.cumsum, axis=1)

# rename treatment columns
treatment.columns = ['trt_'+str(i) for i in range(2003, 2019)]

#treatment = treatment[['trt_'+str(i) for i in range(2008, 2017)]]

# merge treatment data with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), treatment.reset_index(drop=True)], axis=1)

del treatment, treatment_grid

#################################################

# load in province and commune shapefiles
provinces = geopandas.read_file(working_dir+'/KHM_ADM1/KHM_ADM1.shp')
communes = geopandas.read_file(working_dir+'/KHM_ADM3/KHM_ADM3.shp')

# merge grid cells with province data
gdf = geopandas.sjoin(gdf, provinces[['id', 'geometry']], how='left', op='intersects')
gdf = geopandas.sjoin(gdf.drop(['index_right'],axis=1), communes[['id', 'geometry']], how='left', op='intersects')

# rename ADM dataset
gdf = gdf[['id_left', 'id_right']]
gdf.columns = ['province', 'commune']

# merge ADM dataset with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), gdf[['province', 'commune']].reset_index(drop=True)], axis=1)

del geometry, gdf, provinces, communes

#if overwrite:
#    full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

#################################################

# to use the reshaping function, need to have same number of columns for each time-variant measure
# so need to fill missing years with zero or NA values for some measures

#for i in range(1999, 2003):
#    full_grid['trt_'+str(i)] = 0

#for i in list(range(1999, 2001))+[2018]:
#    full_grid['temp_'+str(i)] = 'NA'

#full_grid['precip_2018'] = 'NA'

for i in range(2014, 2017):
	full_grid['ntl_'+str(i)] = 'NA'

for i in range(2003, 2008):
	full_grid['mort'+str(i)]='NA'

yrs = ['08', '09', '10', '11', '12', '13', '14', '15', '16']
for i in yrs:
	full_grid=full_grid.rename(columns = {'mort'+i:'mort_20'+i})

# reorder columns in main dataset
new_names = ['cell_id', 'commune', 'province', 'plantation', 'concession', 'protected_area', 'road_distance', 'distance'] + ['mort_' + str(i) for i in range(2003, 2017)] + ['ndvi_'+str(i)+'_5kmbuf' for i in range(2003, 2017)] + ['trt_' + str(i) for i in range(2003, 2017)] + ['temp_' + str(i) for i in range(2003, 2017)] + ['precip_' + str(i) for i in range(2003, 2017)] + ['ntl_' + str(i) for i in range(2003, 2017)]
full_grid = full_grid[new_names]

# drop observations with missing cell ID
full_grid.dropna(axis=0, subset=['cell_id'], inplace=True)

# write "pre panel" to csv file
if overwrite:
    full_grid.to_csv(working_dir+'/pre_panel_cdb.csv', index=False)

# identify column indices for each time-variant measure. Will need these indices for reshaping
headers = [str(i) for i in range(2003, 2017)]
mort_index = ['mort' in i for i in full_grid.columns]
ndvi_index = ['ndvi' in i for i in full_grid.columns]
trt_index = ['trt' in i for i in full_grid.columns]
temp_index = ['temp' in i for i in full_grid.columns]
precip_index = ['precip' in i for i in full_grid.columns]
ntl_index = ['ntl' in i for i in full_grid.columns]

del full_grid

# reshape panel from wide to long form
with open(working_dir+'/pre_panel_cdb.csv') as f, open(working_dir+'/panel_cdb2.csv', 'w') as f2:
    # first line of the csv is variable names
    a=f2.write('cell_id,year,commune,province,plantation,concession,protected_area,road_distance,vill_distance,mort,ndvi,trt,temp,precip,ntl\n')
    # performing transformation one grid cell at a time
    for i, line in enumerate(f):
        if i != 0:
            x = line.strip().split(',')
            cell, commune, province, plantation, concession, protected, road_distance, distance = x[0:7]
            mort = list(itertools.compress(x, mort_index))
            ndvi = list(itertools.compress(x, ndvi_index))
            trt = list(itertools.compress(x, trt_index))
            temp = list(itertools.compress(x, temp_index))
            precip = list(itertools.compress(x, precip_index))
            ntl = list(itertools.compress(x, ntl_index))
            for year, mort_out, ndvi_out, trt_out, temp_out, precip_out, ntl_out in zip(headers, mort, ndvi, trt, temp, precip, ntl):
                a=f2.write(','.join([cell, year, commune, province, plantation, concession, protected, road_distance, distance, mort_out, ndvi_out, trt_out, temp_out, precip_out, ntl_out])+'\n')
