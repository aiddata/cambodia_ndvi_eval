
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

# working_dir = '/sciclone/home20/cbaehr/cambodia_gie/data'
working_dir = 'C:/Users/cbaehr/Downloads'

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

grid = pd.read_csv(working_dir+'/empty_grid.csv')

##################################################

rasters = ['ndvi_'+str(year) for year in range(1999, 2019)]

ndvi = getValuesAtPoint(indir=working_dir+'/ndvi', rasterfileList=rasters, pos=grid, lon='lon', lat='lat', cell_id='cell_id')

full_grid = pd.concat([grid['cell_id'].reset_index(drop=True), ndvi.drop(['cell_id','x','y'], axis=1).reset_index(drop=True)], axis=1)

del ndvi

if overwrite:
   full_grid.to_csv(working_dir+'/pre_panel.csv', index=False)

##################################################

rasters = ['temp_'+str(year) for year in range(2001, 2018)]

temp = getValuesAtPoint(indir=working_dir+'/temperature', rasterfileList=rasters, pos=grid, lon='lon', lat='lat', cell_id='cell_id')

full_grid = pd.concat([full_grid.reset_index(drop=True), temp.drop(['cell_id','x','y'], axis=1).reset_index(drop=True)], axis=1)

del temp

if overwrite:
    full_grid.to_csv(working_dir+'/pre_panel.csv', index=False)

###################################################

rasters = ['precip_'+str(year) for year in range(1999, 2018)]

precip = getValuesAtPoint(indir=working_dir+'/precipitation', rasterfileList=rasters, pos=grid, lon='lon', lat='lat', cell_id='cell_id')


full_grid = pd.concat([full_grid.reset_index(drop=True), precip.drop(['cell_id','x','y'], axis=1).reset_index(drop=True)], axis=1)

del precip

if overwrite:
    full_grid.to_csv(working_dir+'/pre_panel.csv', index=False)

####################################################

plantations = fiona.open(working_dir+'/plantations/plantations.shp')
plantations = plantations[0]
plantations = shape(plantations['geometry'])
prep_plantations = prep(plantations)

concessions = fiona.open(working_dir+'/concessions/concessions.shp')
concessions = concessions[0]
concessions = shape(concessions['geometry'])
prep_concessions = prep(concessions)

protected_areas = fiona.open(working_dir+'/protected_areas/protected_areas.shp')
protected_areas = protected_areas[0]
protected_areas = shape(protected_areas['geometry'])
prep_protected_areas = prep(protected_areas)

plantations_col = []
concessions_col = []
protected_areas_col = []

for _, row in grid.iterrows():
    c = Point(row['lon'], row['lat'])
    plantations_col.append(prep_plantations.intersects(c))
    concessions_col.append(prep_concessions.intersects(c))
    protected_areas_col.append(prep_protected_areas.intersects(c))

land_designation = pd.DataFrame()
land_designation.insert(loc=0, column='plantation', value=plantations_col)
land_designation.insert(loc=1, column='concession', value=concessions_col)
land_designation.insert(loc=2, column='protected_area', value=protected_areas_col)

full_grid = pd.concat([full_grid.reset_index(drop=True), land_designation.reset_index(drop=True)], axis=1)

del plantations, concessions, protected_areas, prep_plantations, prep_concessions, prep_protected_areas

if overwrite:
    full_grid.to_csv(working_dir+'/pre_panel.csv', index=False)

#################################################

road_distance = getValuesAtPoint(indir=working_dir, rasterfileList=['road_distance'], pos=grid, lon='lon', lat='lat', cell_id='cell_id')

full_grid = pd.concat([full_grid.reset_index(drop=True), road_distance['road_distance'].reset_index(drop=True)], axis=1)

del road_distance

if overwrite:
    full_grid.to_csv(working_dir+'/pre_panel.csv', index=False)

####################################################

treatment = geopandas.read_file(working_dir+'/buf_trt_villages/buf_trt_villages.shp')

geometry = [Point(xy) for xy in zip(grid.lon, grid.lat)]
crs = {'init': 'epsg:4326'}
gdf = geopandas.GeoDataFrame(grid['cell_id'], crs=crs, geometry=geometry)

treatment_grid = geopandas.sjoin(gdf, treatment[['end_years', 'geometry']], how='left', op='intersects')
treatment_grid = treatment_grid[['cell_id', 'end_years']]

treatment_grid = treatment_grid.pivot_table(['end_years'], 'cell_id', aggfunc='|'.join)
treatment_grid = treatment_grid['end_years'].tolist()

def build(year_str):
    j = year_str.split('|')
    return {i:j.count(i) for i in set(j)}

year_dicts = list(map(build, treatment_grid))

treatment = pd.DataFrame(year_dicts)
treatment = treatment.fillna(0)

for i in range(2003, 2019):
    if str(i) not in treatment.columns:
        treatment[str(i)] = 0

treatment = treatment.apply(np.cumsum, axis=1)

treatment.columns = ['trt_'+str(i) for i in range(2003, 2019)]

full_grid = pd.concat([full_grid.reset_index(drop=True), treatment.reset_index(drop=True)], axis=1)

del treatment, treatment_grid

###

multi_treatment = geopandas.read_file(working_dir+'/multi_buf_trt_villages/multi_buf_trt_villages.shp')

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

treatment_1k = treatment_1k.reindex(sorted(treatment_1k.columns), axis=1)
treatment_1k = treatment_1k.apply(np.cumsum, axis=1)
treatment_1k.columns = ['trt1k_'+str(i) for i in range(2003, 2019)]

full_grid = pd.concat([full_grid.reset_index(drop=True), treatment_1k.reset_index(drop=True)], axis=1)

del treatment_grid_1k, treatment_1k

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

treatment_2k = treatment_2k.reindex(sorted(treatment_2k.columns), axis=1)
treatment_2k = treatment_2k.apply(np.cumsum, axis=1)
treatment_2k.columns = ['trt2k_'+str(i) for i in range(2003, 2019)]

full_grid = pd.concat([full_grid.reset_index(drop=True), treatment_2k.reset_index(drop=True)], axis=1)

del treatment_grid_2k, treatment_2k

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

treatment_3k = treatment_3k.reindex(sorted(treatment_3k.columns), axis=1)
treatment_3k = treatment_3k.apply(np.cumsum, axis=1)
treatment_3k.columns = ['trt3k_'+str(i) for i in range(2003, 2019)]

full_grid = pd.concat([full_grid.reset_index(drop=True), treatment_3k.reset_index(drop=True)], axis=1)

del treatment_grid_3k, treatment_3k

###

del year_dicts, multi_treatment

if overwrite:
    full_grid.to_csv(working_dir+'/pre_panel.csv', index=False)

#################################################

provinces = geopandas.read_file(working_dir+'/KHM_ADM1/KHM_ADM1.shp')
communes = geopandas.read_file(working_dir+'/KHM_ADM3/KHM_ADM3.shp')

gdf = geopandas.sjoin(gdf, provinces[['id', 'geometry']], how='left', op='intersects')
gdf = geopandas.sjoin(gdf.drop(['index_right'],axis=1), communes[['id', 'geometry']], how='left', op='intersects')

gdf = gdf[['id_left', 'id_right']]
gdf.columns = ['province', 'commune']

full_grid = pd.concat([full_grid.reset_index(drop=True), gdf[['province', 'commune']].reset_index(drop=True)], axis=1)

del geometry, gdf, provinces, communes

if overwrite:
    full_grid.to_csv(working_dir+'/pre_panel.csv', index=False)

#################################################

for i in range(1999, 2003):
    full_grid['trt_'+str(i)] = 0
    full_grid['trt1k_'+str(i)] = 0
    full_grid['trt2k_'+str(i)] = 0
    full_grid['trt3k_'+str(i)] = 0

for i in list(range(1999, 2001))+[2018]:
    full_grid['temp_'+str(i)] = 'NA'

full_grid['precip_2018'] = 'NA'

new_names = ['cell_id', 'commune', 'province', 'plantation', 'concession', 'protected_area', 'road_distance'] + ['ndvi_' + str(i) for i in range(1999, 2019)] + ['trt_' + str(i) for i in range(1999, 2019)] + ['trt1k_' + str(i) for i in range(1999, 2019)] + ['trt2k_' + str(i) for i in range(1999, 2019)] + ['trt3k_' + str(i) for i in range(1999, 2019)] + ['temp_' + str(i) for i in range(1999, 2019)] + ['precip_' + str(i) for i in range(1999, 2019)]

full_grid = full_grid[new_names]

full_grid.dropna(axis=0, subset=['cell_id'], inplace=True)

if overwrite:
    full_grid.to_csv(working_dir+'/pre_panel.csv', index=False)


headers = [str(i) for i in range(1999, 2019)]
ndvi_index = ['ndvi' in i for i in full_grid.columns]
trt_index = ['trt' in i for i in full_grid.columns]
trt1k_index = ['trt1k' in i for i in full_grid.columns]
trt2k_index = ['trt2k' in i for i in full_grid.columns]
trt3k_index = ['trt3k' in i for i in full_grid.columns]
temp_index = ['temp' in i for i in full_grid.columns]
precip_index = ['precip' in i for i in full_grid.columns]

del full_grid

with open(working_dir+'/pre_panel.csv') as f, open(working_dir+'/panel.csv', 'w') as f2:
    a=f2.write('cell_id,year,commune,province,plantation,concession,protected_area,road_distance,ndvi,trt,trt1k,trt2k,trt3k,temp,precip\n')
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
            for year, ndvi_out, trt_out, trt1k_out, trt2k_out, trt3k_out, temp_out, precip_out in zip(headers, ndvi, trt, trt1k, trt2k, trt3k, temp, precip):
                a=f2.write(','.join([cell, year, commune, province, plantation, concession, protected, distance, ndvi_out, trt_out, trt1k_out, trt2k_out, trt3k_out, temp_out, precip_out])+'\n')


