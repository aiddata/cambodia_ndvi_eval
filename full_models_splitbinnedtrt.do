
clear all
set more off
set segmentsize 2g
set min_memory 16g

global data "/sciclone/home20/cbaehr/cambodia_gie/data"
global results "/sciclone/home20/cbaehr/cambodia_gie/results"

* global data "/Users/christianbaehr/Desktop"
* global results "/Users/christianbaehr/Desktop"

reghdfe, compile

import delimited "$data/panel.csv", clear

egen t = group(cell_id)
replace cell_id = t
drop t

replace ndvi = . if ndvi == -9999 | ndvi == -10000
replace ndvi = ndvi * 0.0001
replace year = year-1998

bysort cell_id (year): gen baseline_ndvi = ndvi[4]

replace plantation = "1" if plantation == "True"
replace plantation = "0" if plantation == "False"
destring plantation, replace

replace concession = "1" if concession == "True"
replace concession = "0" if concession == "False"
destring concession, replace

replace protected_area = "1" if protected_area == "True"
replace protected_area = "0" if protected_area == "False"
destring protected_area, replace

local var "temp precip ntl"

foreach i of local var {

	capture confirm string variable `i'
	if !_rc {
		replace `i' = "." if `i'=="NA"
		destring `i', replace
	}
	
}

bysort cell_id (year): gen ndvi_pretrend = ndvi[4] - ndvi[1]

replace precip = . if precip>1000 | precip==-1

compress

drop if missing(ndvi) | missing(trt) | missing(commune)

gen trt1k_1 = (trt1k>=1)
gen trt1k_2_4 = (trt1k>=2)
gen trt1k_5_9 = (trt1k>=5)
gen trt1k_10_ = (trt1k>=10)

gen trt2k_1 = (trt2k>=1)
gen trt2k_2_4 = (trt2k>=2)
gen trt2k_5_9 = (trt2k>=5)
gen trt2k_10_ = (trt2k>=10)

gen trt3k_1 = (trt3k>=1)
gen trt3k_2_4 = (trt3k>=2)
gen trt3k_5_9 = (trt3k>=5)
gen trt3k_10_ = (trt3k>=10)

capture quietly cgmreg ndvi trt1k_1 trt1k_2_4 trt1k_5_9 trt1k_10_ trt2k_1 trt2k_2_4 trt2k_5_9 trt2k_10_ trt3k_1 trt3k_2_4 trt3k_5_9 trt3k_10_, cluster(commune year)
outreg2 using "$results/main_models_splitdummytrt.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N)

capture quietly reghdfe ndvi trt1k_1 trt1k_2_4 trt1k_5_9 trt1k_10_ trt2k_1 trt2k_2_4 trt2k_5_9 trt2k_10_ trt3k_1 trt3k_2_4 trt3k_5_9 trt3k_10_, cluster(commune year) absorb(year) pool(10)
outreg2 using "$results/main_models_splitdummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N)
	
capture quietly reghdfe ndvi trt1k_1 trt1k_2_4 trt1k_5_9 trt1k_10_ trt2k_1 trt2k_2_4 trt2k_5_9 trt2k_10_ trt3k_1 trt3k_2_4 trt3k_5_9 trt3k_10_, cluster(commune year) absorb(cell_id year) pool(10)
outreg2 using "$results/main_models_splitdummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k_1 trt1k_2_4 trt1k_5_9 trt1k_10_ trt2k_1 trt2k_2_4 trt2k_5_9 trt2k_10_ trt3k_1 trt3k_2_4 trt3k_5_9 trt3k_10_ temp precip, cluster(commune year) absorb(cell_id year) pool(10)
outreg2 using "$results/main_models_splitdummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k_1 trt1k_2_4 trt1k_5_9 trt1k_10_ trt2k_1 trt2k_2_4 trt2k_5_9 trt2k_10_ trt3k_1 trt3k_2_4 trt3k_5_9 trt3k_10_ temp precip c.trt#c.baseline_ndvi, cluster(commune year) absorb(cell_id year) pool(10)
outreg2 using "$results/main_models_splitdummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt1k_1 trt1k_2_4 trt1k_5_9 trt1k_10_ trt2k_1 trt2k_2_4 trt2k_5_9 trt2k_10_ trt3k_1 trt3k_2_4 trt3k_5_9 trt3k_10_ temp precip c.trt#c.road_distance, cluster(commune year) absorb(cell_id year) pool(10)
outreg2 using "$results/main_models_splitdummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k_1 trt1k_2_4 trt1k_5_9 trt1k_10_ trt2k_1 trt2k_2_4 trt2k_5_9 trt2k_10_ trt3k_1 trt3k_2_4 trt3k_5_9 trt3k_10_ temp precip c.trt#c.(plantation concession protected_area), cluster(commune year) absorb(cell_id year) pool(10)
outreg2 using "$results/main_models_splitdummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k_1 trt1k_2_4 trt1k_5_9 trt1k_10_ trt2k_1 trt2k_2_4 trt2k_5_9 trt2k_10_ trt3k_1 trt3k_2_4 trt3k_5_9 trt3k_10_ temp precip c.trt#c.(baseline_ndvi road_distance plantation concession protected_area), cluster(commune year) absorb(cell_id year) pool(10)
outreg2 using "$results/main_models_splitdummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

