//Stata assignment 4 
//Mehria 

//Part 1: Power calculations for individual-level randomization
//1.Develop a data generating process for some Y that is normally disturbed around 0 with standard deviation of 1.

//Set sample size and seed for reproducibility
clear all
set seed 12345
set obs 1000  // we start with 1000 observations

//Generate a baseline outcome Y
gen Y = rnormal(0, 1)  // Y ~ N(0, 1)

//Quick summary to verify
summarize Y
histogram Y, normal title("Distribution of Y ~ N(0,1)")



//2.The average treatment effect should be 0.1 sd (with the effects being uniformly distributed between 0.0 – 0.2 sd)

//Assign treatment to 50% of the sample, randomly splits sample into half treated half control
gen treat = runiform() < 0.5  // 0 = control, 1 = treatment

//Generate heterogeneous treatment effects from U[0.0, 0.2], allows treatment effects to vary — average effect is 0.1 SD by construction.
gen treat_effect = runiform(0, 0.2)

//Add treatment effect to Y only for treated units

replace Y = Y + treat_effect if treat == 1

//Quick checks
summarize Y treat_effect treat

// Add descriptive labels
label variable Y "Simulated outcome (Y)"
label variable treat "Treatment assignment (1 = treated, 0 = control)"
label variable treat_effect "Individual treatment effect (drawn from U[0, 0.2])"


//3.	The proportion of individuals receiving treatment should be 0.5 (i.e. half in control, and half in treatment) Calculate the number of individuals required to reach 80% power when you are trying to detect 0.1 sd treatment effect.

power twomeans 0 0.1, sd(1) power(0.8)

****twomeans-compares two independent groups (control vs treatment)
****0 0.1 means of control and treatment groups so difference is 0.1
****sd(1) assumes sd=1 from your DGP
****power 0.8 you want 80% chance of detecting that 0.1 effect 


//4.	Now assume, 15% of the sample will attrite (assume similar attrition rates in control and treatment arms.) How does this change your sample size calculations from the previous part?


*********To detect a 0.1 SD treatment effect with equal allocation (50/50), we need:

****3,142 total participants
*****1,571 in treatment
*****1,571 in control
******This is our benchmark without attrition or cost constraints.


//Since 15% of sample will drop out, only 85% will remain. To compensate, we need to inflate the required sample size

***********************
*adjusted N= required N/ 1- attrition rate 
***********************

display ceil(3142 / 0.85)

//Adjusted total sample size with 15% attrition
display ceil(3142 / 0.85)

//Calculate 50% treated
display round(0.50 * ceil(3142 / 0.85))

// Calculate 50% control
display round(0.50 * ceil(3142 / 0.85))
display "Treated: " round(0.5 * ceil(3142 / 0.85)) ", Control: " round(0.5 * ceil(3142 / 0.85))
* this gives us 3697, so we will need 1849 treated and 1849 control 


//5.	Now assume the intervention is very expensive and we can only afford to provide this specific treatment to 30% of the sample. How would this change the sample size needed for 80% power.


power twomeans 0 0.1, sd(1) power(0.8) nratio(0.43)

*When treatment is assigned unequally (e.g., 30% treated, 70% control), power decreases unless you increase the total sample size. To correct for that, we use the nratio() option in the power command to tell stata treatment group will be 0.43 timesthe size of the control group


*To detect a 0.1 SD effect with 80% power, when only 30% of the sample receives treatment, you need:

*3,736 total participants
*2,612 in control (≈ 70%)
*1,124 in treatment (≈ 30%)


****adjust for attrition
display ceil(3736 / 0.85)

display "Treated: " round(0.30 * ceil(3736 / 0.85)) ", Control: " round(0.70 * ceil(3736 / 0.85))

*If only 30% of individuals can receive treatment, and 15% of sample will attrite, we need:

*4,396 total participants
//~1,319 treated
//~3,077 control




// =========================================================
// Part 2: Power Calculations for Cluster Randomization
// =========================================================


// =========================================================
// Question 1: Develop a data generating process for Y
// =========================================================

clear all
set seed 67890

// Set number of schools
set obs 123
gen school_id = _n

// Simulate ICC structure (30% between-school variance)
local rho = 0.3
local sigma2 = 1
local sigma_cluster = sqrt(`rho' * `sigma2')
gen u_school = rnormal(0, `sigma_cluster')

// Random treatment assignment at the school level
gen treat_school = runiform() < 0.5

// Number of students per school
local cluster_size = 134
expand `cluster_size'
bysort school_id (u_school): gen student_id = _n

// Simulate student-level residual variation
local sigma_indiv = sqrt(1 - `rho')
gen e_student = rnormal(0, `sigma_indiv')

// Generate outcome variable Y
gen Y = u_school + e_student

gen treat_effect = runiform(0.15, 0.25)
replace Y = Y + treat_effect if treat_school == 1

// Label variables
label variable Y "Simulated math score (post-treatment)"
label variable treat_school "Treatment assignment at school level (1 = treated)"
label variable treat_effect "Individual treatment effect (U[0.15, 0.25])"

// Summary checks
count
summarize Y
mean Y, over(treat_school)

/*
Summary: Simulated 123 schools with 134 students each.
ICC ≈ 0.3. Treatment assigned at school-level. Treatment effects drawn from U(0.15, 0.25).
*/


// =========================================================
// Question 2: Create a flexible simulation program
// =========================================================


program define simulate_cluster_power, rclass
    syntax , clusters(integer) clustersize(integer)

    clear
    local rho = 0.3
    local sigma2 = 1
    local sigma_cluster = sqrt(`rho' * `sigma2')
    local sigma_indiv = sqrt(1 - `rho')

    set obs `clusters'
    gen school_id = _n
    gen u_school = rnormal(0, `sigma_cluster')
    gen treat = runiform() < 0.5

    expand `clustersize'
    bysort school_id (u_school): gen student_id = _n

    gen e_student = rnormal(0, `sigma_indiv')
    gen Y = u_school + e_student
    replace Y = Y + 0.2 if treat == 1

    regress Y treat, cluster(school_id)
    matrix b = r(table)
    return scalar sig = (b[4,1] < 0.05)
    return scalar tstat = b[3,1]
    return scalar pval  = b[4,1]
end


// =========================================================
// Question 3: Simulate ICC ≈ 0.3 (already built into above)
// =========================================================
// The above setup uses rho = 0.3 with correctly computed variance components.


// =========================================================
// Question 4: Evenly divide schools and generate 0.2 SD effect
// =========================================================
// Already done in function simulate_cluster_power — effect is 0.2 applied to treated schools.


// =========================================================
// Question 5: Hold clusters = 200, vary cluster size (powers of 2)
// =========================================================

clear
set seed 22222
local sims = 1000
local clust = 200
tempfile allsim
postfile sim tstat sig cluster_size using `allsim', replace

foreach csize in 2 4 8 16 32 64 128 256 512 1024 {
    display "Simulating for cluster size `csize'..."
    forvalues i = 1/`sims' {
        quietly simulate_cluster_power, clusters(`clust') clustersize(`csize')
        post sim (r(tstat)) (r(sig)) (`csize')
    }
}
postclose sim

use `allsim', clear
vioplot tstat, over(cluster_size) vertical
graph export "vioplot_cluster_size.png", replace

/*
INTERPRETATION: Violin Plot of t-statistics by Cluster Size

- Shows how the distribution of t-statistics changes as cluster size increases.
- Small clusters (e.g. 2, 4) produce highly variable t-stats often far below 1.96 (significance threshold).
- As cluster size increases, distributions narrow and center more around the 1.96 line.
- Larger clusters = better precision, more consistent estimates.
*/

collapse (mean) power=sig, by(cluster_size)
list

twoway (line power cluster_size), 
    xlabel(2 4 8 16 32 64 128 256 512 1024) 
    title("Power vs. Cluster Size (200 Clusters)") 
    yline(0.8, lpattern(dash)) 
    xtitle("Cluster Size (log scale)") 
    ytitle("Estimated Power")
graph export "power.png", replace

/*
INTERPRETATION: Line Plot of Power vs. Cluster Size

- Holding clusters constant at 200, this shows how power improves with cluster size.
- Power sharply increases from 2 to ~64 students/cluster, then levels off.
- Recommendation: Use a cluster size ≥ 64 if budget allows, to achieve higher power.
*/


// =========================================================
// Diagnostic: Approximate Power Calculation (Analytical)
// Using power twomeans with design effect
// =========================================================

// Assumptions:
local effect_perfect = 0.2     // True treatment effect
local effect_70pct    = 0.2*0.7  // Adjusted effect with 70% compliance
local sigma = 1                // Standard deviation of outcome
local rho = 0.3                // Intra-cluster correlation
local m = 15                   // Students per school (cluster size)
local DEFF = 1 + (`m' - 1)*`rho'  // Design effect

display "Design effect: " `DEFF'

// --------------------
// Perfect compliance
// --------------------
power twomeans 0 `effect_perfect', sd(`sigma') power(0.8)
display "Unadjusted N (individuals): " r(N)
display "Adjusted N (clusters): " r(N)/`m'*`DEFF'

// --------------------
// 70% compliance
// --------------------
power twomeans 0 `effect_70pct', sd(`sigma') power(0.8)
display "Unadjusted N (individuals, 70% compliance): " r(N)
display "Adjusted N (clusters, 70% compliance): " r(N)/`m'*`DEFF'

/*
INTERPRETATION:

This block uses analytical power calculations to get a rough lower bound 
on the number of **individuals** needed for 80% power, assuming a simple 
randomized design. Then we adjust for clustering using the design effect.

This is not a replacement for simulation, but provides a good reference point:

- For perfect compliance (0.2 SD effect), this gives ~N clusters.
- For 70% compliance, we adjust the effect size and re-calculate.

Compare these values to your simulation-based estimates (~300 and ~566 schools).
You should find the analytical numbers are lower, as they don't account 
for multi-level structure or noise from random assignment.
*/

/*
Comparison with `power twomeans`:

We used `power twomeans` as a quick analytical check to estimate sample size under 70% compliance. 
It suggested ~556 clusters are needed (after adjusting for DEFF). This is very close to our 
simulation-based result (~566 clusters), which accounts for ICC, noncompliance, and finite sample noise.

This confirms our simulation is well-calibrated, while also showing that analytical tools like `power twomeans`
can provide useful ballpark estimates, though they may slightly underestimate required sample sizes in complex designs.
*/





// =========================================================
// Question 6: Hold cluster size = 15, vary number of schools
// =========================================================

clear
set seed 44444
local sims = 500
local clustsize = 15
tempfile school_sim
postfile pwr2 clusters tstat sig using `school_sim', replace

foreach clust in 10 20 30 40 50 60 70 80 90 100 120 140 160 180 200 220 240 260 280 300 {
    display "Simulating for `clust' schools..."
    forvalues i = 1/`sims' {
        quietly simulate_cluster_power, clusters(`clust') clustersize(`clustsize')
        post pwr2 (`clust') (r(tstat)) (r(sig))
    }
}
postclose pwr2

use `school_sim', clear
vioplot tstat, over(clusters) vertical
graph export "violin_plotcluster15.png", replace

/*
INTERPRETATION: Violin Plot — Cluster Size Fixed at 15, Varying Schools

- T-statistic distributions become tighter and more centered around 1.96 as school count increases.
- Indicates more schools = more power and better precision.
*/

collapse (mean) power=sig, by(clusters)
list

twoway (line power clusters), ///
    title("Power vs. Number of Schools (Cluster Size = 15)") ///
    yline(0.8, lpattern(dash)) ///
    xtitle("Number of Schools") ///
    ytitle("Estimated Power")
	
graph export "power_vs_clusters_15.png", replace 
/*
INTERPRETATION: Power vs. Schools (Cluster Size = 15)

- Shows power increases with number of clusters.
- Power crosses 80% threshold around 280–300 schools.
- Suggests at least 300 schools are needed with 15 students/cluster.
*/


// =========================================================
// Question 7: 70% compliance — how many schools needed?
// =========================================================

clear
set seed 55555
local sims = 500
local clustsize = 15
tempfile noncompliance_sim
postfile pwr3 clusters tstat sig using `noncompliance_sim', replace

foreach clust in 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400 {
    display "Simulating for `clust' schools with 70% compliance..."
    forvalues i = 1/`sims' {
        clear
        local rho = 0.3
        local sigma2 = 1
        local sigma_cluster = sqrt(`rho' * `sigma2')
        local sigma_indiv = sqrt(1 - `rho')

        set obs `clust'
        gen school_id = _n
        gen u_school = rnormal(0, `sigma_cluster')

        gen treat = runiform() < 0.5
        gen adopted = .
        replace adopted = runiform() < 0.7 if treat == 1
        replace adopted = 0 if treat == 0

        expand `clustsize'
        bysort school_id (u_school): gen student_id = _n

        gen e_student = rnormal(0, `sigma_indiv')
        gen Y = u_school + e_student
        replace Y = Y + 0.2 if adopted == 1

        regress Y treat, cluster(school_id)
        matrix b = r(table)
        local sig = (b[4,1] < 0.05)
        local tstat = b[3,1]
        post pwr3 (`clust') (`tstat') (`sig')
    }
}
postclose pwr3

use `noncompliance_sim', clear
vioplot tstat, over(clusters) vertical
graph export "violin_plot3.png", replace

/*
INTERPRETATION: Violin Plot — 70% Compliance

- Noncompliance weakens statistical signal.
- T-stat distributions are wider, less centered around 1.96 even at high cluster counts.
*/

collapse (mean) power=sig, by(clusters)
list

twoway (line power clusters), 
    title("Power vs. Schools with 70% Compliance") 
    yline(0.8, lpattern(dash)) 
    xtitle("Number of Schools") 
    ytitle("Estimated Power")
graph export "power70%_compliance.png", replace

/*
INTERPRETATION: Power Curve with Noncompliance

- Power plateaus below 80% even at 400 schools.
- Noncompliance reduces detectable treatment effect → reduced power.
*/

// Estimate exact number of schools needed for 80% power
reg power clusters if inrange(clusters, 300, 400)
display (0.8 - _b[_cons]) / _b[clusters]   // ≈ 566 schools

/*
Final Result: Under 70% compliance, ~566 schools are needed to detect a 0.2 SD effect with 80% power.
*/


	
	
	
	
	
	
	

	
	
	
	
	
	
//////////////////////////////////////////////////////////////////////////
// ============================= Part 3 ================================ //
//////////////////////////////////////////////////////////////////////////

// =========================================================
// Part 3.1: Basic Data Generating Process for Outcome Y
// Create treatment variable and outcome Y with noise
// =========================================================

clear all
set seed 77777

// Set sample size for this simple example (later varied in 3.4)
local N = 1000
set obs `N'

// Generate binary treatment assignment (random)
gen D = runiform() < 0.5   // 50% chance of receiving treatment

// Set true treatment effect
local beta = 0.5

// Generate random noise term (ε ~ N(0, 1))
gen epsilon = rnormal(0, 1)

// Construct outcome: Y = β * D + ε
gen Y = `beta'*D + epsilon

// Label variables for clarity
label variable Y "Outcome"
label variable D "Treatment assignment"
label variable epsilon "Random noise"

// Quick descriptive stats
summarize Y D epsilon
reg Y D

/*
INTERPRETATION – PART 3.1:

created a basic data generating process (DGP) with 1000 observations:
- Treatment (D) assigned randomly
- Outcome (Y) = true treatment effect (β = 0.5) + random noise

This establishes a baseline regression model with no bias or confounding.
*/


// =========================================================
// Part 3.2: Add Strata Groups and Covariates
// Introduce strata and continuous covariates (some affect treatment, some Y)
// =========================================================

clear all
set seed 88888

// 1. Create 10 strata groups (e.g., schools or regions)
set obs 10
gen strata_id = _n
gen strata_effect = rnormal(0, 0.3)   // Strata-level influence on Y

// 2. Expand to individual level: 100 individuals per strata
expand 100     // Total sample size = 1000
bysort strata_id: gen id = _n

// 3. Generate individual-level noise
gen epsilon = rnormal(0, 1)

// 4. Generate covariates
gen confounder = rnormal(0, 1)       // Affects both treatment and outcome (confounder)
gen outcome_only = rnormal(0, 1)     // Affects only outcome
gen treatment_only = rnormal(0, 1)   // Affects only treatment

// 5. Assign treatment with confounding
gen prob_treat = invlogit(0.5 * confounder + 0.5 * treatment_only)
gen D = runiform() < prob_treat

// 6. True treatment effect
local beta = 0.5

// 7. Construct outcome with treatment effect and covariates
gen Y = `beta'*D + confounder + outcome_only + strata_effect + epsilon

// Label variables
label variable D "Treatment (depends on confounder + treatment_only)"
label variable confounder "Confounder (affects treatment & outcome)"
label variable outcome_only "Outcome-only covariate"
label variable treatment_only "Treatment-only covariate"
label variable strata_id "Strata group"
label variable strata_effect "Effect of strata group on Y"
label variable Y "Outcome"

// Quick summary
summarize Y D confounder outcome_only treatment_only strata_effect

// Check: Are treatment assignments biased due to confounder?
reg D confounder treatment_only

/*
INTERPRETATION – PART 3.2:

expanded our DGP to include realistic covariates and strata:

1. Created 10 strata groups with unique effects on outcome Y.
2. Introduced 3 continuous covariates:
   - `confounder`: affects **both** treatment and outcome
   - `outcome_only`: affects only Y
   - `treatment_only`: affects only D

3. Assigned treatment probabilistically using a logistic function,
   which simulates real-world treatment selection bias.

4. Constructed outcome Y using all covariates, strata effects, and noise.

This setup introduces **confounding**, making simple regressions of Y on D biased.

*/



// =========================================================
// Part 3.3: Confirm Covariate Roles via Regressions
//  Use regressions to validate our data generating process (DGP)
// =========================================================

/*
In this section, I use regressions to empirically verify that the continuous covariates behave according to the roles I designed for them in Part 3.2:

- `confounder` should affect both treatment and outcome
- `outcome_only` should affect only the outcome
- `treatment_only` should affect only the treatment

This helps confirm that the simulated data will meaningfully reflect bias from omitted variables.
*/

// ---------------------------------------------------------
// Check 1: Does the confounder affect treatment?
// ---------------------------------------------------------

reg D confounder treatment_only

/*
Result:
Both `confounder` (coef = 0.13, p < 0.001) and `treatment_only` (coef = 0.089, p < 0.001) 
are significant predictors of treatment (D).

This confirms that treatment is **not purely random** — it's driven by a combination 
of the confounder and another variable (`treatment_only`), just as intended.

This introduces the selection bias we will later try to correct for in regressions.
*/


// ---------------------------------------------------------
// Check 2: Does the outcome-only variable affect treatment?
// ---------------------------------------------------------

reg D outcome_only

/*
Result:
The coefficient is -0.003 (p = 0.84), which is **statistically insignificant**.

This confirms that `outcome_only` does **not influence treatment**, 
which is exactly what we designed it to do.
*/


// ---------------------------------------------------------
// Check 3: Does the treatment-only variable affect the outcome?
// ---------------------------------------------------------

reg Y treatment_only

/*
Result:
The coefficient is -0.073 (p = 0.22), which is **not statistically significant**.

This confirms that `treatment_only` has **no direct impact on the outcome** Y, 
which is important because it isolates it as a treatment predictor, not an outcome driver.
*/


// ---------------------------------------------------------
// Check 4: Does the outcome-only variable actually affect the outcome?
// ---------------------------------------------------------

reg Y outcome_only

/*
Result:
`outcome_only` has a large and highly significant coefficient (0.95, p < 0.001).

This confirms it does influence Y strongly — as expected — 
but does **not bias the treatment effect** since it doesn't influence treatment.
*/


// ---------------------------------------------------------
// Check 5: Does the confounder affect the outcome as well?
// ---------------------------------------------------------

reg Y confounder

/*
Result:
`confounder` has a very strong effect on Y (coef = 1.10, p < 0.001).

This confirms that the confounder affects **both** the outcome and treatment,
meaning it introduces bias in naive estimates of the treatment effect.

This is exactly the kind of variable we hope to **control for** in regression models 
to reduce bias in our estimate of β.
*/


// ---------------------------------------------------------
// Summary of Part 3.3
// ---------------------------------------------------------

/*
This set of regressions confirms the **intended causal roles** of the three covariates in my simulation:

- `confounder`: affects both D and Y → introduces bias
- `outcome_only`: affects only Y → improves outcome precision when included
- `treatment_only`: affects only D → simulates a real-world selection factor

 With this structure validated, I can now move on to Part 3.4 to compare how different regression models 
(naive, partial, full, with and without fixed effects) perform in estimating the treatment effect 
across different sample sizes.
*/
	
	
	
// =========================================================
// Part 3.4 – Simulation Program for Bias & Convergence
// Define a program that simulates data and runs multiple models
// =========================================================
program drop simulate_model_bias
program define simulate_model_bias, rclass
    syntax , obs(integer)

    // -----------------------------
    // Simulate data
    // -----------------------------
    clear
    set obs 10
    gen strata_id = _n
    gen strata_effect = rnormal(0, 0.3)

    expand `obs'/10  // Expand to desired sample size
    bysort strata_id: gen id = _n

    gen epsilon = rnormal(0, 1)
    gen confounder = rnormal(0, 1)
    gen outcome_only = rnormal(0, 1)
    gen treatment_only = rnormal(0, 1)

    gen prob_treat = invlogit(0.5 * confounder + 0.5 * treatment_only)
    gen D = runiform() < prob_treat

    local beta = 0.5
    gen Y = `beta'*D + confounder + outcome_only + strata_effect + epsilon

    // -----------------------------
    // Run 5 regression models
    // -----------------------------

    // Model 1: Naive
    reg Y D
    return scalar m1 = _b[D]

    // Model 2: + Confounder
    reg Y D confounder
    return scalar m2 = _b[D]

    // Model 3: + Outcome-only
    reg Y D confounder outcome_only
    return scalar m3 = _b[D]

    // Model 4: + Strata FE
    reg Y D confounder outcome_only i.strata_id
    return scalar m4 = _b[D]

    // Model 5: + All covariates
    reg Y D confounder outcome_only treatment_only i.strata_id
    return scalar m5 = _b[D]
end


// =========================================================
// Run simulations and collect estimates for different sample sizes
// =========================================================

clear
set seed 88888

local sims = 500
tempfile sim_results
postfile results N m1 m2 m3 m4 m5 using `sim_results', replace

foreach N in 100 200 400 800 1600 3200 {
    display "Running simulations for sample size `N'..."
    forvalues i = 1/`sims' {
        quietly simulate_model_bias, obs(`N')
        post results (`N') (r(m1)) (r(m2)) (r(m3)) (r(m4)) (r(m5))
    }
}
postclose results


// =========================================================
// Violin Plot of Estimate Distributions (N = 800 subset)
// =========================================================

use `sim_results', clear
save "sim_results.dta", replace

// Keep only N = 800 for this graph
keep if N == 800
gen sim_id = _n

reshape long m, i(sim_id) j(model_num)
label define model_lbl 1 "M1: Naive" 2 "M2: +Confounder" 3 "M3: +OutcomeOnly" ///
                     4 "M4: +Strata FE" 5 "M5: +All Covariates"
label values model_num model_lbl

// Plot violin distribution of treatment estimates
vioplot m, over(model_num) vertical ///
    ytitle("Estimated β") ///
    title("Distribution of Treatment Estimates (N = 800)") ///
    note("Violin plots show spread of estimates across simulations")

graph export "violin_part3_N800.png", replace
	
	

/*
INTERPRETATION: Part 3.4 Violin Plot – Bias and Precision Across Models

This violin plot visualizes the distribution of estimated treatment effects (β̂)
across 500 simulations for five regression models, all using a fixed sample size of N = 800.

Each violin represents the **spread and density** of the estimated coefficient on `D` (treatment)
for a given model specification:

- **M1: Naive** — Only includes treatment in the regression.
    - **Highly biased** upward.
    - Centered around ~1.0 instead of the true β = 0.5.
    - This bias is due to omitted variable bias (confounder not included).

- **M2: +Confounder** — Controls for the confounder.
    - Estimate is now centered closer to the true value (β = 0.5).
    - Bias is largely eliminated.

- **M3: +OutcomeOnly** — Adds a variable that affects only the outcome.
    - Further reduces variance of β̂ slightly.
    - Does not address bias but improves efficiency.

- **M4: +Strata FE** — Adds fixed effects for `strata_id`.
    - Captures group-level variation.
    - Helps control for unobserved strata differences that influence outcome.
    - Tightens spread and remains centered at β = 0.5.

- **M5: +All Covariates** — Includes all covariates: confounder, outcome-only, and treatment-only.
    - **Best model in terms of bias and precision**.
    - Estimate is tightly distributed around the true β = 0.5.
    - Treatment-only covariate doesn't reduce bias but can reduce residual variance.

OVERALL:
- Omitting confounders causes serious bias (Model 1).
- Including **relevant covariates** and **strata fixed effects** improves both **accuracy** and **precision**.
- This visualization clearly shows the trade-off between **bias correction** and **efficiency gains** as we add controls.

Note: This plot uses N = 800. Later in this part, we will investigate how sample size affects variance and bias.
*/
	
	

// ================================================
// Visualizing Bias & Convergence by Sample Size
// (Mean & Variance of Treatment Estimates)
// ================================================

clear
use "sim_results.dta", clear
//Mean convergence plot 

// Collapse by N: mean and sd of each model estimate
collapse (mean) mean_m1=m1 mean_m2=m2 mean_m3=m3 mean_m4=m4 mean_m5=m5 ///
         (sd)   sd_m1=m1   sd_m2=m2   sd_m3=m3   sd_m4=m4   sd_m5=m5 , by(N)

twoway ///
    (line mean_m1 N, lcolor(navy)) ///
    (line mean_m2 N, lcolor(cranberry)) ///
    (line mean_m3 N, lcolor(forest_green)) ///
    (line mean_m4 N, lcolor(orange)) ///
    (line mean_m5 N, lcolor(dkgreen)), ///
    title("Convergence of Mean Estimate to True β", size(medsmall)) ///
    ytitle("Mean of β̂", size(small)) ///
    xtitle("Sample Size (N)", size(small)) ///
    yline(0.5, lpattern(dash) lcolor(gray)) ///
    legend(order(1 "M1: Naive" 2 "M2: +Confounder" 3 "M3: +OutcomeOnly" ///
                 4 "M4: +Strata FE" 5 "M5: +All Covariates") ///
           ring(0) position(3) row(2) size(small)) ///
    graphregion(color(white)) plotregion(margin(zero))
	
graph export "mean_convergence.png", replace	

/*
INTERPRETATION – Convergence of Mean Estimate to True β

This graph shows how the average estimate of the treatment effect (β̂) 
evolves across increasing sample sizes for each of the five regression models.

Key insights:

- **Model 1 (Naive)** is clearly biased — the average β̂ remains far above the true value (0.5), 
  even at large N. This is due to omitted variable bias from not adjusting for confounders or strata effects.

- **Models 2–5**, which add covariates and fixed effects, quickly converge toward the true value (0.5):
    - Model 2 includes the confounder (removing bias from selection into treatment).
    - Model 3 adds an outcome-only covariate, reducing residual noise.
    - Model 4 includes strata fixed effects, accounting for group-level variation.
    - Model 5 combines all controls and performs the best in terms of both bias and efficiency.

- As sample size increases, the mean estimates from Models 2–5 stabilize tightly around 0.5, 
  confirming that **proper controls eliminate bias** and that estimates become more precise with larger N.

This figure provides visual confirmation that **bias decreases and consistency improves** 
when we add relevant covariates and fixed effects — a key lesson in causal inference.

*/

// =======================
// Standard Deviation Convergence Plot
// =======================

twoway ///
    (line sd_m1 N, lcolor(navy)) ///
    (line sd_m2 N, lcolor(red)) ///
    (line sd_m3 N, lcolor(green)) ///
    (line sd_m4 N, lcolor(orange)) ///
    (line sd_m5 N, lcolor(brown)), ///
    title("Convergence of Standard Deviation (β̂)") ///
    ytitle("Standard Deviation of β̂", size(medsmall)) ///
    xtitle("Sample Size (N)", size(medsmall)) ///
    legend(order(1 "M1: Naive" 2 "M2: +Confounder" ///
                 3 "M3: +OutcomeOnly" 4 "M4: +Strata FE" ///
                 5 "M5: +All Covariates") rows(2)) ///
    graphregion(color(white))

graph export "sd_convergence.png", replace
	

/*
INTERPRETATION – Standard Deviation Convergence Plot

This plot illustrates how the **standard deviation** of the estimated treatment effect (β̂)
changes as the sample size increases across five models.

Model 1 (Naive): No controls → highest variability due to omitted variable bias.

Model 2 (+Confounder): Adjusting for confounding reduces variance but not to minimum.

Model 3 (+OutcomeOnly): Has similar variance to M2 since outcome_only only affects Y.

Model 4 (+Strata FE): Adds precision by accounting for group-level heterogeneity.

Model 5 (+All Covariates): Most precise and lowest standard deviation at all N values.

The decreasing trend in all models shows **consistency**, and the ordering reflects 
**efficiency gains** from adjusting for important covariates and fixed effects.
This validates why better-specified models are both less biased and more stable.
*/
	
