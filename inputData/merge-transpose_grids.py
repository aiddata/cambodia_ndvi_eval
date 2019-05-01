
## set this to the directory you have the grid files stored in. These files aren't stored in Box because they are too large
my_dir = "/Users/christianbaehr/Downloads"
box_dir = "/Users/christianbaehr/Box Sync"

import pandas as pd
import math

empty_grid = pd.read_csv(box_dir + "/cambodia_ndvi_eval/inputData/empty_grid.csv")

ndvi = pd.read_csv(my_dir + "/ndvi.csv")
ndvi['cell_id'] = ndvi['cell_id'].astype(int)

covars = pd.read_csv(my_dir + "/covariates.csv")

treatment = pd.read_csv(my_dir + "/treatment.csv")

adm = pd.read_csv(my_dir + "/adm.csv")

dist_to_roads = pd.read_csv(my_dir + "/dist_to_roads.csv")
dist_to_roads['cell_id'] = dist_to_roads['cell_id'].astype(int)

temperature = pd.read_csv(my_dir + "/temperature.csv")

precip = pd.read_csv(my_dir + "/precip.csv")



if ndvi['cell_id'].equals(empty_grid['Unnamed: 0']) and ndvi['cell_id'].equals(covars['cell_id']) and ndvi['cell_id'].equals(treatment['cell_id']) and ndvi['cell_id'].equals(adm['cell_id']) and ndvi['cell_id'].equals(dist_to_roads['cell_id']) and ndvi['cell_id'].equals(temperature['cell_id']) and ndvi['cell_id'].equals(precip['cell_id']):
	pre_panel = pd.concat(objs = [empty_grid, adm, ndvi, treatment, covars, dist_to_roads, temperature, precip], axis = 1)

del empty_grid
del ndvi
del covars
del treatment
del adm
del dist_to_roads
del temperature
del precip

pre_panel.drop(['cell_id'], axis = 1, inplace = True)

pre_panel = pre_panel[pre_panel['urban_area']==0]


###

## creating province-level panels

# pre_panel_sub = pre_panel.sample(100000)
pre_panel_sub = pre_panel
del pre_panel

pre_panel_sub.drop(['latitude', 'longitude'], axis = 1, inplace = True)

for j in range(1999, 2003):
	pre_panel_sub['trt_' + str(j)] = 0

names = {}
old_names = [str(year) + '_trimmed' for year in range(1999, 2019)]
new_names = ['ndvi_' + str(year) for year in range(1999, 2019)]
for i in range(20):
	names[old_names[i]] = new_names[i]

pre_panel_sub.rename(columns = names, inplace = True)
pre_panel_sub.rename(columns = {'Unnamed: 0': 'cell_id'}, inplace = True)

provs = pre_panel_sub['prov_id'].unique().tolist()

for prov in provs:
	if prov == prov:
		temp_pre_panel = pre_panel_sub[pre_panel_sub['prov_id'] == prov]
		temp_pre_panel.drop(['prov_id'], axis = 1, inplace = True)
		temp_panel = pd.wide_to_long(temp_pre_panel, ['ndvi_', 'trt_', 'temp_', 'precip_'], i='cell_id', j='year')
		temp_panel.to_stata(my_dir + '/province_panels/panel' + str(int(prov)) + '.dta')


###

## take a random sample of rows from the pre_panel to test
pre_panel_sub = pre_panel.sample(1000)

for j in range(1999, 2003):
	pre_panel_sub['trt_' + str(j)] = 0

names = {}
old_names = [str(year) + '_trimmed' for year in range(1999, 2019)]
new_names = ['ndvi_' + str(year) for year in range(1999, 2019)]
for i in range(20):
	names[old_names[i]] = new_names[i]

pre_panel_sub.rename(columns = names, inplace = True)
pre_panel_sub.rename(columns = {'Unnamed: 0': 'cell_id'}, inplace = True)

panel_sub = pd.wide_to_long(pre_panel_sub, ['ndvi_', 'trt_'], i='cell_id', j='year')

# add scale factor
panel_sub['ndvi_'] = panel_sub['ndvi_'] * 0.0001

panel_sub.to_csv(my_dir + "/panel.csv")
panel_sub.to_stata(my_dir + "/panel.dta")






