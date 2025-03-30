# README: Sampling Noise in a Fixed Population
This assignment explores how sampling noise affects regression estimates when drawing samples from a fixed population. We simulate repeated sampling and regression at different sample sizes (N = 10, 100, 1000, 10000), and examine how estimates, standard errors, and confidence intervals behave.

## Data Generating Process (DGP)

We create a fixed population of 10,000 individuals using the following data generating process:

y_i = 2 + 3*x_i + ε_i

Where:
- x_i ~ N(0, 1) is the independent variable
- ε_i ~ N(0, 1) is the error term
- The true slope (beta) is 3
- The true intercept is 2

This dataset is saved as `q1_fixedpop.dta`.

## Simulation Design

We created a Stata program `sample_regression` that:
1. Loads the fixed population
2. Draws a random sample of size N
3. Runs a regression of y on x
4. Saves the coefficient (beta), standard error, p-value, and confidence interval

Using the simulate command, we ran this program 500 times for each of the following sample sizes:
- N = 10
- N = 100
- N = 1000
- N = 10000

All results were combined into one dataset: `combined_sim_results.dta`.

## Graphs and Interpretation
### 1. Boxplot of Beta Estimates by Sample Size
This graph shows how the distribution of beta estimates varies with N.
### Distribution of Beta Estimates (Boxplot)
![Graph1.png](https://raw.githubusercontent.com/gui2de/ppol6818-mk2417/main/graph/Graph1.png)
Interpretation:
- For N = 10, the beta estimates are highly spread out with more noise and outliers.
- As sample size increases, the estimates become tightly clustered around the true beta = 3.
- The median is stable across groups, confirming the estimator is unbiased.

### 2. Standard Error vs Sample Size
Line graph showing the average standard error of beta at each sample size.

![Graph3.png](https://raw.githubusercontent.com/gui2de/ppol6818-mk2417/main/graph/Graph3.png)

Interpretation:
- The standard error decreases sharply as N increases.
- This reflects the increased precision of the regression estimate with larger samples.

### 3. Confidence Interval Width vs Sample Size
Line graph showing how wide the 95% confidence intervals are, on average.
![Graph4.png](https://raw.githubusercontent.com/gui2de/ppol6818-mk2417/main/graph/Graph4.png)
Interpretation:
- Confidence intervals shrink rapidly with larger sample size.
- Larger samples allow us to make tighter and more reliable inferences.

### 4. Dot Plot of Mean Beta and 95% Confidence Intervals

Dots represent the mean beta estimate at each N, and vertical bars show 95% confidence intervals.
### Mean Beta Estimates with 95% CIs
![Graph5.png](https://raw.githubusercontent.com/gui2de/ppol6818-mk2417/main/graph/Graph5.png)
Interpretation:
- All mean estimates are very close to the true value (beta = 3).
- Confidence intervals get narrower as N increases, showing increased reliability.

### 5. Density Plots of Beta Estimates
Smooth curves show the distribution of beta estimates for each sample size.

Interpretation:
- At N = 10, the distribution is wide and flat.
- At larger sample sizes, the distributions become narrow and tightly centered around 3.
- This visualizes how sampling noise decreases with larger N.
![Distribution of Beta Estimates (Density)](https://raw.githubusercontent.com/gui2de/ppol6818-mk2417/main/graph/Graph.png)

### 6. Summary Table of Simulation Results

| Sample Size | Mean Beta | Std. Dev. Beta | Mean SE | Mean CI Width |
|-------------|-----------|----------------|---------|----------------|
| 10          | 3.0228    | 0.3839         | 0.3604  | 1.6621         |
| 100         | 3.0169    | 0.1065         | 0.1026  | 0.4073         |
| 1000        | 3.0109    | 0.0293         | 0.0321  | 0.1258         |
| 10000       | 3.0101    | ~0             | 0.0101  | 0.0397         |

Interpretation:
- The mean beta is close to the true value across all sample sizes.
- Standard errors and confidence interval widths drop rapidly as N increases.
- The estimates become both accurate and highly precise as N gets larger.
  ### Histogram by Sample Size
![Graph7.png](https://raw.githubusercontent.com/gui2de/ppol6818-mk2417/main/graph/Graph7.png)

## Analysis of Simulation Results

The graphs clearly show how increasing the sample size reduces sampling noise and leads to more precise estimates of the true beta. At small sample sizes like N = 10, the beta estimates are widely dispersed, with large standard errors and wide confidence intervals, making the estimates unreliable. As the sample size increases to 100 and 1,000, the distribution of beta estimates becomes narrower, and the standard error and confidence intervals shrink, reflecting greater precision. However, at N = 10,000, the behavior changes qualitatively—the beta estimates across simulations are almost identical, the standard errors are extremely small, and the confidence intervals are very tight. This suggests that at such a large sample size, sampling noise is virtually eliminated and the estimates consistently recover the true beta. The shift at N = 10,000 highlights how large samples can produce highly stable and replicable results in regression analysis.


## Conclusion

This simulation illustrates how:
- Regression estimates from small samples can vary widely due to sampling noise.
- Larger samples provide greater precision, reflected in smaller standard errors and tighter confidence intervals.
- Even though the estimator is unbiased, small samples are riskier when making inferences.

These findings highlight the importance of adequate sample sizes in applied research. 
