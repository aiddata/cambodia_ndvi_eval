

clear all
set more off
set segmentsize 2g
set min_memory 16g

global data "/sciclone/home20/cbaehr/cambodia_gie/data"
global results "/sciclone/home20/cbaehr/cambodia_gie/results"


*global data "C:/Users/cbaehr/Desktop"
*global results "C:/Users/cbaehr/Desktop"


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

***

egen year_min = min(year) if trt1k > 0, by(cell_id)
egen first_trt = mean(year_min), by(cell_id)
gen years_to_trt1 = year - first_trt

levelsof years_to_trt1, loc(levels) sep()

foreach l of local levels{
	local j = `l' + 30
	local label `"`label' `j' "`l'" "'
	}
	
cap la drop years_to_trt1	
la def years_to_trt1 `label'

replace years_to_trt1 = years_to_trt1 + 30
la values years_to_trt1 years_to_trt1

reghdfe ndvi ib30.years_to_trt1 temp precip, cluster(commune year) absorb(cell_id year)

coefplot, xline(8.5) yline(0) vertical omit recast(line) ///
    color(blue) ciopts(recast(rline)  color(blue) lp(dash)) graphregion(color(white)) ///
    bgcolor(white) xtitle("Years to Treatment") ytitle("Treatment effects on NDVI") ///
	title("Time to treatment (0-1km)") ///
	saving("$results/time_to_trt1.gph", replace) ///
	keep(22.years_to_trt1 23.years_to_trt1 24.years_to_trt1 25.years_to_trt1 26.years_to_trt1 27.years_to_trt1 28.years_to_trt1 29.years_to_trt1 30.years_to_trt1 31.years_to_trt1 32.years_to_trt1 33.years_to_trt1 34.years_to_trt1 35.years_to_trt1 36.years_to_trt1 37.years_to_trt1 38.years_to_trt1)

drop year_min first_trt years_to_trt1	

***

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

reghdfe ndvi ib30.years_to_trt2 temp precip, cluster(commune year) absorb(cell_id year)

coefplot, xline(8.5) yline(0) vertical omit recast(line) ///
    color(blue) ciopts(recast(rline)  color(blue) lp(dash)) graphregion(color(white)) ///
    bgcolor(white) xtitle("Years to Treatment") ytitle("Treatment effects on NDVI") ///
	title("Time to treatment (1-2km)") ///
	saving("$results/time_to_trt2.gph", replace) ///
	keep(22.years_to_trt2 23.years_to_trt2 24.years_to_trt2 25.years_to_trt2 26.years_to_trt2 27.years_to_trt2 28.years_to_trt2 29.years_to_trt2 30.years_to_trt2 31.years_to_trt2 32.years_to_trt2 33.years_to_trt2 34.years_to_trt2 35.years_to_trt2 36.years_to_trt2 37.years_to_trt2 38.years_to_trt2)

drop year_min first_trt years_to_trt2

***

egen year_min = min(year) if trt3k > 0, by(cell_id)
egen first_trt = mean(year_min), by(cell_id)
gen years_to_trt3 = year - first_trt

levelsof years_to_trt3, loc(levels) sep()

foreach l of local levels{
	local j = `l' + 30
	local label `"`label' `j' "`l'" "'
	}
	
cap la drop years_to_trt3
la def years_to_trt3 `label'

replace years_to_trt3 = years_to_trt3 + 30
la values years_to_trt3 years_to_trt3

reghdfe ndvi ib30.years_to_trt3 temp precip, cluster(commune year) absorb(cell_id year)

coefplot, xline(8.5) yline(0) vertical omit recast(line) ///
    color(blue) ciopts(recast(rline)  color(blue) lp(dash)) graphregion(color(white)) ///
    bgcolor(white) xtitle("Years to Treatment") ytitle("Treatment effects on NDVI") ///
	title("Time to treatment (2-3km)") ///
	saving("$results/time_to_trt3.gph", replace) ///
	keep(22.years_to_trt3 23.years_to_trt3 24.years_to_trt3 25.years_to_trt3 26.years_to_trt3 27.years_to_trt3 28.years_to_trt3 29.years_to_trt3 30.years_to_trt3 31.years_to_trt3 32.years_to_trt3 33.years_to_trt3 34.years_to_trt3 35.years_to_trt3 36.years_to_trt3 37.years_to_trt3 38.years_to_trt3)

	