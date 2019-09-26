
clear all
set more off
set segmentsize 2g
set min_memory 16g

global data "/sciclone/home20/cbaehr/cambodia_gie/data"
global results "/sciclone/home20/cbaehr/cambodia_gie/results"

* global data "/Users/christianbaehr/Desktop"
* global results "/Users/christianbaehr/Desktop"

* reghdfe, compile

import delimited "$data/panel.csv", clear

* egen t = group(cell_id)
* replace cell_id = t
* drop t

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

outreg2 using "$results/ndvi_stats.doc", replace sum(log)
rm "$results/ndvi_stats.txt"

*** main models ***

capture quietly cgmreg ndvi trt, cluster(commune year)
outreg2 using "$results/main_models.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt, cluster(commune year) absorb(year)
outreg2 using "$results/main_models.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", N)

capture quietly reghdfe ndvi trt temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.baseline_ndvi, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.(plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.(baseline_ndvi plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt temp precip c.trt#c.(baseline_ndvi road_distance plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt temp precip ndvi_pretrend, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt temp precip c.trt#c.(baseline_ndvi road_distance plantation concession protected_area) ndvi_pretrend, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

rm "$results/main_models.txt"

*** split treatment 0-1km 1-2km 2-3km ***

capture quietly cgmreg ndvi trt1k trt2k trt3k, cluster(commune year)
outreg2 using "$results/main_models_splittrt.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k, cluster(commune year) absorb(year)
outreg2 using "$results/main_models_splittrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.baseline_ndvi, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.road_distance, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.(plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.(baseline_ndvi road_distance plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

rm "$results/main_models_splittrt.txt"

*** additional models ***

egen baseline_ndvi_binned = cut(baseline_ndvi), group(4)

gen trt_dummy = (trt > 0)

capture quietly reghdfe ndvi trt temp precip c.trt#c.baseline_ndvi_binned, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/robustness_models.doc", replace noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt temp precip c.trt_dummy#c.baseline_ndvi, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/robustness_models.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

rm "$results/robsutness_models.txt"

*** correlate trt bins w/ baseline NDVI ***

* corr baseline_ndvi trt1k trt2k trt3k if year==20

*** change in ndvi histogram ***

* bysort cell_id (year): gen ndvi_diff = ndvi[_N]-ndvi[1]

* hist ndvi_diff if year==2, bin(20) title("Change in NDVI from first year to last") ///
* 	xtitle("NDVI[last year]-NDVI[first year]") saving("$results\ndvi_diff.gph", replace)

* drop ndvi_diff

* residual histogram

reghdfe ndvi, cluster(commune year) absorb(cell_id year) res(resid)
hist resid, saving("$results/residuals.gph", replace)
drop resid

*** nighttime lights work ***

egen ever_lit = max(ntl > 0 & !missing(ntl)), by(cell_id)

*** main models, ever-lit cells only ***

capture quietly cgmreg ndvi trt if ever_lit == 1, cluster(commune year)
outreg2 using "$results/main_models_everlit.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt if ever_lit == 1, cluster(commune year) absorb(year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N, "Climate Controls", N)

capture quietly reghdfe ndvi trt if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", N)

capture quietly reghdfe ndvi trt temp precip if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.baseline_ndvi if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.(plantation concession protected_area) if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.(baseline_ndvi plantation concession protected_area) if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt temp precip c.trt#c.(baseline_ndvi road_distance plantation concession protected_area) if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt temp precip ntl if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt temp precip ntl c.trt#c.(baseline_ndvi road_distance plantation concession protected_area) if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

rm "$results/main_models_everlit.txt"

*** split treatment 0-1km 1-2km 2-3km, ever-lit cells only ***

capture quietly cgmreg ndvi trt1k trt2k trt3k if ever_lit == 1, cluster(commune year)
outreg2 using "$results/main_models_splittrt_everlit.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k if ever_lit == 1, cluster(commune year) absorb(year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.baseline_ndvi if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.road_distance if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.(plantation concession protected_area) if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.(baseline_ndvi road_distance plantation concession protected_area) if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip ntl if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip ntl c.trt#c.(baseline_ndvi road_distance plantation concession protected_area) if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

rm "$results/main_models_splittrt_everlit.txt"

*** main models, never-lit cells only ***

capture quietly cgmreg ndvi trt if ever_lit == 0, cluster(commune year)
outreg2 using "$results/main_models_neverlit.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt if ever_lit == 0, cluster(commune year) absorb(year)
outreg2 using "$results/main_models_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", N)

capture quietly reghdfe ndvi trt temp precip if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_neverlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.baseline_ndvi if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_neverlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.(plantation concession protected_area) if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_neverlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.(baseline_ndvi plantation concession protected_area) if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_neverlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt temp precip c.trt#c.(baseline_ndvi road_distance plantation concession protected_area) if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_neverlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

rm "$results/main_models_neverlit.txt"

*** split treatment 0-1km 1-2km 2-3km, never-lit cells only ***

capture quietly cgmreg ndvi trt1k trt2k trt3k if ever_lit == 0, cluster(commune year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k if ever_lit == 0, cluster(commune year) absorb(year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", N)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.baseline_ndvi if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.road_distance if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.(plantation concession protected_area) if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.(baseline_ndvi road_distance plantation concession protected_area) if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", append noni nocons drop(temp precip) addtext("Year FEs", Y, "Grid cell FEs", Y, "Climate Controls", Y)

rm "$results/main_models_splittrt_neverlit.txt"

***

* time to treatment dummies

egen year_min = min(year) if trt1k > 0, by(cell_id)
egen first_trt = mean(year_min), by(cell_id)
gen time_to_trt1k = year - first_trt
gen time_to_trt1k_dummy = (time_to_trt1k >= 0)

drop year_min first_trt

egen year_min = min(year) if trt2k > 0, by(cell_id)
egen first_trt = mean(year_min), by(cell_id)
gen time_to_trt2k = year - first_trt
gen time_to_trt2k_dummy = (time_to_trt2k >= 0)

drop year_min first_trt

egen year_min = min(year) if trt3k > 0, by(cell_id)
egen first_trt = mean(year_min), by(cell_id)
gen time_to_trt3k = year - first_trt
gen time_to_trt3k_dummy = (time_to_trt3k >= 0)

drop year_min first_trt

reghdfe ndvi time_to_trt1k c.time_to_trt1k#i.time_to_trt1k_dummy temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/time_to_trt.doc", replace noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

reghdfe ndvi time_to_trt2k c.time_to_trt2k#i.time_to_trt2k_dummy temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/time_to_trt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

reghdfe ndvi time_to_trt3k c.time_to_trt3k#i.time_to_trt3k_dummy temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/time_to_trt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)












