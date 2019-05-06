
clear all
set more off
set segmentsize 2g
set min_memory 16g
set max_memory 70g

* global project "/Users/christianbaehr/Downloads/province_panels"
global project "C:/Users/cbaehr/Downloads/province_panels"
global box "C:/Users/cbaehr/Box Sync"

numlist "1/25"
local provs "`r(numlist)'"

foreach prov of local provs {

	import delimited "$project/out`prov'.csv", clear
	
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
	
	outreg2 using "$box/cambodia_ndvi_eval/Results/ndvi_stats`prov'.doc", replace sum(log)
	rm "$box/cambodia_ndvi_eval/Results/ndvi_stats`prov'.txt"
 	
	
	capture quietly cgmreg ndvi trt, cluster(comm_id year)
	* est sto a1
	outreg2 using "$box/cambodia_ndvi_eval/Results/ndvi_models`prov'.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N)
	capture quietly reghdfe ndvi trt, cluster(comm_id year) absorb(year)
	* est sto a2
	outreg2 using "$box/cambodia_ndvi_eval/Results/ndvi_models`prov'.doc", append keep(trt) noni nocons addtext("Year FEs", Y, "Grid cell FEs", N)
	capture quietly reghdfe ndvi trt i.year, cluster(comm_id year) absorb(cell_id)
	* est sto a3
	outreg2 using "$box/cambodia_ndvi_eval/Results/ndvi_models`prov'.doc", append keep(trt) noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
	capture quietly reghdfe ndvi trt c.trt#c.baseline_ndvi i.year, cluster(comm_id year) absorb(cell_id)
	* est sto a4
	outreg2 using "$box/cambodia_ndvi_eval/Results/ndvi_models`prov'.doc", append keep(trt c.trt#c.baseline_ndvi) noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
	capture quietly reghdfe ndvi trt temp precip i.year, cluster(comm_id year) absorb(cell_id)
	* est sto a5
	outreg2 using "$box/cambodia_ndvi_eval/Results/ndvi_models`prov'.doc", append keep(trt baseline_ndvi temp precip) noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
	capture quietly reghdfe ndvi trt c.trt#c.(plantation_dummy concession_dummy protectedarea_dummy) i.year, cluster(comm_id year) absorb(cell_id)
	* est sto a6
	outreg2 using "$box/cambodia_ndvi_eval/Results/ndvi_models`prov'.doc", append keep(trt c.trt#c.plantation_dummy c.trt#c.concession_dummy c.trt#c.protectedarea_dummy) noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
	
	rm "$box/cambodia_ndvi_eval/Results/ndvi_models`prov'.txt"
	
	}






