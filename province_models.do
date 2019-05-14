
clear all
set more off
set segmentsize 2g
set min_memory 16g
set max_memory 70g

* global project "/Users/christianbaehr/Downloads/province_panels"
* global project "C:/Users/cbaehr/Downloads/province_panels"
global data "/sciclone/home20/cbaehr/cambodia_gie/province_panels"
* global box "/Users/christianbaehr/Box Sync"
* global box "C:/Users/cbaehr/Box Sync"
global results "/sciclone/home20/cbaehr/cambodia_gie/results"

numlist "1/25"
local provs "`r(numlist)'"

foreach prov of local provs {

	import delimited "$data/panel`prov'.csv", clear
	
	egen cell_id2 = group(cell_id)
	replace cell_id = cell_id2
	
	egen comm_id2 = group(comm_id)
	replace comm_id = comm_id2
	
	drop dist_to_road cell_id2 comm_id2
	
	replace ndvi = . if ndvi == -9999 | ndvi == -10000
	replace ndvi = ndvi * 0.0001
	replace year = year-1998
	
	replace temp = "." if temp == "NA"
	destring temp, replace
	replace precip = "." if precip == "NA"
	destring precip, replace
	
	compress
	
	drop if missing(ndvi) | missing(trt) | missing(comm_id)
	
	bysort cell_id (year): gen baseline_ndvi = ndvi[4]
	
	outreg2 using "$results/ndvi_stats`prov'.doc", replace sum(log)
	rm "$results/ndvi_stats`prov'.txt"
 	
	*** main models ***
	
	capture quietly cgmreg ndvi trt, cluster(comm_id year)
	outreg2 using "$results/main_models`prov'.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N)
	
	capture quietly reghdfe ndvi trt, cluster(comm_id year) absorb(year)
	outreg2 using "$results/main_models`prov'.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N)
	
	capture quietly reghdfe ndvi trt, cluster(comm_id year) absorb(cell_id year)
	outreg2 using "$results/main_models`prov'.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
	capture quietly reghdfe ndvi trt temp precip, cluster(comm_id year) absorb(cell_id year)
	outreg2 using "$results/main_models`prov'.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
	capture quietly reghdfe ndvi trt temp precip c.trt#c.baseline_ndvi, cluster(comm_id year) absorb(cell_id year)
	outreg2 using "$results/main_models`prov'.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
	capture quietly reghdfe ndvi trt temp precip c.trt#c.(plantation_dummy concession_dummy protectedarea_dummy), cluster(comm_id year) absorb(cell_id year)
	outreg2 using "$results/main_models`prov'.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
	capture quietly reghdfe ndvi trt temp precip c.trt#c.(baseline_ndvi plantation_dummy concession_dummy protectedarea_dummy), cluster(comm_id year) absorb(cell_id year)
	outreg2 using "$results/main_models`prov'.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
	*** additional models ***
	
	egen baseline_ndvi_binned = cut(baseline_ndvi), group(4)

	capture quietly reghdfe ndvi trt temp precip c.trt#c.baseline_ndvi_binned, cluster(comm_id year) absorb(cell_id year)
	outreg2 using "$results/robustness_models`prov'.doc", replace noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
	gen trt_dummy = (trt > 0)
	
	capture quietly reghdfe ndvi trt temp precip c.trt_dummy#c.baseline_ndvi, cluster(comm_id year) absorb(cell_id year)
	outreg2 using "$results/robustness_models`prov'.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
	
	
	
	rm "$results/main_models`prov'.txt"
	rm "$results/robsutness_models`prov'.txt"
	
	}

	
	
	
	
	
	

	
	