//Stata assignment 3- Mehria 

//Part 1: Sampling noise in a fixed population
//1.Develop some data generating process for data X's and for outcome Y.

* I define a simple linear Data Generating Process (DGP) where:
*    Y = 2 + 3*X + ε
* where:
*    - X is a random variable drawn from a standard normal distribution (mean = 0, SD = 1)
*    - ε (error term) is also drawn from a standard normal distribution
*    - The intercept is 2
*    - The slope (true effect of X on Y) is 3

* This process implies that X has a positive, linear impact on Y.
* The error term represents unobserved variability that affects Y but is not explained by X.
* This setup will be used to generate a fixed synthetic population of 10,000 individuals.

//2.	Write a do-file that creates a fixed population of 10,000 individual observations and generate random X's for them (use set seed to make sure it will always create the same data set). Create the Ys from the Xs with a true relationship and an error source. Save this data set in your Box folder.
clear all
set seed 12345 //Ensures reproducibility same random numbers every time
set obs 10000 //this is our full population 
gen id = _n //create unique id for each person from 1 to 10,000 
gen x = rnormal(0, 1) //generate X values from a normal distribution with mean 0 and sd 1 
gen e = rnormal(0, 1) //error term 
gen y = 2 + 3*x + e //our outcome variable , randomly assigned 3
//Each 1-unit increase in X increases Y by 3, on average."
save "q1_fixedpop.dta", replace

//3.	Write a do-file defining a program that: (a) loads this data; (b) randomly samples a subset whose sample size is an argument to the program; (c) performs a regression of Y on X; and (e) returns the N, beta, SEM, p-value, and confidence intervals into r().
capture program drop sample_regression
program define sample_regression, rclass //remember the results 
    syntax, n(integer) //the sample size we wanna chose, stata will remember what to choose, signals stata to expect an argument 
use "q1_fixedpop.dta", clear 
    sample `n', count //randomly draw a sample of N people from population
    regress y x
   
    //Save regression output into r() so simulate can access it later

    return scalar N     = e(N)        // Actual sample size
    return scalar beta  = _b[x]       // Coefficient estimate on x
    return scalar sem   = _se[x]      // Standard error of the estimate
    return scalar pval = 2 * ttail(e(df_r), abs(_b[x]/_se[x])) // P-value for the x coefficient, That's what your regression table is showing in the P>|t| column — we're grabbing that same info for our simulation.
    
	return scalar ci_lo = _b[x] - invttail(e(df_r), 0.025) * _se[x]  // Lower 95% CI
    return scalar ci_hi = _b[x] + invttail(e(df_r), 0.025) * _se[x]  // Upper 95% CI

end

sample_regression, n(100)

//4.	Using the simulate command, run your program 500 times each at sample sizes N = 10, 100, 1,000, and 10,000. Load the resulting data set of 2,000 regression results into Stata.
//pretend I'm running the same experiment 500 times, each time with a random sample of people. Then I'll collect the slope, standard error, p-value, and confidence interval from each of those runs — and compare how stable they are depending on the sample size

*-----------------------------------------------------------------
//This runs the sample_regression program 500 times for sample sizes 10, 100, 1000, and 10000 using the simulate command.It saves the results for each N in separate files and then combines them into one big dataset for analysis.
*-----------------------------------------------------------------
clear
* -----------------------------
* Simulations for N = 10
* -----------------------------
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
    reps(500) seed(1111): sample_regression, n(10) //run the regression 500 times using a sample size of 10 each time. after each run collects six numbers (sample size, beta, standard error, p-value, confidence intervals)
	//seed allows for results to be reproducible, The seed sets the starting point for Stata's random number generator so that you get the same random results every time you run your code. It ensures your simulations are reproducible. different seeds=different randomness, same seed= repeatable randomness 
	

* Save the results in a file
save "sim_N10.dta", replace


* -----------------------------
* Simulations for N = 100
* -----------------------------
clear 
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
    reps(500) seed(1112): sample_regression, n(100)


save "sim_N100.dta", replace


* -----------------------------
* Simulations for N = 1000
* -----------------------------
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
    reps(500) seed(1113): sample_regression, n(1000)


save "sim_N1000.dta", replace


* -----------------------------
* Simulations for N = 10000
* -----------------------------
simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
    reps(500) seed(1114): sample_regression, n(10000)


save "sim_N10000.dta", replace


* -----------------------------
* Combine all results together
* -----------------------------
use "sim_N10.dta", clear
append using "sim_N100.dta"
append using "sim_N1000.dta"
append using "sim_N10000.dta"

* Save the final combined dataset
save "combined_sim_results.dta", replace

//5.	Create at least one figure and at least one table showing the variation in your beta estimates depending on the sample size, and characterize the size of the SEM and confidence intervals as N gets larger.

use "combined_sim_results.dta", clear

//Analyze how regression results vary with sample size

//Create a boxplot of beta estimates by sample size, creating a box plot that shows the distribution of beta estimate changes with different sample sizes
graph box beta, over(N, label(angle(0))) ///
    yline(3, lpattern(dash) lcolor(pink)) ///
    title("Distribution of Beta Estimates by Sample Size") ///
    ytitle("Estimated Slope (Beta)") ///
    subtitle("True Beta = 3")

//some more visuals- just for practice 
*****preparation step for all visuals 
//Calculate confidence interval width
gen ci_width = ci_hi - ci_lo
collapse (mean) mean_beta=beta mean_sem=sem mean_ci_lo=ci_lo mean_ci_hi=ci_hi ///
         mean_ci_width=ci_width, by(N)

		 
********Line Plot for SE vs Sample Size******************		 
twoway line mean_sem N, ///
    title("Standard Error vs Sample Size") ///
    xtitle("Sample Size") ytitle("Mean Standard Error") ///
    lcolor(pink) lwidth(medium) ///
    xlabel(, format(%9.0g))
	
**********Line plot for CI vs Sample size 
twoway line mean_ci_width N, ///
    title("CI Width vs Sample Size") ///
    xtitle("Sample Size") ytitle("Mean Confidence Interval Width") ///
    lcolor(green) lwidth(medium) ///
    xlabel(, format(%9.0g))

*********Dot plot of Mean beta with errors bars (95% CI)
twoway (rcap mean_ci_hi mean_ci_lo N, lcolor(green)) ///
       (scatter mean_beta N, mcolor(purple) msize(medium)), ///
    title("Mean Beta Estimates with 95% CIs") ///
    yline(3, lpattern(dash) lcolor(pink)) ///
    xtitle("Sample Size") ytitle("Mean Beta") ///
    xlabel(, format(%9.0g))

******Density Plot(one per sample size)**********
	
use "combined_sim_results.dta", clear	
twoway ///
    (kdensity beta if N==10, lcolor(pink)) ///
    (kdensity beta if N==100, lcolor(green)) ///
    (kdensity beta if N==1000, lcolor(orange)) ///
    (kdensity beta if N==10000, lcolor(purple)), ///
    title("Distribution of Beta Estimates by Sample Size") ///
    legend(label(1 "N = 10") label(2 "N = 100") label(3 "N = 1000") label(4 "N = 10000")) ///
    ytitle("Density") xtitle("Beta Estimate") ///
    xline(3, lcolor(black) lpattern(dash))
	
****histogram**
hist beta, by(N)	
//Create a summary table by sample size, so whats the average beta, its sd, average standard error and CI at each sample size 
table N, statistic(mean beta) statistic(sd beta) ///
         statistic(mean sem) statistic(mean ci_lo) statistic(mean ci_hi) ///
//6.	Fully describe your results in your README file, including figures and tables as appropriate.
//


///////////////////////////part 2/////////////////////////////
// Part 2: Sampling noise in an infinite superpopulation

// 1. Define a program to generate new random data each time based on the same DGP
//    (i.e., X and e from standard normals, Y = 2 + 3*X + e)
//    Then regress Y on X and return key statistics
clear all 
capture program drop superpop_regression
program define superpop_regression, rclass
    syntax, n(integer) // input argument: the number of observations to generate

    clear
    set obs `n' // create a new dataset with N observations (this varies each run)

    // Generate X and error term e from standard normal distribution
    gen x = rnormal(0,1)
    gen e = rnormal(0,1)

    // Define the outcome Y using the same DGP: Y = 2 + 3*X + e
    gen y = 2 + 3*x + e

    // Regress Y on X
    regress y x

    // Return key results
    return scalar N     = e(N)
    return scalar beta  = _b[x]
    return scalar sem   = _se[x]
    return scalar pval  = 2 * ttail(e(df_r), abs(_b[x]/_se[x]))
    return scalar ci_lo = _b[x] - invttail(e(df_r), 0.025) * _se[x]
    return scalar ci_hi = _b[x] + invttail(e(df_r), 0.025) * _se[x]
end

// Step 2: Simulate 500 replications for each of 26 sample sizes
// Includes: First 20 powers of 2 (from 4 to 2,097,152) + common powers of 10

// Define the program 
* program define superpop_regression, rclass ...
*   (from previous code block)



// Create local macro with 26 sample sizes
// → First 20 powers of 2 + N = 10, 100, 1000, 10000, 100000, 1000000
local sizes 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 ///
            131072 262144 524288 1048576 2097152 ///
            10 100 1000 10000 100000 1000000

// Loop through each sample size and simulate 500 samples
foreach n of local sizes {
    display "Running 500 simulations for N = `n'"
    
    simulate N=r(N) beta=r(beta) sem=r(sem) pval=r(pval) ///
             ci_lo=r(ci_lo) ci_hi=r(ci_hi), ///
             reps(500) seed(`=1110 + `n''): superpop_regression, n(`n')
             
    // Save each simulated dataset by sample size
    save "superpop_sim_N`n'.dta", replace
}

clear
use "superpop_sim_N4.dta", clear

foreach n in 8 10 16 32 64 100 128 256 512 1000 1024 2048 4096 8192 10000 ///
              16384 32768 65536 131072 262144 524288 1048576 2097152 ///
              100000 1000000 {
    append using "superpop_sim_N`n'.dta"
}

save "superpop_combined_sim_results.dta", replace


// 4. Create plots and summary statistics to visualize simulation results

use "superpop_combined_sim_results.dta", clear

// Group into a manageable number of bins for display
hist beta, by(N, total note("") compact col(4)) ///
    bin(30) ///
    title("Histogram of Beta Estimates by Sample Size") ///
    xtitle("Beta Estimate") ytitle("Frequency")


graph box beta, over(N, label(angle(45))) ///
    title("Boxplot of Beta Estimates by Sample Size") ///
    ytitle("Estimated Beta") ///
    yline(3, lpattern(dash) lcolor(pink))
	
graph export "boxplot_part2.png", replace

// Optional: restrict to fewer sample sizes to keep the plot readable
twoway ///
    (kdensity beta if N==10, lcolor(pink)) ///
    (kdensity beta if N==100, lcolor(blue)) ///
    (kdensity beta if N==1000, lcolor(green)) ///
    (kdensity beta if N==10000, lcolor(orange)) ///
    (kdensity beta if N==1000000, lcolor(purple)), ///
    title("Density of Beta Estimates by Sample Size") ///
    xtitle("Beta Estimate") ytitle("Density") ///
    xline(3, lcolor(black) lpattern(dash)) ///
    legend(label(1 "N=10") label(2 "N=100") label(3 "N=1,000") ///
           label(4 "N=10,000") label(5 "N=1,000,000"))


// Step 1: Create a variable for CI width
gen ci_width = ci_hi - ci_lo

// Step 2: Collapse to summarize results by sample size
collapse (mean) mean_beta=beta mean_sem=sem mean_ci_lo=ci_lo mean_ci_hi=ci_hi ///
         mean_ci_width=ci_width, by(N)

// Step 3: Format the table for display
list N mean_beta mean_sem mean_ci_lo mean_ci_hi mean_ci_width, sep(0)


//visualize part 1 and 2 comparison

use "combined_sim_results.dta", clear //This is from Part 1
gen ci_width = ci_hi - ci_lo
collapse (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width ///
         mean_ci_lo=ci_lo mean_ci_hi=ci_hi, by(N)
gen source = "Fixed Population"
save "part1_summary.dta", replace



use "superpop_combined_sim_results.dta", clear
gen ci_width = ci_hi - ci_lo
collapse (mean) mean_beta=beta mean_sem=sem mean_ci_width=ci_width ///
         mean_ci_lo=ci_lo mean_ci_hi=ci_hi, by(N)
gen source = "Superpopulation"
save "part2_summary.dta", replace


use "part1_summary.dta", clear
append using "part2_summary.dta"
save "combined_part1_part2_summary.dta", replace



twoway (line mean_sem N if source=="Fixed Population", lcolor(blue) lpattern(solid)) ///
       (line mean_sem N if source=="Superpopulation", lcolor(red) lpattern(dash)), ///
    title("Standard Error vs Sample Size") ///
    legend(order(1 "Fixed Population" 2 "Superpopulation")) ///
    xtitle("Sample Size") ytitle("Mean Standard Error") ///
    xlabel(, format(%9.0g))


twoway (line mean_ci_width N if source=="Fixed Population", lcolor(blue) lpattern(solid)) ///
       (line mean_ci_width N if source=="Superpopulation", lcolor(red) lpattern(dash)), ///
    title("CI Width vs Sample Size") ///
    legend(order(1 "Fixed Population" 2 "Superpopulation")) ///
    xtitle("Sample Size") ytitle("Mean Confidence Interval Width") ///
    xlabel(, format(%9.0g))

twoway ///
  (rcap mean_ci_hi mean_ci_lo N if source=="Fixed Population", lcolor(blue)) ///
  (scatter mean_beta N if source=="Fixed Population", mcolor(blue)) ///
  (rcap mean_ci_hi mean_ci_lo N if source=="Superpopulation", lcolor(red)) ///
  (scatter mean_beta N if source=="Superpopulation", mcolor(red)), ///
  title("Mean Beta Estimates with 95% CIs") ///
  yline(3, lcolor(black) lpattern(dash)) ///
  legend(order(2 "Fixed Pop" 4 "Superpop")) ///
  xtitle("Sample Size") ytitle("Mean Beta") ///
  xlabel(, format(%9.0g))

