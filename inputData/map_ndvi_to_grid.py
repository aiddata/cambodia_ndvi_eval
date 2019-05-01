
# specify your Box filepath
box_dir = "/Users/christianbaehr/Box Sync"
# specify the filepath where you store the trimmed NDVI raster TIF files
raster_dir = "/Users/christianbaehr/Downloads/trimmed_ndvi_rasters"
# specify a filepath to store the output data and temporary data files. I 
# dont store this in Box because the output file is too large
temp_dir = "/Users/christianbaehr/Downloads"

import csv
import pandas
import numpy
from osgeo import gdal

###

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

my_index = list(numpy.linspace(0, 79566182, 10, dtype = 'int'))

rasters = [str(year) + "_trimmed" for year in range(1999, 2019)]

for j in list(range(0, 9)):
    ndvi = pandas.read_csv(temp_dir + "/empty_grid.csv", nrows = my_index[j+1]-my_index[j], skiprows = my_index[j])
    rasDf = getValuesAtPoint(indir=raster_dir, rasterfileList=rasters, pos=ndvi, lon=ndvi.columns[2], lat=ndvi.columns[1], cell_id=ndvi.columns[0])
    rasDf.to_csv(temp_dir + '/temp_grid' + str(j) + ".csv")

###

rasters.append("cell_id")

data = pandas.read_csv(temp_dir + '/temp_grid0.csv')
data = data[rasters]

for j in list(range(1, 9)):
    temp = pandas.read_csv(temp_dir + '/temp_grid' + str(j) + ".csv")
    temp = temp[rasters]
    data = data.append(temp)

# I dont save the output csv to Box because the file is too large
data.to_csv(temp_dir + "/ndvi.csv", index = False)



