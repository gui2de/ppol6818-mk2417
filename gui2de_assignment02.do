//set up for submission 
if c(username) == "jacob" {
    global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username) == "MehriaSaadatKhan" { 
    global wd "/Users/MehriaSaadatKhan/Desktop/ppol6818"
}


// Set global variables for dataset locations
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

//question 1 
use $q1_psle_raw, clear

***************************************
* PART 1: SCHOOL-LEVEL DATA EXTRACTION
***************************************

// Extract school-level information
gen school_name = regexs(1) if regexm(s, "([A-Z ]+) - PS[0-9]+")
gen school_code = regexs(0) if regexm(s, "(PS[0-9]+)")

// Extract number of students
gen num_students = regexs(1) if regexm(s, "WALIOFANYA MTIHANI : ([0-9]+)")
destring num_students, replace

// Extract school average score
gen school_avg = regexs(1) if regexm(s, "WASTANI WA SHULE\s*:\s*([0-9]+\.[0-9]+)")
destring school_avg, replace

// Extract student group classification
gen student_group = 0 if regexm(s, "KUNDI LA SHULE\s*:\s*Wanafunzi chini ya 40")
replace student_group = 1 if regexm(s, "KUNDI LA SHULE\s*:\s*Wanafunzi 40 au zaidi")

// Extract rankings
gen rank_council = regexs(1) if regexm(s, "NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI:\s*([0-9]+)")
destring rank_council, replace

gen rank_region = regexs(1) if regexm(s, "NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA\s*:\s*([0-9]+)")
destring rank_region, replace

gen rank_nation = regexs(1) if regexm(s, "NAFASI YA SHULE KWENYE KUNDI LAKE KITAIFA\s*:\s*([0-9]+)")
destring rank_nation, replace

//after I have the school data now I want to exctract student data from each school
 //for doing that I need to reshape the data from long to wide and then extract all the colunmns for each school and then reshape again appending it to each other. 
 //I could probably use a program to loop and append each instead of long or use program so I dont have to do the reshape, maybe? 
*Q1 (Builds on Stata 1 Bonus Question) 
use $q1_psle_raw, replace 

rename s rawdata
gen cleaned = rawdata
//Insert a delimiter "|||" before each candidate record.
//assuming candidate records start with "PS01"
replace cleaned = subinstr(cleaned, "PS0", "|||PS0", .)

//Remove everything before the first candidate record delimiter.
local pos = strpos(cleaned, "|||")
if `pos' > 0 {
    replace cleaned = substr(cleaned, `pos' + 3, .)
}

split cleaned, parse("|||")
//This creates variables cleaned1, cleaned2, … cleanedN where each should (ideally) be one candidate record.

drop rawdata cleaned schoolcode

gen id = _n // just becasue stata requires an id in the pivot 
reshape long cleaned, i(id) j(rec_num) string

//Create new variables and extract each group via the regex:
gen schoolcode     = ustrregexs(1) if ustrregexm(cleaned, "(PS\d{7})")
gen cand_id        = ustrregexs(1) if ustrregexm(cleaned, "(PS\d{7}-\d{4})")
gen prem_number    = ustrregexs(1) if ustrregexm(cleaned, "(\d{11})")
gen gender         = ustrregexs(1) if ustrregexm(cleaned, ">([MF])<")
gen name           = ustrregexs(1) if ustrregexm(cleaned, "<P>(.*?)</FONT>")
gen grade_kiswahili= ustrregexs(1) if ustrregexm(cleaned, "Kiswahili\s*-\s*([A-Z])")
gen grade_english  = ustrregexs(1) if ustrregexm(cleaned, "English\s*-\s*([A-Z])")
gen grade_maarifa  = ustrregexs(1) if ustrregexm(cleaned, "Maarifa\s*-\s*([A-Z])")
gen grade_hisabati = ustrregexs(1) if ustrregexm(cleaned, "Hisabati\s*-\s*([A-Z])")
gen grade_science  = ustrregexs(1) if ustrregexm(cleaned, "Science\s*-\s*([A-Z])")
gen grade_uraia    = ustrregexs(1) if ustrregexm(cleaned, "Uraia\s*-\s*([A-Z])")
gen grade_average  = ustrregexs(1) if ustrregexm(cleaned, "Average Grade\s*-\s*([A-Z])")

//Drop the temporary variable holding the full candidate text.
drop cleaned* id rec_num

//Given the mismatch kinda extra rows will show up just drop
keep if !missing(cand_id)
//Order variables as desired:
order schoolcode cand_id prem_number gender name grade_kiswahili grade_english grade_maarifa grade_hisabati grade_science grade_uraia grade_average


///////////////////Quesiton 2 
//We have household survey data and population density data of Côte d'Ivoire. Merge departmente-level density data from the excel sheet (CIV_populationdensity.xlsx) into the household data (CIV_Section_O.dta) i.e. add population density column to the CIV_Section_0 dataset.
*** we have two data sets one stata file and one excel with pop density, we have to merge these two to add the population information (department-level) to each household in the household level dataset. 
** department will be the common indentifier for the merge 

use "$wd/week_05/03_assignment/01_data/q2_CIV_Section_0.dta", clear

// Import the population density dataset
import excel "$wd/week_05/03_assignment/01_data/q2_CIV_populationdensity.xlsx", firstrow clear

// Keep only district level rows
keep if regexm(NOMCIRCONSCRIPTION, "^(DEPARTEMENT)")
gen department = ""
replace department = regexs(1) if regexm(NOMCIRCONSCRIPTION, "^DEPARTEMENT.*?([A-Za-zÀ-ÿ-]+)$")
replace department = lower(department) // Convert to lower case

// Rename DENSITEAUKM variable to department_density
rename DENSITEAUKM department_density

save "$wd/week_05/03_assignment/01_data/q2_CIV_populationdensity.dta", replace

// Load the household dataset
use "$wd/week_05/03_assignment/01_data/q2_CIV_Section_0.dta", clear

// Generate a string type department variable
decode b06_departemen, gen(department)

// Merge the dataset by department
merge m:1 department using "$wd/week_05/03_assignment/01_data/q2_CIV_populationdensity.dta", keepusing(department_density)
tab _merge
drop _merge
save "$wd/week_05/03_assignment/01_data/q2_merged_dataset.dta", replace


///////////////////////////////////////////////////////

///Quesiton 3 
//We have the GPS coordinates for 111 households from a particular village. You are a field manager and your job is to assign these households to 19 enumerators (~6 surveys per enumerator per day) in such a way that each enumerator is assigned 6 households that are close to each other (this would reduce the amount of time they spend walking from one house to another.) Manually assigning them for each village will take you a lot of time. Your job is to write an algorithm that would auto assign each household (i.e. add a column and assign it a value 1-19 which can be used as enumerator ID). Note: Your code should still work if I run it on data from another village.

use $q3_GPS, replace  // Load the dataset containing GPS coordinates for households

* Set seed for reproducibility
set seed 145678  // Ensures that results are consistent across different runs

* Store the target number of enumerations
scalar enumerator_target = 6  // Each enumerator should ideally be assigned around 6 households
scalar enumerator_differencebest  = .  // Variable to store the best difference between assigned and target enumeration size
scalar enumerator_iteration = .  // Variable to store the iteration number with the best assignment

* Loop for 1000 iterations of K-means since the starting point is random
* Assignments will vary for each iteration, so we iterate multiple times to find the best solution
forval i = 1/1000 {
    cluster kmeans latitude longitude, k(19) name(enum_`i')  // Perform K-means clustering with 19 clusters
    bysort enum_`i': generate cluster_size_`i' = _N  // Count the number of households assigned to each enumerator
    qui su cluster_size_`i', meanonly  // Compute summary statistics quietly
    scalar enum_diff = abs(r(mean) - enumerator_target)  // Calculate deviation from the target enumeration size

    * If this iteration has a smaller difference, keep it as the best iteration
    if missing(enumerator_differencebest) | enum_diff < enumerator_differencebest {
        scalar enumerator_differencebest = enum_diff  // Update the best difference found so far
        scalar enumerator_iteration = `i'  // Store the iteration number of the best assignment
        tempfile best_enum_results  // Create a temporary file to store the best result
        save `best_enum_results', replace  // Save the best iteration's results
    }
}

* Load the best result from the iteration that had the closest cluster sizes to the target
use `best_enum_results', clear

display enumerator_iteration  // Display the iteration number that gave the best result
local num = enumerator_iteration // Store the best iteration number in a local macro

* Keep relevant variables and rename the final enumerator assignments
keep latitude longitude id age female enum_`num' cluster_size_`num'
rename enum_`num' enum  // Rename the best enumerator assignment column to "enum"

* Display summary of the clusters assigned
tabulate enum  // Show how many households were assigned to each enumerator

//question 4 
* Q4 - Additional Data Cleaning
import excel using "$tz_elec_10_raw", clear  // Import raw election data from an Excel file

* Drop unnecessary columns (G and K) that are not needed
drop G K  

* Standardize variable names by renaming them based on the 5th row of data
foreach var of varlist * {
    rename `var' `=strtoname(`var'[5])'
}

* Remove extra header rows from the imported Excel file
drop if _n < 7  // Drop all rows before row 7, as they contain extra metadata

* Fill down missing values for REGION, DISTRICT, CONSTITUENCY, and WARD
foreach var in REGION DISTRICT COSTITUENCY WARD {
    replace `var' = `var'[_n-1] if `var' == ""
}

* Clean the total votes column by handling "UNOPPOSED" cases
replace TTL_VOTES = "" if TTL_VOTES == "UN OPPOSSED"  // Standardize unopposed cases

destring TTL_VOTES, replace  // Convert TTL_VOTES to numeric format

* Compute total votes and number of candidates per ward
bysort WARD: egen total_votes = total(TTL_VOTES)  // Sum up votes for each ward
bysort WARD: gen total_cands = _N  // Count the number of candidates in each ward

* Keep only relevant columns for analysis
keep REGION DISTRICT COSTITUENCY WARD POLITICAL_PARTY TTL_VOTES total_votes total_cands

duplicates drop  // Remove any duplicate records

* Generate a unique ward ID for accurate data reshaping and merging
egen id = group(REGION DISTRICT COSTITUENCY WARD)  // Create a unique ID for each ward

* Standardize political party names by removing special characters and spaces
replace POLITICAL_PARTY = subinstr(POLITICAL_PARTY, "-", "_", .)
replace POLITICAL_PARTY = subinstr(POLITICAL_PARTY, " ", "", .)

* Preserve relevant summary information for merging later
preserve
keep REGION DISTRICT COSTITUENCY WARD total_votes total_cands id
duplicates drop  // Remove duplicate rows to ensure clean merging
tempfile extras
save `extras'  // Store summary data in a temporary file
restore

* Collapse data to get total votes per political party per ward
collapse (sum) TTL_VOTES, by(id POLITICAL_PARTY)

* Reshape data to wide format with votes for each political party in separate columns
reshape wide TTL_VOTES, i(id) j(POLITICAL_PARTY) string 

* Merge back the ward-level summary data
merge 1:1 id using `extras'

* Order variables for better readability
order REGION DISTRICT COSTITUENCY WARD total_votes total_cands id TTL*

* Rename variables for clarity
rename id ward_id
rename TTL_VOTES* votes_*
rename *, lower  // Convert all variable names to lowercase

drop _merge  // Remove merge indicator column

//question 5

use $Q5, clear  // Load the dataset containing school location information

// We only need a subset of variables, so we keep only relevant columns
keep School Ward Region SN  
rename School school  // Standardizing variable names for consistency
rename Ward ward  
rename Region region  

// Generate a serial number variable from SN for merging later
encode SN, gen(serial)  // Converts categorical serial numbers to numeric format
order ward, a(SN)  // Arrange the dataset so that 'ward' appears after 'SN'

// Save the cleaned school location data as a temporary file
tempfile tanzamia_school  
save `tanzamia_school', replace  

// Now load the PSLE dataset which contains student performance data
clear  // Clear the memory before loading the new dataset

use $Q5_psle, clear  // Load the PSLE dataset

// Standardizing school and region names to match the school location dataset
rename schoolname school  // Rename 'schoolname' to 'school' for consistency
rename region_name region  // Rename 'region_name' to 'region' for consistency
  
// Merge the PSLE dataset with the school location dataset using the generated serial number
merge 1:1 serial using `tanzamia_school'  
* The merge operation successfully added ward information for 17,329 schools. 

// Drop the merge variable as it's no longer needed
drop _merge


//question 6 (didnt have time to do the code but just wrote how would go about this question)
// Load the dataset containing 2015 ward information

// Load the dataset containing 2010 ward information

// Load the dataset that provides the percentage area of 2015 wards overlapping with 2010 wards

// Merge the 2015 ward dataset with the overlap dataset using the ward ID

// Identify wards that remained unchanged between 2010 and 2015

// Identify wards that were split into multiple new wards

// Assign the 2010 ward to each 2015 ward based on the largest percentage overlap

// Validate the matches and check for any wards without a 2010 counterpart

// Save the final dataset with each 2015 ward linked to its 2010 parent ward

// Generate a summary table to analyze ward changes, including how many remained unchanged and how many were split

































