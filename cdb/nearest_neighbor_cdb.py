
working_dir = '/sciclone/home20/cbaehr/cambodia_gie/data'

import os
import math
import time
import pandas as pd
import geopandas as gpd
import numpy as np
from shapely.geometry import Point
from scipy.spatial import cKDTree

def snap(val, interval):
    if interval > 1:
        raise ValueError("Interval must be less than one")
    return round(np.floor( val* 1/interval)) / (1/interval)


class NN():
    """Use KDTree to find NearestNeighbor values for a given location

    Given DataFrame must have "longitude" and "latitude" columns
    Values returned are based on field/column provided

    """
    def __init__(self, df, k=1, agg_func=None):
        self.df = df
        self.default_k = k
        self.default_agg_func = agg_func
    def snap_to(self, interval):
        self.df["original_longitude"] = list(self.df.longitude)
        self.df["original_latitude"] = list(self.df.latitude)
        self.df.longitude = self.df.longitude.apply(lambda x: snap(x, interval))
        self.df.latitude = self.df.latitude.apply(lambda x: snap(x, interval))
    def build_tree(self):
        self.input_geom = list(zip(self.df.longitude, self.df.latitude))
        self.tree = cKDTree(
            data=self.input_geom,
            leafsize=64
        )
    def query(self, loc, field, k=None, agg_func=None):
        if k is None:
            k = self.default_k
        if agg_func is None:
            agg_func = self.default_agg_func
        if k > 1 and agg_func is None:
            raise Exception("An aggregation must be provided when k > 1")
        min_dist, min_index = self.tree.query([loc], k)
        #print(self.tree.query([loc], k))
        min_dist = min_dist[0]
        min_index = np.array(min_index[0])
        if k==1:
            lon_vals, lat_vals = self.input_geom[min_index]
            lon_vals = [lon_vals]
            lat_vals = [lat_vals]
        else:
            lon_vals, lat_vals = zip(*[self.input_geom[i] for i in min_index])
        nn_rows = self.df.loc[(self.df.longitude.isin(lon_vals)) & (self.df.latitude.isin(lat_vals))]
        if len(nn_rows)>1:
            print("greater than one")
            nn = nn_rows.iloc[0]
            val = nn[field].values.flatten().tolist()
            #val = agg_func(vals)
            min_dist = min_dist.tolist()
            min_index = min_index.tolist()
            val.append(min_dist)
            val.append(min_index)
        #elif len(nn_rows) == 0:
            #raise Exception("No NN match could be found")
        #elif agg_func is None:
            # if len(nn_rows) > 1:
            #     warnings.warn("More than one NN match found; using first match.")
            #nn = nn_rows.iloc[0]
            #val = nn[field]
        else:
            # vals = nn_rows[field].tolist()
            # print(type(nn_rows[field].values.flatten()))
            val = nn_rows[field].values.flatten().tolist()
            #val = agg_func(vals)
            min_dist = min_dist.tolist()
            min_index = min_index.tolist()
            val.append(min_dist)
            val.append(min_index)
        return val

points_csv = pd.read_csv(working_dir+"/cdb_spatial.csv")

nn = NN(df=points_csv, k=1)

nn.build_tree()

acled_field = ["infant_mort.2008", "infant_mort.2009", "infant_mort.2010", "infant_mort.2011", "infant_mort.2012", "infant_mort.2013", "infant_mort.2014", "infant_mort.2015", "infant_mort.2016"]

data = pd.read_csv(working_dir+"/empty_grid_cdb.csv")

subset2 = data[['lat', 'lon']]
subset2.columns = ['latitude', 'longitude']

#locs = [tuple(x) for x in subset.values]

loc_val = []

for ix,row in subset2.iterrows():
    loc=(row.longitude, row.latitude)
    x=nn.query(loc=loc, k=1, field=acled_field)
    loc_val.append(x)

mort = pd.DataFrame(loc_val)

mort.columns = ["mort08", "mort09", "mort10", "mort11", "mort12", "mort13", "mort14", "mort15", "mort16", "distance", "index"]

mort['cell_id'] = list(data.cell_id)

# distance measure produces sqrt((x2-x1)^2+(y2-y1)^2)

mort2 = mort
mort2['lat'] = list(subset2['latitude'])
mort2['lon'] = list(subset2['longitude'])

mort2.to_csv(working_dir+"/nn_grid_cdb.csv", index=False)






