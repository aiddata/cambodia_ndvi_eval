
# set the directory to your local Box Sync path. Reading in shapefile from Box
box_dir = "C:/Users/cbaehr/Box Sync"
# set a directory to store output data. I dont specify Box as the filepath because the
# output file is too large to store in Box
temp_dir = "C:/Users/cbaehr/Downloads"

import fiona
import itertools
import math
import numpy as np
import pandas as pd
from shapely.geometry import shape, Point
from shapely.prepared import prep

polygon_path = box_dir + "/cambodia_ndvi_eval/inputData/village_shapefiles/dissolve_buf_villages/dissolve_buf_villages.shp"

output_path = temp_dir + "/cambodia_ndvi_eval/inputData/empty_grid.csv"

pixel_size = 0.0002695

polygon_data = fiona.open(polygon_path, 'r')

###

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
df_list = [{"longitude": i.x, "latitude": i.y} for i in point_list_country]

df = pd.DataFrame(df_list)

df.to_csv(output_path, encoding='utf-8')
