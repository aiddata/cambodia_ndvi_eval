
clear all
set more off
* set these options to accomodate the large dataset
set segmentsize 2g
set min_memory 16g

* local macros for where to load in data from and where to store
* outputs
global data "/sciclone/home20/cbaehr/cambodia_gie/data"
global results "/sciclone/home20/cbaehr/cambodia_gie/results"

* global data "/Users/christianbaehr/Desktop"
* global results "/Users/christianbaehr/Desktop"

* compiling the reghdfe package
reghdfe, compile

* read in panel data
import delimited "$data/panel.csv", clear

* replace negative NDVI values with missing
replace ndvi = . if ndvi == -9999 | ndvi == -10000
* multiply NDVI by scale factor
replace ndvi = ndvi * 0.0001
* start year count from 1 instead of actual
replace year = year-1998

* generate baseline NDVI for each observation. This will be the
* NDVI value from 2002 for each group
bysort cell_id (year): gen baseline_ndvi = ndvi[4]

* replace "TRUE/FALSE" values with 1 and 0 for plantation dummy
replace plantation = "1" if plantation == "True"
replace plantation = "0" if plantation == "False"
destring plantation, replace

* replace "TRUE/FALSE" values with 1 and 0 for concession dummy
replace concession = "1" if concession == "True"
replace concession = "0" if concession == "False"
destring concession, replace

* replace "TRUE/FALSE" values with 1 and 0 for protected area dummy
replace protected_area = "1" if protected_area == "True"
replace protected_area = "0" if protected_area == "False"
destring protected_area, replace

local var "temp precip ntl"

* for each variable in varlist, convert "NA" missing values to "." and destring
foreach i of local var {

	capture confirm string variable `i'
	if !_rc {
		replace `i' = "." if `i'=="NA"
		destring `i', replace
	}
	
}

* generate NDVI pretrend. This is the 2002 value subtracted by the 1999 value
bysort cell_id (year): gen ndvi_pretrend = ndvi[4] - ndvi[1]

* replace topcoded or negative precipitation values with missing
replace precip = . if precip>1000 | precip==-1
replace temp = . if temp==0

* compress the data to ease memory constraints
compress

* drop observations missing NDVI, trt, or commune variable. These observations
* would be omitted from all models anyway
drop if missing(ndvi) | missing(trt) | missing(commune)

*******************

gen temp1 = (trt>0)
gen temp2 = temp1*year
egen temp3 = min(temp2), by(cell_id)

gen time_to_trt = year - temp3

replace time_to_trt = -5 if time_to_trt < -5
replace time_to_trt = 10 if time_to_trt > 10


levelsof time_to_trt, loc(levels) sep()


foreach l of local levels{
	local j = `l' + 50
	local label `"`label' `j' "`l'" "'
	}
	

cap la drop time_to_trt `label'
la def time_to_trt `label', replace

replace time_to_trt = time_to_trt + 50
la values time_to_trt time_to_trt

reghdfe ndvi i.time_to_trt, cluster(commune year) absorb(cell_id year) pool(10)














