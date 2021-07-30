
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
import delimited "$data/panel.csv", clear

* replace water and missing NDVI values with .
replace ndvi = . if ndvi == -9999 | ndvi == -10000
* multiply NDVI by scale factor
replace ndvi = ndvi * 0.0001
* have year count start at 1 rather than 1999
replace year = year-1998

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


*** Table 7 - Summary Statistics ***

outreg2 using "$results/ndvi_stats.doc", replace sum(log)
rm "$results/ndvi_stats.txt"


*** Table 3 ***

cgmreg ndvi trt, cluster(commune year)
outreg2 using "$results/main_models.doc", replace tex noni nocons addtext("Year FEs", N, "Grid cell FEs", N, "Climate Controls", N)

reghdfe ndvi trt, cluster(commune year) absorb(year)
outreg2 using "$results/main_models.doc", append tex noni nocons addtext("Year FEs", Y, "Grid cell FEs", N, "Climate Controls", N)
	
reghdfe ndvi trt, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append tex noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", N)

reghdfe ndvi trt temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

reghdfe ndvi trt temp precip c.trt#c.(plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
reghdfe ndvi trt temp precip c.trt#c.(protected_area road_distance), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

reghdfe ndvi trt temp precip c.trt#c.baseline_ndvi, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
* compute interquartile range of Baseline NDVI and multiply by Treatment*Baseline_NDVI coefficient
su baseline_ndvi, d
loc ndvi_25 = r(p25)
loc ndvi_75 = r(p75)
loc iq_inter = _b[c.trt#c.baseline_ndvi] * (`ndvi_75' - `ndvi_25')
display `iq_inter'

reghdfe ndvi trt temp precip c.trt#c.(plantation concession protected_area baseline_ndvi), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

reghdfe ndvi trt temp precip c.trt#c.(plantation concession protected_area road_distance baseline_ndvi), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

rm "$results/main_models.txt"


*** Table 8 - column 2 ***

* generate maximum NDVI value for each cell
egen max_trt = max(trt), by(cell_id)

reghdfe ndvi trt temp precip c.trt#c.(plantation concession protected_area road_distance baseline_ndvi) if max_trt<=300, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_sub300trt.doc", replace noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

rm "$results/main_models_sub300trt.txt"


*** Table 8 - column 3 ***

* generate binned "dummy" treatment measures
gen trt1_5 = (trt >= 1)
gen trt6_12 = (trt >= 6)
gen trt13_29 = (trt >= 13)
gen trt30_ = (trt >= 30)

reghdfe ndvi trt1_5 trt6_12 trt13_29 trt30_ temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt.doc", replace tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

rm "$results/main_models_splittrt.txt"


*** Table 5 ***

reghdfe ndvi c.trt#c.bombings temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/khmer_models.doc", replace tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid Cell FEs", Y, "Climate Controls", Y)

reghdfe ndvi c.trt#c.burials temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/khmer_models.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid Cell FEs", Y, "Climate Controls", Y)

reghdfe ndvi c.trt#c.memorials temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/khmer_models.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid Cell FEs", Y, "Climate Controls", Y)

reghdfe ndvi c.trt#c.prisons temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/khmer_models.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid Cell FEs", Y, "Climate Controls", Y)

reghdfe ndvi c.trt#c.(bombings burials memorials prisons) temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/khmer_models.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid Cell FEs", Y, "Climate Controls", Y)

reghdfe ndvi c.trt#c.(plantation concession protected_area baseline_ndvi road_distance bombings burials memorials prisons) temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/khmer_models.doc", append tex noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid Cell FEs", Y, "Climate Controls", Y)

rm "$results/khmer_models.txt"

*** NDVI Saturation test ***

* generate dummy indicating whether NDVI = 1. Testing for whether NDVI saturation is correlated
* with treatment
gen saturation = (ndvi==1)

reghdfe saturation trt temp precip, cluster(commune year) absorb(province year)
outreg2 using "$results/saturation_test.doc", replace noni nocons addtext("Year FEs", Y, "Province FEs", Y)

rm "$results/saturation_test.txt"

*** NDVI cross-section histogram ***

* produce a histogram of NDVI values in 2008
hist ndvi if year==10, bin(20) title("NDVI in 2008") xtitle("NDVI, 2008") saving("$results/ndvi_histogram.gph", replace)





