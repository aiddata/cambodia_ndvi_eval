
# use Seth's distancerasters package located in my Windows downloads folder!!

temp_dir = "C:/Users/cbaehr/Downloads"
box_dir = "C:/users/cbaehr/Box Sync"

import sys
import os
import errno
import math
from warnings import warn
import fiona
import rasterio
from rasterio import features
from affine import Affine
from rasterstats.io import read_features
import numpy as np


import distancerasters

roads_path = box_dir + "/cambodia_ndvi_eval/inputData/dissolved_roads/dissolved_roads.shp"

pixel_size = 0.0002695

xmin = 101
xmax = 108
ymin = 10
ymax = 15

affine = Affine(pixel_size, 0, xmin, 0, -pixel_size, ymax)

shape = (int((ymax-ymin)/pixel_size), int((xmax-xmin)/pixel_size))

roads, _ = distancerasters.rasterize(roads_path, affine=affine, shape=shape)

# binary_output_raster_path = "C:/Users/cbaehr/Downloads/roads_binary.tif"
# export_raster(roads, affine, binary_output_raster_path)

distance_output_raster_path = temp_dir + "/road_distance.tif"

def raster_conditional(rarray):
    return (rarray == 1)

dist = distancerasters.build_distance_array(roads, affine=affine,
                            				output=distance_output_raster_path,
                            				conditional=raster_conditional)

###

# once you have clipped the output raster from the above code, run the below code

import csv
import pandas
import numpy
from osgeo import gdal

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
        data = band.ReadAsArray().astype(numpy.float)
        #free memory
        del gdata
        if i == 0:
            #iterate through the points
            for p in pos.iterrows():
                x = int((p[1][lon] - x0)/w)
                y = int((p[1][lat] - y0)/h)
                if y < 15050 and x < 19530:
                    val = data[y,x]
                else:
                    val = -9999
                presVAL = [p[1][cell_id], p[1][lon], p[1][lat], val]
                presValues.append(presVAL)
            df = pandas.DataFrame(presValues, columns=['cell_id', 'x', 'y', rs])
        else:
            #iterate through the points
            for p in pos.iterrows():
                x = int((p[1][lon] - x0)/w)
                y = int((p[1][lat] - y0)/h)
                if y < 15050 and x < 19530:
                    val = data[y,x]
                else:
                    val = -9999
                presValues.append(val)
            df[rs] = pandas.Series(presValues)
    del data, band
    return df

###

grid = pandas.read_csv(box_dir + "/cambodia_ndvi_eval/inputData/empty_grid.csv")

rasDf = getValuesAtPoint(indir=box_dir+"/cambodia_ndvi_eval/inputData/covariates", rasterfileList=["dist_to_roads"], pos=grid, lon=grid.columns[2], lat=grid.columns[1], cell_id=grid.columns[0])

rasDf = rasDf[['cell_id', 'dist_to_roads']]

rasDf.to_csv(temp_dir+"/dist_to_roads.csv", index = False)









