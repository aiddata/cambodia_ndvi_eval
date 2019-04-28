
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
















