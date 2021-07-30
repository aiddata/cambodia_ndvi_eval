
clear all
set more off
set segmentsize 2g
set min_memory 16g

* set file path macros for dataset and results
global data "/sciclone/home20/cbaehr/cambodia_gie/processedData"
global results "/sciclone/home20/cbaehr/cambodia_gie/results"

* update reghdfe package
reghdfe, compile

* import main panel
import delimited "$data/panel_cdb.csv", clear

* replace missing NDVI values and values indicating water with .
replace ndvi = . if ndvi == -9999 | ndvi == -10000
* multiply NDVI by scale factor
replace ndvi = ndvi * 0.0001
* have year count start at 1 rather than 2008
replace year = year-2007

* create baseline NDVI variable, setting the baseline as the 2002 observation
* for each cell
bysort cell_id (year): gen baseline_ndvi = ndvi[4]

* convert plantation dummy to numeric
replace plantation = "1" if plantation == "True"
replace plantation = "0" if plantation == "False"
destring plantation, replace

* convert concession dummy to numeric
replace concession = "1" if concession == "True"
replace concession = "0" if concession == "False"
destring concession, replace

* convert protected area dummy to numeric
replace protected_area = "1" if protected_area == "True"
replace protected_area = "0" if protected_area == "False"
destring protected_area, replace

* for the temperature precipitation and NTL variables, if they have missing
* cases stored as "NA", covert them to "." Then convert variables to numeric
local var "temp precip ntl"

foreach i of local var {

	capture confirm string variable `i'
	if !_rc {
		replace `i' = "." if `i'=="NA"
		destring `i', replace
	}
	
}

* replace missing precipitation cases with .
replace precip = . if precip>1000 | precip==-1
* replace missing temperature cases with .
replace temp = . if temp==0

* reduce dataset size (if possible)
compress


*** Summary Statistics ***

* outreg2 using "$results/ndvi_stats_cdb.doc", replace tex sum(log)
* rm "$results/ndvi_stats_cdb.txt"


*** Table 4 ***

reghdfe ndvi trt temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_cdb.doc", replace tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

reghdfe ndvi trt ntl temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_cdb.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

reghdfe ndvi trt mort temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_cdb.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

reghdfe ndvi trt ntl mort temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_cdb.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

reghdfe ndvi c.trt##c.(plantation concession protected area road_distance baseline_ndvi) ntl mort temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_cdb.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

reghdfe ndvi c.trt##c.(plantation concession protected_area road_distance baseline_ndvi) temp precip if !missing(ntl) & !missing(mort), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_cdb.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

rm "$results/main_models_cdb.txt"

*** Table 3 - column 1 ***

reghdfe ndvi c.trt##c.(plantation concession protected_area road_distance baseline_ndvi) temp precip if vill_dist<=0.0267, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_cdb3km.doc", replace tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

rm "$results/main_models_cdb3km.txt"



