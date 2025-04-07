# PPOL 6818 – Assignment 4: Simulation-Based Inference in Stata

Author: Mehria  
Course: PPOL 6818 – Regression Methods for Development  
Assignment: Stata Assignment 4  


This project explores statistical power, design constraints, and bias correction through simulation-based inference in Stata. The assignment is divided into three parts:

- Part 1: Power calculations under individual-level randomization  
- Part 2: Cluster randomized trial (CRT) power simulations  
- Part 3: Bias correction using covariates and strata

All simulations were implemented in Stata and documented in the file `guide_assignment4.do`.

---

# Part 1: Power Calculations – Individual-Level Randomization

## Question 1: Simulating a Normally Distributed Outcome Variable
We begin by generating a baseline dataset with 1,000 individual-level observations. Our outcome variable, Y, is drawn from a normal distribution centered at zero with a standard deviation of one:
    Y ~ N(0,1).
This mimics a common data generating process (DGP) used in randomized controlled trials where the outcome is centered and symmetrically distributed. A histogram of Y confirmed the distribution's shape and parameters.

## Question 2: Adding Randomized Treatment with Heterogeneous Effects
Next, we simulate a randomized experiment where 50% of the sample receives a treatment. Treatment assignment is done using a Bernoulli process with a 0.5 probability, ensuring equal allocation between the treated and control groups.
To introduce heterogeneity in treatment effects, we generate an individual-specific treatment effect from a uniform distribution U[0.0, 0.2]. This ensures the average treatment effect across all treated units is approximately 0.1 standard deviations—a common benchmark for small but meaningful program impacts. The outcome Y is updated only for treated individuals by adding this treat_effect, simulating how treatment improves outcomes for treated individuals only.

## Question 3: Calculating Required Sample Size for 80% PowerUsing Stata's power twomeans command, we calculate how many participants are needed to detect a 0.1 SD treatment effect with 80% power.
We assume:

- Control group mean = 0
- Treatment group mean = 0.1
- Standard deviation = 1
- α (Type I error) = 0.05
- Equal allocation to treatment and control groups
-            power twomeans 0 0.1, sd(1) power(0.8)
- This yields a required total sample size of 3,142 individuals:
- 1,571 in treatment group
- 1,571 in control group
This serves as our baseline estimate without attrition or constraints.

## Question 4: Adjusting for 15% Attrition
We now account for 15% attrition, assuming the dropout rate is the same in both treatment and control arms. Since only 85% of the sample is expected to remain at the endline, we adjust our required sample size accordingly.

We divide the original requirement by 0.85, yielding an adjusted sample size of 3,697 individuals:

~1,849 in treatment
~1,849 in control
This ensures that after attrition, we still retain ~3,142 respondents needed to detect the desired effect with 80% power.

## Question 5: Adjusting for Budget Constraints (30% Treated)
In real-world settings, it’s common to face budget constraints that limit the number of individuals who can receive treatment. Here, we assume that only 30% of the sample can be treated, and the remaining 70% will serve as the control group. This unequal allocation reduces statistical power and requires a larger overall sample size to maintain 80% power.

To correct for the imbalance, we use Stata's nratio() option:

-     power twomeans 0 0.1, sd(1) power(0.8) nratio(0.43)
This indicates the treatment group is 43% the size of the control group.

Stata returns:

3,736 total participants
1,124 in treatment (30%)
2,612 in control (70%)
After adjusting for 15% attrition:

-     display ceil(3736 / 0.85)
We get an adjusted sample size of 4,396 individuals:

~1,319 in treatment
~3,077 in control
### Summary of Sample Size Scenarios

| Scenario                          | Required N (Total) | Treated | Control |
|----------------------------------|--------------------|---------|---------|
| Equal allocation (50/50)         | 3,142              | 1,571   | 1,571   |
| Equal allocation + 15% attrition | 3,697              | 1,849   | 1,849   |
| 30% treated                      | 3,736              | 1,124   | 2,612   |
| 30% treated + 15% attrition      | 4,396              | 1,319   | 3,077   |

---

# Part 2: Power Calculations for Cluster Randomization

Objective:

Create a clustered data structure where outcomes are influenced by group-level effects (e.g., schools), allowing for intra-cluster correlation (ICC ≈ 0.3).

Simulation Setup:

123 schools are simulated.
Each school is assigned 134 students, totaling 16,482 observations.
Treatment is assigned at the school level, with 50% of schools randomly assigned to treatment (treat_school = 1).
Each school's baseline outcome includes a cluster-level shock (u_school ~ N(0, σ²_cluster)), where σ²_cluster = 0.3 of the total variance.
Each student's individual error (e_student) is drawn from N(0, σ²_indiv) to satisfy the total variance structure (ρ = 0.3).
Students in treated schools receive a treatment effect drawn from U(0.15, 0.25), representing heterogeneous treatment effects.
###  Key Properties

| Feature                  | Specification                         |
|--------------------------|----------------------------------------|
| Cluster-level variation  | 30% (ICC = 0.3)                        |
| Treatment effect         | Heterogeneous: U(0.15, 0.25)           |
| Treatment assignment     | Random at the school level             |
| Sample size              | 123 schools × 134 students = 16,482    |

Interpretation:
This DGP simulates a realistic school-based randomized controlled trial, where:
Outcomes are correlated within schools due to shared unobserved characteristics.
Treatment effects are heterogeneous, adding realism to the design.
ICC is explicitly built in, which is essential when planning cluster randomized evaluations.

---

##  Question 2: Create a Flexible Simulation Program

To estimate power under different cluster sizes and numbers of clusters, we wrote a flexible Stata simulation program called `simulate_cluster_power`. The program allows us to specify:

- The number of clusters (schools)
- The number of students per cluster (cluster size)

Within each simulation:

1. Each cluster gets a random effect `u_school`, drawn from a normal distribution scaled by ICC (ρ = 0.3).
2. Treatment is randomly assigned at the **cluster level** (half of the schools are treated).
3. The individual-level error `e_student` is drawn from a normal distribution with variance consistent with the ICC.
4. Each student’s outcome is computed as:

   
   Y = u_school + e_student + 0.2 × treated
   

   (i.e., a constant 0.2 SD treatment effect is applied to treated clusters).

5. A regression of `Y` on `treat` is run, **clustering standard errors at the school level**, and the program saves:
   - The estimated t-statistic
   - A dummy for whether the p-value < 0.05 (significant)
   - The p-value itself

This program is used repeatedly in the next few questions to simulate different power scenarios.

---

Creating a flexible program lets us simulate **power under realistic conditions** of clustering and ICC. This is more accurate than analytical formulas when:

- ICC is moderate or high (as here: ρ = 0.3)
- Sample size is limited
- There is noise in the assignment or outcomes

This program is used repeatedly in **Questions 5–7** to compare power under different configurations of cluster size, cluster count, and compliance scenarios.

---

##  Question 3: Simulate ICC ≈ 0.3

This question asks us to ensure the **intra-cluster correlation (ICC)** in our data-generating process is approximately 0.3. This was **already built into the simulation program in Question 2**.

---

### ICC Built into Simulation

We explicitly specified the ICC in our simulation with:

```stata
local rho = 0.3
```

We then calculated the between-cluster and within-cluster variances using:

```stata
local sigma_cluster = sqrt(`rho' * `sigma2')
local sigma_indiv = sqrt(1 - `rho')
```

This results in:

- 30% of the total variance coming from cluster-level effects (`u_school`)
- 70% coming from individual-level error (`e_student`)

This ensures the simulated outcome variable `Y` has **clustered structure** representative of many real-world education and public health settings.

The ICC has a major impact on statistical power in cluster randomized trials:

- Higher ICC means **more similarity within clusters**, which reduces the **effective sample size**.
- This leads to **lower precision** unless you have more clusters or larger cluster sizes.

By building in ICC = 0.3, we simulate a moderately clustered scenario — which is realistic and analytically useful.

---
##  Question 4: Evenly Divide Schools and Generate 0.2 SD Effect

This question asks us to simulate a treatment effect of **0.2 standard deviations**, applied **at the school level**, and to **evenly divide** schools between treatment and control.

---

###  Implemented in the Simulation Program

In our simulation program (`simulate_cluster_power`), this was directly implemented as:

```stata
gen treat = runiform() < 0.5
replace Y = Y + 0.2 if treat == 1
```

This setup ensures:

- **Random assignment** of schools to treatment and control (50/50 split)
- **Constant treatment effect** of 0.2 SD applied to treated clusters

The outcome variable `Y` is influenced by:
- Cluster-level random effects (`u_school`)
- Individual-level noise (`e_student`)
- And the treatment boost of **0.2 SD** for treated clusters

---

### Summary Statistics (Simulated Example)

Using 123 schools and 134 students per school, we ran:

```stata
mean Y, over(treat_school)
```

This confirms that the mean `Y` is higher in treated schools, and the effect is approximately 0.2 SD in expectation.

---

### Interpretation

- This setup reflects a classic **cluster randomized experiment**.
- The treatment assignment and constant effect simplify analysis.
- Later, we'll explore **how cluster size and number of clusters** affect our ability to detect this 0.2 SD effect with statistical power.

---
## Question 5: Hold Number of Clusters Constant, Vary Cluster Size

This section explores how statistical power changes when we **hold the number of clusters constant (at 200)** and vary the **cluster size** across powers of 2.

We simulate cluster sizes:  
**2, 4, 8, 16, 32, 64, 128, 256, 512, 1024**  
Each configuration is simulated **1000 times** to estimate empirical power.

---

### Design Choices

- **Number of clusters**: Fixed at 200
- **Cluster sizes**: Varied systematically across powers of 2
- **Treatment assignment**: Random (50% treated schools)
- **Treatment effect**: Constant at 0.2 SD
- **ICC**: 0.3
- **Significance level**: 5%
- **Power calculation**: Proportion of simulations where p-value < 0.05
###  Violin Plot of T-statistics by Cluster Size

The violin plot below shows how the **distribution of t-statistics** on the treatment variable changes with cluster size:

![vioplot_cluster_size.png](https://raw.githubusercontent.com/gui2de/ppol6818-mk2417/main/graph/vioplot_cluster_size.png)

#### Interpretation:

- For **small clusters** (e.g., 2–8 students), the t-statistics are widely spread and rarely exceed the critical threshold of 1.96.
- As cluster size increases, the distribution **narrows and centers closer to 2**, improving precision and power.
- This graph visually confirms how **larger clusters yield more reliable treatment effect estimates**.
---
###  Power vs. Cluster Size

This graph summarizes the **mean power** across cluster sizes:

![power.png](https://raw.githubusercontent.com/gui2de/ppol6818-mk2417/main/graph/power.png)

#### Interpretation:

- Power increases rapidly from **cluster size = 2 to ≈ 64**.
- After cluster size 64, power **plateaus**, meaning **adding more individuals per cluster has diminishing returns**.
- With 200 clusters, power exceeds 80% once the cluster size reaches ~64.
---
### Practical Insight

- If budget constraints limit the number of individuals per cluster, **targeting at least 64 per cluster** achieves high power.
- If you're stuck with small clusters, **increase the number of clusters** to improve power (explored in Question 6).

---
## Question 6: Hold Cluster Size Fixed, Vary Number of Clusters

This section investigates how **power changes with the number of clusters**, while holding the **cluster size constant at 15 students per school**.

We simulate the following school counts:  
**10, 20, 30, ..., up to 300 schools**  
Each scenario is simulated **500 times**.

---
### Design Choices

- **Cluster size**: Fixed at 15 students
- **Clusters (schools)**: Varied from 10 to 300
- **Treatment assignment**: Random (50% treated schools)
- **Treatment effect**: Constant at 0.2 SD
- **ICC**: 0.3
- **Significance level**: 5%

---

### Violin Plot of T-statistics by Number of Clusters

The violin plot shows the distribution of t-statistics on the treatment coefficient for each cluster count.

![violin_plotcluster15.png](https://raw.githubusercontent.com/gui2de/ppol6818-mk2417/main/graph/violin_plotcluster15.png)

#### Interpretation:

- With **few clusters** (e.g., 10–50), t-statistics are highly variable and rarely reach the critical value of 1.96.
- As the number of schools increases, the distribution **becomes tighter and shifts upward**, centering around the threshold.
- This reflects that **increasing the number of clusters significantly improves power** — especially critical when cluster sizes are small.
---
### Power vs. Number of Clusters

This line plot summarizes the average power by number of clusters:
![power_vs_clusters_15.png](https://raw.githubusercontent.com/gui2de/ppol6818-mk2417/main/graph/power_vs_clusters_15.png)

#### Interpretation:
- Power grows steadily with more clusters.
- We cross the **80% power threshold at around 280–300 clusters**.
- This emphasizes the point that **when cluster size is small**, the **number of clusters is the main driver of power**.
---
### Practical Insight
- If you’re constrained to small clusters (e.g., 15 students/school), focus your budget on **adding more clusters (schools)**.
- Compared to increasing cluster size, **adding clusters** has a much **stronger impact on power** in cluster-randomized trials.
---
## Question 7: How Many Clusters Are Needed Under 70% Compliance?

This section explores how **noncompliance affects statistical power**. Specifically, we ask:

> "How many schools are needed to achieve 80% power if only **70% of treated schools** actually adopt the treatment?"
---
###  Setup

- **Cluster size**: 15 students per school (fixed)
- **Compliance rate**: 70% among treated schools
- **Effect size**: 0.2 SD — **but only for compliers**
- **Effective ATE**: 0.2 × 0.7 = **0.14**
- **ICC**: 0.3
- **Simulation**: 500 replications for each number of schools, from 100 to 400
---

### Violin Plot: T-statistics under 70% Compliance

This plot shows the distribution of treatment effect t-statistics at various school counts under noncompliance.

![violin_plot3.png](https://raw.githubusercontent.com/gui2de/ppol6818-mk2417/main/graph/violin_plot3.png)

#### Interpretation:

- Even with **300+ schools**, the distribution of t-statistics remains spread out.
- Many simulations fall **below the significance threshold (1.96)**.
- **Power is weakened due to the diluted treatment effect** from noncompliance.
---
###  Power Curve under 70% Compliance

We calculate the **proportion of simulations** with p < 0.05 (i.e., statistical significance) at each cluster count.

![power70%_compliance.png](https://github.com/gui2de/ppol6818-mk2417/blob/1dad4c3afb83b126e6c58716d69bb8e08b7d35f7/graph/power70%25_compliance.png)
#### Interpretation:

- Power increases with number of schools, but the curve rises **more slowly** than in the full-compliance case.
- Even at **400 schools**, power doesn’t exceed 80%.
- Using a linear regression on the power curve, we estimate that **~566 schools are needed** to reach 80% power at 70% compliance.
---
### Approximate Sample Size Calculation (Analytical Check)

We also used Stata’s `power twomeans` command and adjusted for clustering:
- **True effect**: 0.14 SD (adjusted for compliance)
- **Design effect**: 1 + (m – 1) × ICC = 5.2
- **Required individual N**: ~1604
- **Adjusted for clustering**:  
  `Adjusted clusters = 1604 / 15 × 5.2 ≈ 556`
This closely matches our simulation result: **566 clusters**.
---
- **Noncompliance significantly reduces power**, even if compliance is relatively high (70%).
- Simulation and analytical estimates both suggest needing **550–570 clusters** to detect a 0.14 SD effect at 80% power.
- When planning cluster RCTs, it is **crucial to account for implementation realities** like compliance.

---











