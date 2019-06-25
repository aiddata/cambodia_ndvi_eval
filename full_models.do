
clear all
set more off
set segmentsize 2g
set min_memory 16g

* global data "/sciclone/home20/cbaehr/cambodia_gie/data"
* global results "/sciclone/home20/cbaehr/cambodia_gie/results"

global data "C:/Users/cbaehr/Downloads"
global results "C:/Users/cbaehr/Downloads"

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

replace temp = "." if temp=="NA"
destring temp, replace

replace precip = "." if precip=="NA"
destring precip, replace
replace precip = . if precip>1000 | precip==-1

replace ntl = "." if ntl=="NA"
destring ntl, replace

compress

drop if missing(ndvi) | missing(trt) | missing(commune)

outreg2 using "$results/ndvi_stats.doc", replace sum(log)
rm "$results/ndvi_stats.txt"

*** main models ***

capture quietly cgmreg ndvi trt, cluster(commune year)
outreg2 using "$results/main_models.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N)
	
capture quietly reghdfe ndvi trt, cluster(commune year) absorb(year)
outreg2 using "$results/main_models.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N)
	
capture quietly reghdfe ndvi trt, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.baseline_ndvi, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.(plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.(baseline_ndvi plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt temp precip c.trt#c.(baseline_ndvi road_distance plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)


*** split treatment 0-1km 1-2km 2-3km ***

capture quietly cgmreg ndvi trt1k trt2k trt3k, cluster(commune year)
outreg2 using "$results/main_models_splittrt.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k, cluster(commune year) absorb(year)
outreg2 using "$results/main_models_splittrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.baseline_ndvi, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.road_distance, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.(plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.(baseline_ndvi road_distance plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)


*** additional models ***
	
egen baseline_ndvi_binned = cut(baseline_ndvi), group(4)

capture quietly reghdfe ndvi trt temp precip c.trt#c.baseline_ndvi_binned, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/robustness_models.doc", replace noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
gen trt_dummy = (trt > 0)
	
capture quietly reghdfe ndvi trt temp precip c.trt_dummy#c.baseline_ndvi, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/robustness_models.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

*** new models ***


capture quietly reghdfe ndvi trt temp precip c.trt#c.(plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.(baseline_ndvi plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)


rm "$results/main_models.txt"
rm "$results/main_models_splittrt.txt"
rm "$results/robsutness_models.txt"

*** correlate trt bins w/ baseline NDVI ***

corr baseline_ndvi trt1k trt2k trt3k

*** change in ndvi histogram ***

bysort cell_id (year): gen ndvi_diff = ndvi[_N]-ndvi[1]

hist ndvi_diff if year==2, bin(20) title("Change in NDVI from first year to last") ///
	xtitle("NDVI[last year]-NDVI[first year]") saving("$results\ndvi_diff.gph", replace)

drop ndvi_diff

*** nighttime lights work ***

egen ever_lit = max(ntl > 0 & !missing(ntl)), by(cell_id)

*** main models, ever-lit cells only ***

capture quietly cgmreg ndvi trt if ever_lit == 1, cluster(commune year)
outreg2 using "$results/main_models_everlit.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N)
	
capture quietly reghdfe ndvi trt if ever_lit == 1, cluster(commune year) absorb(year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N)

capture quietly reghdfe ndvi trt if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt temp precip if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.baseline_ndvi if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.(plantation concession protected_area) if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.(baseline_ndvi plantation concession protected_area) if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt temp precip c.trt#c.(baseline_ndvi road_distance plantation concession protected_area) if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt temp precip ntl if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt temp precip ntl c.trt#c.(baseline_ndvi road_distance plantation concession protected_area) if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)


*** split treatment 0-1km 1-2km 2-3km, ever-lit cells only ***

capture quietly cgmreg ndvi trt1k trt2k trt3k if ever_lit == 1, cluster(commune year)
outreg2 using "$results/main_models_splittrt_everlit.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k if ever_lit == 1, cluster(commune year) absorb(year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.baseline_ndvi if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.road_distance if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.(plantation concession protected_area) if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.(baseline_ndvi road_distance plantation concession protected_area) if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip ntl if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip ntl c.trt#c.(baseline_ndvi road_distance plantation concession protected_area) if ever_lit == 1, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_everlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)


*** main models, never-lit cells only ***

capture quietly cgmreg ndvi trt if ever_lit == 0, cluster(commune year)
outreg2 using "$results/main_models_neverlit.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N)
	
capture quietly reghdfe ndvi trt if ever_lit == 0, cluster(commune year) absorb(year)
outreg2 using "$results/main_models_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N)
	
capture quietly reghdfe ndvi trt if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt temp precip if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.baseline_ndvi if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.(plantation concession protected_area) if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt temp precip c.trt#c.(baseline_ndvi plantation concession protected_area) if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt temp precip c.trt#c.(baseline_ndvi road_distance plantation concession protected_area) if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)


*** split treatment 0-1km 1-2km 2-3km, never-lit cells only ***

capture quietly cgmreg ndvi trt1k trt2k trt3k if ever_lit == 0, cluster(commune year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k if ever_lit == 0, cluster(commune year) absorb(year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.baseline_ndvi if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.road_distance if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.(plantation concession protected_area) if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt1k trt2k trt3k temp precip c.trt#c.(baseline_ndvi road_distance plantation concession protected_area) if ever_lit == 0, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_splittrt_neverlit.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)










