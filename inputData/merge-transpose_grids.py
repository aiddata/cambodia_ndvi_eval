
## set this to the directory you have the grid files stored in. These files aren't stored in Box because they are too large
my_dir = "/Users/christianbaehr/Downloads"
box_dir = "/Users/christianbaehr/Box Sync"
os.chdir('C:/Users/cbaehr/Downloads/province_pre_panels')

from itertools import compress
import numpy as np
import pandas as pd
import os
import statistics as stats


# empty_grid = pd.read_csv(box_dir+"/cambodia_ndvi_eval/inputData/empty_grid.csv")
# empty_grid = empty_grid[['cell_id']]

adm = pd.read_csv(my_dir+"/adm.csv")

ndvi = pd.read_csv(my_dir+"/ndvi.csv")
ndvi.columns = ['ndvi' + str(i) for i in range(1999, 2019)] + ['cell_id']
ndvi = ndvi[['ndvi' + str(i) for i in range(1999, 2019)]]

pre_panel = pd.concat(objs = [adm, ndvi], axis = 1)
del ndvi
del adm

covars = pd.read_csv(my_dir+"/covariates.csv")
covars = covars[['plantation_dummy', 'concession_dummy', 'protectedArea_dummy']]
pre_panel = pd.concat(objs = [pre_panel, covars], axis = 1)
del covars

treatment = pd.read_csv(my_dir+"/treatment.csv")
treatment = treatment[['trt_' + str(i) for i in range(2003, 2019)]]
pre_panel = pd.concat(objs = [pre_panel, treatment], axis = 1)
del treatment

dist_to_roads = pd.read_csv(my_dir+"/dist_to_roads.csv")
dist_to_roads = dist_to_roads[['dist_to_roads']]
pre_panel = pd.concat(objs = [pre_panel, dist_to_roads], axis = 1)
del dist_to_roads

temperature = pd.read_csv(my_dir+"/temperature.csv")
temperature = temperature[['temp_' + str(i) for i in range(2001, 2018)]]
pre_panel = pd.concat(objs = [pre_panel, temperature], axis = 1)
del temperature

precip = pd.read_csv(my_dir+"/precip.csv")
precip = precip[['precip_' + str(i) for i in range(1999, 2018)]]
pre_panel = pd.concat(objs = [pre_panel, precip], axis = 1)
del precip


for i in pre_panel['prov_id'].unique():
   if i==i:
      temp_panel = pre_panel[pre_panel['prov_id']==i]
      temp_panel = temp_panel[temp_panel['prov_id']==temp_panel['prov_id']]
      temp_panel.drop('prov_id', axis=1, inplace=True)
      temp_panel = temp_panel[temp_panel['urban_area']==0]
      temp_panel.drop('urban_area', axis=1, inplace=True)
      temp_panel = temp_panel[temp_panel['comm_id']==temp_panel['comm_id']]
      temp_panel.to_csv(my_dir+'/province_pre_panels/pre_panel'+str(int(i))+'.csv', index=False)

del pre_panel
del temp_panel

###

new_names = ['cell_id', 'comm_id', 'plantation_dummy', 'concession_dummy', 'protectedArea_dummy', 'dist_to_roads'] + ['ndvi' + str(i) for i in range(1999, 2019)] + ['trt_' + str(i) for i in range(1999, 2019)] + ['temp_' + str(i) for i in range(1999, 2019)] + ['precip_' + str(i) for i in range(1999, 2019)]

for i in range(1, 26):
	test = pd.read_csv('temp_panel'+str(i)+'.csv')
	for j in range(1999, 2003):
		test['trt_' + str(j)] = 0
	for j in range(1999, 2001):
		test['temp_' + str(j)] = 'NA'
	test['temp_2018'] = 'NA'
	test['precip_2018'] = 'NA'
	test = test[new_names]
	test.to_csv(my_dir+'/province_pre_panels/pre_panel'+str(i)+'.csv', index = False)

headers = [str(i) for i in range(1999, 2019)]
ndvi_index = ['ndvi' in i for i in test.columns]
trt_index = ['trt' in i for i in test.columns]
temp_index = ['temp' in i for i in test.columns]
precip_index = ['precip' in i for i in test.columns]


del test

for i in range(1, 26):
	with open(my_dir+'/province_pre_panels/pre_panel'+str(i)+'.csv') as f, open('/province_pre_panels/panel'+str(i)+'.csv', 'w') as f2:
		a = f2.write('cell_id,year,comm_id,plantation_dummy,concession_dummy,protectedArea_dummy,dist_to_roads,ndvi,trt,temp,precip\n')
		for i, line in enumerate(f):
			if i!=0:
				the_line = line.strip().split(',')
				cell, comm, plant, conc, prot, dist = the_line[0:6]
				ndvi = list(compress(the_line, ndvi_index))
				trt = list(compress(the_line, trt_index))
				temp = list(compress(the_line, temp_index))
				precip = list(compress(the_line, precip_index))
				for year, val1, val2, val3, val4 in zip(headers, ndvi, trt, temp, precip):
					a=f2.write(','.join([cell, year, comm, plant, conc, prot, dist,  val1, val2, val3, val4]) + '\n')

