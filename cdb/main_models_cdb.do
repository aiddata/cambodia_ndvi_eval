
clear all
set more off
set segmentsize 2g
set min_memory 16g

reghdfe, compile

global data "/sciclone/home20/cbaehr/cambodia_gie/data"
global results "/sciclone/home20/cbaehr/cambodia_gie/results"

* global data "/Users/christianbaehr/Desktop"
* global results "/Users/christianbaehr/Desktop"

import delimited "$data/panel_cdb.csv", clear

replace ndvi = . if ndvi == -9999 | ndvi == -10000
replace ndvi = ndvi * 0.0001
replace year = year-2007

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

replace precip = . if precip>1000 | precip==-1
replace temp = . if temp==0

compress

drop if missing(ndvi) | missing(trt) | missing(commune)

outreg2 using "$results/ndvi_stats_cdb.doc", replace sum(log)
rm "$results/ndvi_stats_cdb.txt"

***

capture quietly cgmreg ndvi trt, cluster(commune year)
outreg2 using "$results/main_models_cdb.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt, cluster(commune year) absorb(year)
outreg2 using "$results/main_models_cdb.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_cdb.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", N)

capture quietly reghdfe ndvi trt temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_cdb.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt temp precip ntl, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_cdb.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt temp precip mort, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_cdb.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt temp precip ntl mort, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_cdb.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi c.vill_dist##c.(trt ntl mort) temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_cdb.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi c.trt##c.(protected_area road_distance) temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_cdb.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi c.trt##c.(protected_area road_distance) ntl mort c.(ntl mort)#c.(protected_area road_distance) temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_cdb.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)




