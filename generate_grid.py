

working_dir = '/sciclone/home20/cbaehr/cambodia_gie/data'

# overwrite output files?
overwrite = True

import fiona
from shapely.geometry import shape, Point
from shapely.prepared import prep
import math
import itertools
import numpy as np
import pandas as pd
from osgeo import gdal

pixel_size = 0.0002695

polygon_data = fiona.open(working_dir+'/dissolve_buf_villages/dissolve_buf_villages.shp')

ndvi_feature = polygon_data[0]

ndvi_shape = shape(ndvi_feature['geometry'])
prep_feat = prep(ndvi_shape)

bounds = ndvi_shape.bounds
xmin, ymin, xmax, ymax = bounds
adj_xmin = math.floor((xmin - -180) / pixel_size) * pixel_size + -180
adj_ymin = math.floor((ymin - -90) / pixel_size) * pixel_size + -90
adj_xmax = math.ceil((xmax - -180) / pixel_size) * pixel_size + -180
adj_ymax = math.ceil((ymax - -90) / pixel_size) * pixel_size + -90
adj_bounds = (adj_xmin, adj_ymin, adj_xmax, adj_ymax)
x_count = (adj_xmax-adj_xmin)/pixel_size
if x_count < round(x_count):
    adj_xmax += pixel_size
    
y_count = (adj_ymax-adj_ymin)/pixel_size
if y_count < round(y_count):
    adj_ymax += pixel_size

coords = itertools.product(
    np.arange(adj_xmin, adj_xmax, pixel_size),
    np.arange(adj_ymin, adj_ymax, pixel_size))

point_list = map(Point, coords)

point_list_country = filter(prep_feat.contains, point_list)
df_list = [{'longitude': i.x, 'latitude': i.y} for i in point_list_country]

grid = pd.DataFrame(df_list)

if overwrite:
    grid.to_csv(working_dir+'/empty_grid.csv')

del polygon_data, ndvi_feature, ndvi_shape, prep_feat, coords, point_list, point_list_country, df_list


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

grid = getValuesAtPoint(indir=working_dir, rasterfileList=['hansen_treecover'], pos=grid, lon='longitude', lat='latitude', cell_id='Unnamed: 0')

grid = grid[grid['hansen_treecover'] >= 10]
grid = grid[['cell_id', 'x', 'y']]
grid.columns = ['cell_id', 'lon', 'lat']
grid['cell_id'] = list(range(1, grid.shape[0]+1))

if overwrite:
	grid.to_csv(working_dir+'/empty_grid.csv', index=False)

