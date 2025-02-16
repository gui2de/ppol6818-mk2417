//Stata Assignment 1 

//set up for submission 
if c(username) == "jacob" {
    global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username) == "MehriaSaadatKhan" { // Replace with your username
    global wd "/Users/MehriaSaadatKhan/Desktop/ppol6818"
}

// Set global variables for dataset locations
global q1_school "$wd/week_03/04_assignment/01_data/q1_data/school.dta"
global q2_village "$wd/week_03/04_assignment/01_data/q2_village_pixel.dta"
global q3_proposal "$wd/week_03/04_assignment/01_data/q3_proposal_review.dta"
global q4_excel "$wd/week_03/04_assignment/01_data/q4_Pakistan_district_table21.xlsx"
global q5_html "$wd/week_03/04_assignment/01_data/q5_Tz_student_roster_html.dta"

// Set working directory dynamically
cd "$wd/week_03/04_assignment"

****************************
// quesion 1 
cd "$wd/week_03/04_assignment"
use teacher.dta, clear
use student.dta, clear // master file 
rename primary_teacher teacher // to ensure both has the same names for merge to work
merge m:1 teacher using teacher.dta // merge both so we align the schools with students so then we can later identify those school by regions 
save assignment1.dta, replace // save as a new file just to avoid confusion later 
drop _merge // drop so it can work for all other merges each time 

use assignment1.dta, clear
drop _merge
merge m:1 school using school.dta // merge to now identify each school by region so we can summarize attendance by location 
sum attendance if loc == "South" 
drop _merge

merge m:1 subject using subject.dta //subject data tells us which subjects are tested or not  
drop _merge

count if level == "High" & tested == 1
count if level == "High" 

scalar proportion = 610 / 1379 // divide total high schools that has teachers that are tested divide by total high schools
display proportion

by school, sort: egen mean_attendance = mean(attendance) //to calculate mean for each school asn assign same attendace value to all rows belonging to that school 
duplicates drop school, force // in order to get a precise list, removed all the duplicates 
list school mean_attendance if level == "Middle"
clear
********************************************
//question 2 
use "$wd/q2_village_pixel.dta", clear
//identifying if each payout is consistent within each pixel 
gen pixel_consistent = (payout == payout[1]) //This checks if the payout for each observation within a pixel is equal to the payout of the first household in that pixel. If they are equal, pixel_consistent will be 1, and if not, it will be 0.

replace pixel_consistent = 0 if pixel_consistent == 0 //0 changes made meaning they were all consistent 
tab pixel_consistent // to ensure its a dummy variable 

 
gen pixel_change = (pixel != pixel[_n-1]) 
 // we are basically asking if the neihbhourhood of the house is the same as the one before it. if the current house is different than the previous we mark it with 1 meaning yes its different and if its not in the same neihbhourhood then we mark it with 0. if even one is different then we say it belongs to different neighbourhoods. the command total adds up the differences in neighbourhoods counts the changes.  


gen category =.

replace category = 1 if pixel_change == 0 // villages with households in the same pixel 

replace category = 2 if pixel_change == 1 & payout == payout[1] // villages in multiple pixels where all households have the same payout status

replace category = 3 if pixel_change  == 1 & payout != payout[1] // villages is multiple pixels where households do not have same (which is why we use! to negate) payout status. In other words they have different payouts and live in multiple pixels. 

count if category == 3 //to count how many villages have an issue for the experiment. 
clear 
***********************************
//Question 3  
use "$wd/q3_proposal_review.dta", clear 

//normalize the score wrt each reviewer (using unique ids) before calculating the average score

// Normalize the scores for each reviewer to adjust for different reviewew biases
// rename variables by netid and score 
rename Rewiewer1 netid1
rename Reviewer2 netid2 
rename Reviewer3 netid3
rename Review1Score score1
rename Reviewer2Score score2 
rename Reviewer3Score score3 

keep netid* score* proposal_id

//reshape the dataset from wide to long format 
reshape long netid score, i(proposal_id) j(reviewer_no)
 

//Reviewer 1: Normalize Review1Score with respect to each reviewer 
bysort netid: egen mean_score = mean(score)
bysort netid: egen sd_score = sd(score)
gen stand_score = (score - mean_score) / sd_score

sort proposal_id

drop mean_score sd_score score 

// reshape the dataset from long to wide format 
reshape wide netid stand_score, i(proposal_id) j(reviewer_no)

// now that we have normalized the score we now have to compute average standardize score for each proposal
egen avgstand_score = rowmean(stand_score1 stand_score2 stand_score3)

//Rank the proposals based on the average normalized score
egen rank = rank(avgstand_score), field

sort rank 
list proposal_id rank avgstand_score if rank <= 50

******************************************

//question 4 

//Question4
global excel_t21 "$wd//week_03/04_assignment/01_data/q4_Pakistan_district_table21.xlsx"

clear

*setting up an empty tempfile
tempfile table21
save `table21', replace emptyok

*Run a loop through all the excel sheets (135) this will take 1-5 mins because it has to import all 135 sheets, one by one
forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring 
	//import
	display as error `i' //display the loop number

	keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND" )==1 //keep only those rows that have "18 AND"
	*I'm using regex because the following code won't work if there are any trailing/leading blanks
	*keep if TABLE21PAKISTANICITIZEN1== "18 AND" 
	keep in 1 //there are 3 of them, but we want the first one
	rename TABLE21PAKISTANICITIZEN1 table21

	
	gen table=`i' //to keep track of the sheet we imported the data from
	append using `table21' 	
	save `table21',replace  //saving tempfile so that we dont lose any data	 

 }
*load the tempfile
capture use `table21', clear
*fix column width issue so that it's easy to eyeball the data
format %40s table21 B C D E F G H I J K L M N O P Q R S T U V W X Y  Z AA AB AC

order table, last
sort table
destring B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC, replace ignore(" -")

save clean.dta, replace

//Until this part, all the data are imported correctly. Now I need to clean the data, handle missing values and arrange the columns: 

clear
use clean.dta, clear


// Step 1: Identify relevant columns
local main_cols "table21 table"
local data_cols "B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC"

// Step 2: Generate 12 empty columns for consolidated values
forvalues i = 1/12{
    gen value`i' = .
}

// Step 3: Loop through `data_cols` and fill `value1` to `value12`
foreach var of local data_cols {
    forvalues i = 1/12 {
        replace value`i' = `var' if missing(value`i') & !missing(`var')  // Copy first available value
        replace `var' = . if value`i' == `var'  // Set the copied value to missing in the original column
    }
}

	drop B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC 

rename (value1 value2 value3 value4 value5 value6 value7 value8 value9 value10 value11 value12) ///
    (total_pop cnic_obtained cnic_not_obtained male_population male_cnic_obtained male_cnic_not_obtained female_population demale_cnic_obtained female_cnic_not_obtained transgender_population transgender_cnic_obtained trans_cnic_not_obtained)   
		
//Save the cleaned dataset
save final_cleaned.dta, replace


//check for duplicates
bysort table: gen order = _n //gen a new variable of occurence for each "table" value 
drop if table == 135 & order == 1 //keep only the second occurence if "table"== 135
drop order 

//making it easier to eyeball data 
order table, first 

*fix column width issue so that it's easy to eyeball the data
format %40s table21

rename table district_code 
rename table21 age_group 

br 

*****************************************************
//question 5 
use "$wd/week_03/04_assignment/01_data/q5_Tz_student_roster_html.dta"

//understand the data:
describe
 
display s[1]

//first remove the parts that contain HTML tags (<html>) and so on
replace s = regexr(s, "<[^>]+>", "")

list s if _n == 1

//generating the variables and handing string issues all in two line of codes:

//generating school name: 
gen school_name = regexs(1) if regexm(s, "([A-Z ]+) - PS[0-9]+")
gen school_code = regexs(0) if regexm(s, "(PS[0-9]+)")

//generating student number: 
gen num_students = regexs(1) if regexm(s, "WALIOFANYA MTIHANI : ([0-9]+)")
destring num_students, replace

//generating school average 
gen school_avg = regexs(1) if regexm(s, "WASTANI WA SHULE\s*:\s*([0-9]+\.[0-9]+)")
destring school_avg, replace

//generating student group 
gen student_group = 0 if regexm(s, "KUNDI LA SHULE\s*:\s*Wanafunzi chini ya 40")
replace student_group = 1 if regexm(s, "KUNDI LA SHULE\s*:\s*Wanafunzi 40 au zaidi")

//generating council ranking 
gen rank_council = regexs(1) if regexm(s, "NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI:\s*([0-9]+)")
destring rank_council, replace

//generating region ranking 
gen rank_region = regexs(1) if regexm(s, "NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA\s*:\s*([0-9]+)")
destring rank_region, replace

//generating nation ranking 
gen rank_nation = regexs(1) if regexm(s, "NAFASI YA SHULE KWENYE KUNDI LAKE KITAIFA\s*:\s*([0-9]+)")
destring rank_nation, replace

//dropping the s column and keeping the rest and saving the dataset. 
keep school_name school_code num_students school_avg student_group rank_council rank_region rank_nation
save "cleaned_school_data.dta", replace













