
# set a directory to store output data. I dont specify Box as the filepath because the
# output file is too large to store in Box. You will have to make sure

# in your temporary directory, you must have the dissolved buffered village shapefile,
# the Hansen treecover raster, NDVI raster data for 1999-2018 (separate files stored
# in a folder called "ndvi"), temperature rasters for 2001-2017 (separate files stored
# in a folder called "temperature"), precip rasters for 1999-2017 (separate files stored
# in a folder called "precipitation"), a plantations shapefile (in a folder called 
# "plantations"), a concessions shapefile (in a folder called "concessions"), and a
# protected areas shapefile (in a folder called "protected_areas"), as well as the roads
# shapefile

working_dir = '/sciclone/home20/cbaehr/cambodia_gie/inputData'
out_dir = '/sciclone/home20/cbaehr/cambodia_gie/processedData'
# working_dir = 'C:/Users/cbaehr/Downloads'

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

#################################################

# define function to extract raster values for each grid cell
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
grid = pd.read_csv(working_dir+'/empty_grid.csv')

##################################################

# list of file names for NDVI rasters
rasters = ['ndvi_'+str(year) for year in range(1999, 2019)]

# extract NDVI raster values for each grid cell
ndvi = getValuesAtPoint(indir=working_dir+'/ndvi', rasterfileList=rasters, pos=grid, lon='lon', lat='lat', cell_id='cell_id')

# merge NDVI data with main grid
full_grid = pd.concat([grid['cell_id'].reset_index(drop=True), ndvi.drop(['cell_id','x','y'], axis=1).reset_index(drop=True)], axis=1)

#if overwrite:
#   full_grid.to_csv(out_dir+'/pre_panel.csv', index=False)

###

# list of file names for temperature rasters
rasters = ['temp_'+str(year) for year in range(2001, 2018)]

# extract temperature raster values for each grid cell
temp = getValuesAtPoint(indir=working_dir+'/temperature', rasterfileList=rasters, pos=grid, lon='lon', lat='lat', cell_id='cell_id')

# merge temperature data with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), temp.drop(['cell_id','x','y'], axis=1).reset_index(drop=True)], axis=1)

#if overwrite:
#    full_grid.to_csv(out_dir+'/pre_panel.csv', index=False)

###

# list of file names for precipitation rasters
rasters = ['precip_'+str(year) for year in range(1999, 2018)]

# extract precipitation raster values for each grid cell
precip = getValuesAtPoint(indir=working_dir+'/precipitation', rasterfileList=rasters, pos=grid, lon='lon', lat='lat', cell_id='cell_id')

# merge precipitation data with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), precip.drop(['cell_id','x','y'], axis=1).reset_index(drop=True)], axis=1)

#if overwrite:
#    full_grid.to_csv(out_dir+'/pre_panel.csv', index=False)

###

# list of file names for nighttime lights rasters
rasters = ['ntl_'+str(year) for year in range(1999, 2014)]

# extract nighttime lights raster values for each grid cell
ntl = getValuesAtPoint(indir=working_dir+'/ntl', rasterfileList=rasters, pos=grid, lon='lon', lat='lat', cell_id='cell_id')

# merge nighttime lights data with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), ntl.drop(['cell_id','x','y'], axis=1).reset_index(drop=True)], axis=1)

del ndvi, temp, precip, ntl

#if overwrite:
#    full_grid.to_csv(out_dir+'/pre_panel.csv', index=False)

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
#    full_grid.to_csv(out_dir+'/pre_panel.csv', index=False)

#################################################

# load in road distance rasters and extract road distance values for each grid cell
road_distance = getValuesAtPoint(indir=working_dir, rasterfileList=['road_distance'], pos=grid, lon='lon', lat='lat', cell_id='cell_id')

# merge road distance data with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), road_distance['road_distance'].reset_index(drop=True)], axis=1)

del road_distance

#if overwrite:
#    full_grid.to_csv(out_dir+'/pre_panel.csv', index=False)

####################################################

# load in treatment shapefile as geopandas data
treatment = geopandas.read_file(working_dir+'/buf_trt_villages/buf_trt_villages.shp')

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

treatment = treatment.reindex(sorted(treatment.columns), axis=1)

# convert treatment count to cumulative count
treatment = treatment.apply(np.cumsum, axis=1)

# rename treatment columns
treatment.columns = ['trt_'+str(i) for i in range(2003, 2019)]

# merge treatment data with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), treatment.reset_index(drop=True)], axis=1)

###

# load in tiered treatment shapefile (1km, 2km, 3km)
multi_treatment = geopandas.read_file(working_dir+'/multi_buf_trt_villages/multi_buf_trt_villages.shp')

# build 1km treatment measure
treatment_grid_1k = geopandas.sjoin(gdf, multi_treatment[multi_treatment['dist']=='1000'], how='left', op='intersects')
treatment_grid_1k = treatment_grid_1k[['cell_id', 'end_years']]
treatment_grid_1k['end_years'] = treatment_grid_1k['end_years'].fillna('2002')
treatment_grid_1k = treatment_grid_1k.pivot_table(['end_years'], 'cell_id', aggfunc='|'.join, dropna=False, fill_value=np.nan)
treatment_grid_1k = treatment_grid_1k['end_years'].tolist()

year_dicts = list(map(build, treatment_grid_1k))
treatment_1k = pd.DataFrame(year_dicts)
treatment_1k.drop(['2002'], axis=1, inplace=True)
treatment_1k = treatment_1k.fillna(0)

for i in range(2003, 2019):
    if str(i) not in treatment_1k.columns:
        treatment_1k[str(i)] = 0

treatment_1k = treatment_1k.reindex(columns=sorted(treatment_1k.columns))
treatment_1k = treatment_1k.apply(np.cumsum, axis=1)
treatment_1k.columns = ['trt1k_'+str(i) for i in range(2003, 2019)]

# merge 1km treatment measure with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), treatment_1k.reset_index(drop=True)], axis=1)

###

# build 2km treatment measure
treatment_grid_2k = geopandas.sjoin(gdf, multi_treatment[multi_treatment['dist']=='2000'], how='left', op='intersects')
treatment_grid_2k = treatment_grid_2k[['cell_id', 'end_years']]
treatment_grid_2k['end_years'] = treatment_grid_2k['end_years'].fillna('2002')
treatment_grid_2k = treatment_grid_2k.pivot_table(['end_years'], 'cell_id', aggfunc='|'.join, dropna=False, fill_value=np.nan)
treatment_grid_2k = treatment_grid_2k['end_years'].tolist()

year_dicts = list(map(build, treatment_grid_2k))
treatment_2k = pd.DataFrame(year_dicts)
treatment_2k.drop(['2002'], axis=1, inplace=True)
treatment_2k = treatment_2k.fillna(0)

for i in range(2003, 2019):
    if str(i) not in treatment_2k.columns:
        treatment_2k[str(i)] = 0

treatment_2k = treatment_2k.reindex(columns=sorted(treatment_2k.columns))
treatment_2k = treatment_2k.apply(np.cumsum, axis=1)
treatment_2k.columns = ['trt2k_'+str(i) for i in range(2003, 2019)]

# merge 2km treatment measure with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), treatment_2k.reset_index(drop=True)], axis=1)

###

# build 3km treatment measure
treatment_grid_3k = geopandas.sjoin(gdf, multi_treatment[multi_treatment['dist']=='3000'], how='left', op='intersects')
treatment_grid_3k = treatment_grid_3k[['cell_id', 'end_years']]
treatment_grid_3k['end_years'] = treatment_grid_3k['end_years'].fillna('2002')
treatment_grid_3k = treatment_grid_3k.pivot_table(['end_years'], 'cell_id', aggfunc='|'.join, dropna=False, fill_value=np.nan)
treatment_grid_3k = treatment_grid_3k['end_years'].tolist()

year_dicts = list(map(build, treatment_grid_3k))
treatment_3k = pd.DataFrame(year_dicts)
treatment_3k.drop(['2002'], axis=1, inplace=True)
treatment_3k = treatment_3k.fillna(0)

for i in range(2003, 2019):
    if str(i) not in treatment_3k.columns:
        treatment_3k[str(i)] = 0

treatment_3k = treatment_3k.reindex(columns=sorted(treatment_3k.columns))
treatment_3k = treatment_3k.apply(np.cumsum, axis=1)
treatment_3k.columns = ['trt3k_'+str(i) for i in range(2003, 2019)]

# merge 3km treatment measure with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), treatment_3k.reset_index(drop=True)], axis=1)

del treatment, treatment_grid, treatment_grid_1k, treatment_1k, treatment_grid_2k, treatment_2k, treatment_grid_3k, treatment_3k, year_dicts, multi_treatment

#if overwrite:
#    full_grid.to_csv(out_dir+'/pre_panel.csv', index=False)

#################################################

# load in province and commune shapefiles
provinces = geopandas.read_file(working_dir+'/KHM_ADM1/KHM_ADM1.shp')
communes = geopandas.read_file(working_dir+'/KHM_ADM3/KHM_ADM3.shp')

# merge grid cells with province data
gdf = geopandas.sjoin(gdf, provinces[['id', 'geometry']], how='left', op='intersects')
# merge grid cells with commune data
gdf = geopandas.sjoin(gdf.drop(['index_right'],axis=1), communes[['id', 'geometry']], how='left', op='intersects')

# rename ADM dataset
gdf = gdf[['id_left', 'id_right']]
gdf.columns = ['province', 'commune']

# merge ADM dataset with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), gdf[['province', 'commune']].reset_index(drop=True)], axis=1)

del geometry, gdf, provinces, communes

#if overwrite:
#    full_grid.to_csv(out_dir+'/pre_panel.csv', index=False)

#################################################

# load in CGEO shapefiles and prepare for merging with grid cells
bombings = fiona.open(working_dir+'/cgeo/khmer_bombings/khmer_bombings.shp')
bombings = bombings[0]
bombings = shape(bombings['geometry'])
prep_bombings = prep(bombings)

burials = fiona.open(working_dir+'/cgeo/khmer_burials/khmer_burials.shp')
burials = burials[0]
burials = shape(burials['geometry'])
prep_burials = prep(burials)

memorials = fiona.open(working_dir+'/cgeo/khmer_memorials/khmer_memorials.shp')
memorials = memorials[0]
memorials = shape(memorials['geometry'])
prep_memorials = prep(memorials)

prisons = fiona.open(working_dir+'/cgeo/khmer_prisons/khmer_prisons.shp')
prisons = prisons[0]
prisons = shape(prisons['geometry'])
prep_prisons = prep(prisons)

# create empty lists to store Khmer exposure indicators for each grid cell
bombings_col = []
burials_col = []
memorials_col = []
prisons_col = []

# building Khmer exposure dummies
for _, row in grid.iterrows():
    c = Point(row['lon'], row['lat'])
    bombings_col.append(prep_bombings.intersects(c))
    burials_col.append(prep_burials.intersects(c))
    memorials_col.append(prep_memorials.intersects(c))
    prisons_col.append(prep_prisons.intersects(c))

# combine Khmer exposure dummies into a pandas df
khmer_exposure = pd.DataFrame()
khmer_exposure.insert(loc=0, column='bombings', value=bombings_col)
khmer_exposure.insert(loc=1, column='burials', value=burials_col)
khmer_exposure.insert(loc=2, column='memorials', value=memorials_col)
khmer_exposure.insert(loc=3, column='prisons', value=prisons_col)

# merge Khmer dummies with main grid
full_grid = pd.concat([full_grid.reset_index(drop=True), khmer_exposure.reset_index(drop=True)], axis=1)

del bombings, burials, memorials, prisons, prep_bombings, prep_burials, prep_memorials, prep_prisons, bombings_col, burials_col, memorials_col, prisons_col, khmer_exposure

#if overwrite:
#    full_grid.to_csv(out_dir+'/pre_panel.csv', index=False)

#################################################

# to use the reshaping function, need to have same number of columns for each time-variant measure
# so need to fill missing years with zero or NA values for some measures
for i in range(1999, 2003):
    full_grid['trt_'+str(i)] = 0
    full_grid['trt1k_'+str(i)] = 0
    full_grid['trt2k_'+str(i)] = 0
    full_grid['trt3k_'+str(i)] = 0

for i in list(range(1999, 2001))+[2018]:
    full_grid['temp_'+str(i)] = 'NA'

full_grid['precip_2018'] = 'NA'

for i in range(2014, 2019):
	full_grid['ntl_'+str(i)] = 'NA'

# reorder columns in main dataset
new_names = ['cell_id', 'commune', 'province', 'plantation', 'concession', 'protected_area', 'road_distance', 'bombings', 'burials', 'memorials', 'prisons'] + ['ndvi_' + str(i) for i in range(1999, 2019)] + ['trt_' + str(i) for i in range(1999, 2019)] + ['trt1k_' + str(i) for i in range(1999, 2019)] + ['trt2k_' + str(i) for i in range(1999, 2019)] + ['trt3k_' + str(i) for i in range(1999, 2019)] + ['temp_' + str(i) for i in range(1999, 2019)] + ['precip_' + str(i) for i in range(1999, 2019)] + ['ntl_' + str(i) for i in range(1999, 2019)]
full_grid = full_grid[new_names]

# drop observations with missing cell ID
full_grid.dropna(axis=0, subset=['cell_id'], inplace=True)

# write "pre panel" to csv file
if overwrite:
    full_grid.to_csv(out_dir+'/pre_panel.csv', index=False)

# identify column indices for each time-variant measure. Will need these indices for reshaping
headers = [str(i) for i in range(1999, 2019)]
ndvi_index = ['ndvi' in i for i in full_grid.columns]
trt_index = ['trt' in i for i in full_grid.columns]
trt1k_index = ['trt1k' in i for i in full_grid.columns]
trt2k_index = ['trt2k' in i for i in full_grid.columns]
trt3k_index = ['trt3k' in i for i in full_grid.columns]
temp_index = ['temp' in i for i in full_grid.columns]
precip_index = ['precip' in i for i in full_grid.columns]
ntl_index = ['ntl' in i for i in full_grid.columns]

del full_grid

# reshape panel from wide to long form
with open(out_dir+'/pre_panel.csv') as f, open(out_dir+'/panel.csv', 'w') as f2:
	# first line of the csv is variable names
    a=f2.write('cell_id,year,commune,province,plantation,concession,protected_area,road_distance,bombings,burials,memorials,prisons,ndvi,trt,trt1k,trt2k,trt3k,temp,precip,ntl\n')
    # performing transformation one grid cell at a time
    for i, line in enumerate(f):
        if i != 0:
            x = line.strip().split(',')
            cell, commune, province, plantation, concession, protected, distance = x[0:7]
            ndvi = list(itertools.compress(x, ndvi_index))
            trt = list(itertools.compress(x, trt_index))
            trt1k = list(itertools.compress(x, trt1k_index))
            trt2k = list(itertools.compress(x, trt2k_index))
            trt3k = list(itertools.compress(x, trt3k_index))
            temp = list(itertools.compress(x, temp_index))
            precip = list(itertools.compress(x, precip_index))
            ntl = list(itertools.compress(x, ntl_index))
            for year, ndvi_out, trt_out, trt1k_out, trt2k_out, trt3k_out, temp_out, precip_out, ntl_out in zip(headers, ndvi, trt, trt1k, trt2k, trt3k, temp, precip, ntl):
                a=f2.write(','.join([cell, year, commune, province, plantation, concession, protected, distance, bombings, burials, memorials, prisons, ndvi_out, trt_out, trt1k_out, trt2k_out, trt3k_out, temp_out, precip_out, ntl_out])+'\n')


