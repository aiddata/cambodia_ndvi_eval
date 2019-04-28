
# specify your Box filepath
box_dir = "C:/Users/cbaehr/Box Sync"

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
                if y > 15050 and x > 19530:
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
                if y > 15050 and x > 19530:
                    val = data[y,x]
                else:
                    val = -9999
                presValues.append(val)
            df[rs] = pandas.Series(presValues)
    del data, band
    return df

###

grid = pandas.read_csv(box_dir + "/cambodia_ndvi_eval/inputData/empty_grid.csv")

rasDf = getValuesAtPoint(indir="C:/Users/cbaehr/Box Sync/cambodia_ndvi_eval/inputData/covariates/", rasterfileList="dist_to_road", pos=grid, lon=grid.columns[2], lat=grid.columns[1], cell_id=grid.columns[0])

rasDf.to_csv("C:/Users/cbaehr/Downloads/test.csv")

