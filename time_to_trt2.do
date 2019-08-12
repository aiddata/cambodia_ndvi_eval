
clear all
set more off
set segmentsize 2g
set min_memory 16g

global data "/sciclone/home20/cbaehr/cambodia_gie/data"
global results "/sciclone/home20/cbaehr/cambodia_gie/results"

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

compress

drop if missing(ndvi) | missing(trt) | missing(commune)



egen year_min = min(year) if trt2k > 0, by(cell_id)
egen first_trt = mean(year_min), by(cell_id)
gen years_to_trt2 = year - first_trt

levelsof years_to_trt2, loc(levels) sep()

foreach l of local levels{
	local j = `l' + 30
	local label `"`label' `j' "`l'" "'
	}
	
cap la drop years_to_trt2	
la def years_to_trt2 `label'

replace years_to_trt2 = years_to_trt2 + 30
la values years_to_trt2 years_to_trt2


reghdfe ndvi ib30.years_to_trt2 temp precip, cluster(commune year) absorb(cell_id year) pool(10)

coefplot, xline(5) yline(0) vertical omit base recast(line) ///
    color(blue) ciopts(recast(rline)  color(blue) lp(dash)) graphregion(color(white)) ///
    bgcolor(white) xtitle("Years to Treatment") ytitle("Treatment effects on NDVI") ///
	title("Time to treatment (1-2km)") ///
	saving("$results/time_to_trt2.gph", replace) ///
	keep(26.years_to_trt2 27.years_to_trt2 28.years_to_trt2 29.years_to_trt2 30.years_to_trt2 31.years_to_trt2 32.years_to_trt2 33.years_to_trt2 34.years_to_trt2 35.years_to_trt2 36.years_to_trt2 37.years_to_trt2 38.years_to_trt2 39.years_to_trt2 40.years_to_trt2)








