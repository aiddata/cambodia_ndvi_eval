
global loc "/Users/christianbaehr/Desktop"

import delimited "$loc/time_to_trt1_trimmed.csv", clear

regress coef time if time < 0
predict a1

twoway (line coef time, lcolor(blue)) ///
	(line ci1 time, lcolor(blue) lpattern(dash)) /// 
	(line ci2 time, lcolor(blue) lpattern(dash)) ///
	(lfit coef time if time < 0, lcolor(red)) ///
	(line a1 time, lcolor(red) lpattern(dot)) ///
	(lfit coef time if time > 0, lcolor(red)), ///
	xline(0, lcolor(black)) yline(0, lcolor(black)) xlabel(-4(1)10) legend(off) graphregion(fcolor(white))  ///
	title("Time to Treatment (0-1km)") xtitle("Years to Treatment") ytitle("Treatment Effects on NDVI")

graph export "$area/time_to_trt1.png", replace

***

import delimited "$area/time_to_trt2.csv", clear

regress coef time if time <= 0
predict a1

twoway (line coef time, lcolor(blue)) ///
	(line ci1 time, lcolor(blue) lpattern(dash)) /// 
	(line ci2 time, lcolor(blue) lpattern(dash)) ///
	(lfit coef time if time <= 0, lcolor(red)) ///
	(line a1 time, lcolor(red) lpattern(dot)) ///
	(lfit coef time if time >= 0, lcolor(red)), ///
	xline(0, lcolor(black)) yline(0, lcolor(black)) xlabel(-4(1)10) legend(off) graphregion(fcolor(white))  ///
	title("Time to Treatment (1-2km)") xtitle("Years to Treatment") ytitle("Treatment Effects on NDVI")

graph export "$area/time_to_trt2.png", replace

***

import delimited "$area/time_to_trt3.csv", clear

regress coef time if time <= 0
predict a1

twoway (line coef time, lcolor(blue)) ///
	(line ci1 time, lcolor(blue) lpattern(dash)) /// 
	(line ci2 time, lcolor(blue) lpattern(dash)) ///
	(lfit coef time if time <= 0, lcolor(red)) ///
	(line a1 time, lcolor(red) lpattern(dot)) ///
	(lfit coef time if time >= 0, lcolor(red)), ///
	xline(0, lcolor(black)) yline(0, lcolor(black)) xlabel(-4(1)10) legend(off) graphregion(fcolor(white))  ///
	title("Time to Treatment (2-3km)") xtitle("Years to Treatment") ytitle("Treatment Effects on NDVI")

graph export "$area/time_to_trt3.png", replace


