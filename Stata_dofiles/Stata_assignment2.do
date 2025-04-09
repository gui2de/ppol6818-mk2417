# Stata Assignment - PPOL 6818

## Setup for Submission
```stata
if c(username) == "jacob" {
    global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username) == "MehriaSaadatKhan" { 
    global wd "/Users/MehriaSaadatKhan/Desktop/ppol6818"
}
```

## Global Variables for Dataset Locations
```stata
global q1_psle_raw "$wd/week_05/03_assignment/01_data/q1_psle_student_raw.dta" 
global q2_CIV_Section_0 "$wd/week_05/03_assignment/01_data/q2_CIV_Section_0.dta"
global CIV_populationdensity "$wd/week_05/03_assignment/01_data/CIV_populationdensity.dta"
global q3_GPS "$wd/week_05/03_assignment/01_data/q3_GPS.dta"
global tz_elec_10_clean "$wd/week_05/03_assignment/01_data/Tz_elec_10_clean.dta"
global tz_elec_15_clean "$wd/week_05/03_assignment/01_data/Tz_elec_15_clean.dta"
global tz_gis "$wd/week_05/03_assignment/01_data/Tz_GIS_2015_2010_intersection.dta"
global tz_elec_10_raw "$wd/week_05/03_assignment/01_data/q4_Tz_election_2010_raw.xls"
global tz_elec_temp "$wd/week_05/03_assignment/01_data/q4_Tz_election_template.dta"
global q5_psle_data "$wd/week_05/03_assignment/01_data/q5_psle_2020_data.dta"
global Q5 "$wd/week_05/03_assignment/01_data/q5_school_location.dta"
```

---

# Question 1: School-Level Data Extraction
```stata
use $q1_psle_raw, clear

// Extract school-level information
gen school_name = regexs(1) if regexm(s, "([A-Z ]+) - PS[0-9]+")
gen school_code = regexs(0) if regexm(s, "(PS[0-9]+)")

gen num_students = regexs(1) if regexm(s, "WALIOFANYA MTIHANI : ([0-9]+)")
destring num_students, replace

gen school_avg = regexs(1) if regexm(s, "WASTANI WA SHULE\s*:\s*([0-9]+\.[0-9]+)")
destring school_avg, replace

gen student_group = 0 if regexm(s, "KUNDI LA SHULE\s*:\s*Wanafunzi chini ya 40")
replace student_group = 1 if regexm(s, "KUNDI LA SHULE\s*:\s*Wanafunzi 40 au zaidi")

gen rank_council = regexs(1) if regexm(s, "NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI:\s*([0-9]+)")
destring rank_council, replace

gen rank_region = regexs(1) if regexm(s, "NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA\s*:\s*([0-9]+)")
destring rank_region, replace

gen rank_nation = regexs(1) if regexm(s, "NAFASI YA SHULE KWENYE KUNDI LAKE KITAIFA\s*:\s*([0-9]+)")
destring rank_nation, replace
```

---

# Question 2: Merging Household Survey Data with Population Density
```stata
use "$wd/week_05/03_assignment/01_data/q2_CIV_Section_0.dta", clear

import excel "$wd/week_05/03_assignment/01_data/q2_CIV_populationdensity.xlsx", firstrow clear
keep if regexm(NOMCIRCONSCRIPTION, "^(DEPARTEMENT)")
gen department = ""
replace department = regexs(1) if regexm(NOMCIRCONSCRIPTION, "^DEPARTEMENT.*?([A-Za-zÀ-ÿ-]+)$")
replace department = lower(department)
rename DENSITEAUKM department_density
save "$wd/week_05/03_assignment/01_data/q2_CIV_populationdensity.dta", replace

use "$wd/week_05/03_assignment/01_data/q2_CIV_Section_0.dta", clear
decode b06_departemen, gen(department)
merge m:1 department using "$wd/week_05/03_assignment/01_data/q2_CIV_populationdensity.dta", keepusing(department_density)
tab _merge
drop _merge
save "$wd/week_05/03_assignment/01_data/q2_merged_dataset.dta", replace
```

---

# Question 3: Assigning Households to Enumerators Using GPS Data
```stata
use $q3_GPS, replace
set seed 145678 
forval i = 1/1000 {
    cluster kmeans latitude longitude, k(19) name(enum_`i')  
    bysort enum_`i': generate cluster_size_`i' = _N  
    qui su cluster_size_`i', meanonly  
    scalar enum_diff = abs(r(mean) - 6)  
    if missing(enumerator_differencebest) | enum_diff < enumerator_differencebest {
        scalar enumerator_differencebest = enum_diff  
        scalar enumerator_iteration = `i'  
        tempfile best_enum_results  
        save `best_enum_results', replace  
    }
}

use `best_enum_results', clear
rename enum_`enumerator_iteration' enum  
tabulate enum  
```

---

# Question 4: Cleaning Election Data
```stata
import excel using "$tz_elec_10_raw", clear
drop G K  
foreach var of varlist * {
    rename `var' `=strtoname(`var'[5])'
}
drop if _n < 7  
foreach var in REGION DISTRICT COSTITUENCY WARD {
    replace `var' = `var'[_n-1] if `var' == ""
}
destring TTL_VOTES, replace  
```

---

# Question 5: Merging PSLE Data with School Locations
```stata
use $Q5, clear  
keep School Ward Region SN  
rename School school  
rename Ward ward  
rename Region region  
encode SN, gen(serial)  
order ward, a(SN)  
tempfile tanzamia_school  
save `tanzamia_school', replace  
use $Q5_psle, clear  
rename schoolname school  
rename region_name region  
merge 1:1 serial using `tanzamia_school'  
drop _merge  
```

---

# Question 6: Ward Mappings (Outline Only)
1. Load datasets for 2010 and 2015 ward boundaries.
2. Merge datasets using ward ID and identify unchanged wards.
3. Assign 2010 wards to 2015 wards based on highest overlap.
4. Validate and save the final dataset.
5. Generate a summary table to analyze ward changes.

---
