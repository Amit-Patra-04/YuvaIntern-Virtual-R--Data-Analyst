# Yuva Intern — Virtual R Data Analyst Internship

[![R](https://img.shields.io/badge/Language-R%20%3E%3D%204.3-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Internship](https://img.shields.io/badge/Program-Yuva%20Intern%20Virtual%20Internship-orange.svg)](https://yuvaintern.com/)
[![Track](https://img.shields.io/badge/Role-Virtual%20R%20Data%20Analyst%20Intern-purple.svg)]()

This repository contains the complete, production-grade deliverables for the **Virtual R Data Analyst Internship** at **Yuva Intern**. The project examines customer retention dynamics in the telecommunications sector using the **IBM Telco Customer Churn** portfolio (7,043 customer accounts across 21 variables), progressing through data hygiene, exploratory visual analytics, inferential hypothesis testing, and supervised classification modeling with decision threshold optimization.

---

## Project Architecture & Roadmap

```
YuvaIntern-Virtual-R--Data-Analyst/
├── task-1/                                         # Task 1: Data Cleaning & Preliminary Analysis
│   ├── figures/                                    # High-resolution exploratory distributions & audits
│   ├── report_description.txt                      # 314-word submission overview
│   ├── task1_data_cleaning_eda.R                   # Reproducible data cleaning & transformation script
│   ├── WA_Fn-UseC_-Telco-Customer-Churn.csv         # Baseline customer portfolio dataset
│   └── Yuva_Internship_Task_1_Data_Cleaning_and_EDA.docx
├── task-2/                                         # Task 2: Data Visualization & Insight Communication
│   ├── figures/                                    # 7 publication-grade ggplot2 visualizations
│   ├── report_description.txt                      # 298-word visual narrative summary
│   ├── task2_visualization_insights.R              # Multi-tier ggplot2 storytelling script
│   ├── WA_Fn-UseC_-Telco-Customer-Churn.csv         # Cleaned working dataset
│   └── Yuva_Internship_Task_2_Data_Visualization_and_Insights.docx
├── task-3/                                         # Task 3: Statistical Analysis & Predictive Modeling
│   ├── figures/                                    # Diagnostic charts, ROC curves, confusion matrices
│   ├── report_description.txt                      # 294-word modeling & hypothesis testing overview
│   ├── task3_statistical_modeling.R                # Inferential tests & logistic regression pipeline
│   ├── WA_Fn-UseC_-Telco-Customer-Churn.csv         # Model training dataset
│   └── Yuva_Internship_Task_3_Statistical_Analysis_and_Predictive_Modeling.docx
├── task-4/                                         # Task 4: Capstone Comprehensive Reporting
│   ├── figures/                                    # 10 integrated capstone visual artifacts
│   ├── report_description.txt                      # 292-word capstone summary
│   ├── task4_capstone_analysis.R                   # Master end-to-end analytical pipeline
│   ├── WA_Fn-UseC_-Telco-Customer-Churn.csv         # Capstone reference dataset
│   └── Yuva_Internship_Task_4_Comprehensive_Capstone_Report.docx
└── README.md                                       # Comprehensive repository documentation
```

---

## Milestone Breakdown & Analytical Scope

### Task 1: Data Cleaning and Preliminary Analysis with R
- **Objective**: Structural schema auditing, missing value handling, outlier detection, feature engineering, and baseline exploratory data analysis.
- **Key Methodologies**:
  - Identified 11 blank entries in `TotalCharges` causing silent character coercion. Cross-tabulation proved all 11 records had `tenure == 0` (newly onboarded accounts), justifying domain-grounded zero imputation over arbitrary mean substitution ($2,283.30).
  - Audited continuous features against Tukey's 1.5 &times; IQR rule, identifying legitimate bimodal distributions in `tenure` (1–5 months and 65–72 months) and `MonthlyCharges` ($20 vs $80–$100).
  - Addressed heavy positive skewness in `TotalCharges` (+0.96) using logarithmic scaling (`log1p`), normalizing variance down to -0.74.
  - Implemented Min-Max feature normalization ($[0, 1]$), Z-score standardization ($\mu=0, \sigma=1$), ordinal ranking for `Contract`, and dummy encoding for multi-level nominal variables.
- **Deliverables**: [`task-1/Yuva_Internship_Task_1_Data_Cleaning_and_EDA.docx`](task-1/Yuva_Internship_Task_1_Data_Cleaning_and_EDA.docx), [`task-1/task1_data_cleaning_eda.R`](task-1/task1_data_cleaning_eda.R), [`task-1/report_description.txt`](task-1/report_description.txt).

---

### Task 2: Data Visualization and Insight Communication using R
- **Objective**: Communicating complex multivariate behavioral drivers through high-contrast, publication-grade `ggplot2` graphics.
- **Key Visualizations**:
  - **Figure 1 (Lifecycle Trajectory Line Chart)**: Exposed a severe **first-year churn cliff** where Month 1 churn exceeds 50% and Year 1 churn averages 47.7%, falling below 10% after Year 5.
  - **Figure 2 (Pricing Violin-Boxplot Hybrid)**: Showed elevated price density among Fiber Optic accounts ($75–$105/month, median churned bill: $89.85/month).
  - **Figure 3 (Interaction Heatmap)**: Uncovered a **54.6% churn hazard** among month-to-month Fiber Optic subscribers, dropping to 4.8% on two-year agreements.
  - **Figure 5 (Payment Benchmark Lollipop Chart)**: Benchmarked payment friction, showing manual **Electronic Checks carry a 45.29% churn rate** (+18.7% above baseline), whereas automated payment methods average ~15%.
  - **Figure 7 (Diverging Risk Chart)**: Synthesized operational factors relative to the 26.54% portfolio baseline.
- **Deliverables**: [`task-2/Yuva_Internship_Task_2_Data_Visualization_and_Insights.docx`](task-2/Yuva_Internship_Task_2_Data_Visualization_and_Insights.docx), [`task-2/task2_visualization_insights.R`](task-2/task2_visualization_insights.R), [`task-2/report_description.txt`](task-2/report_description.txt).

---

### Task 3: Statistical Analysis and Predictive Modeling using R
- **Objective**: Inferential hypothesis testing, supervised classification modeling, model diagnostics, and decision threshold optimization.
- **Statistical Testing**:
  - **Hypothesis 1 (Monthly Charges)**: Welch's t-test ($t = 18.41, p < 0.001$, Cohen's $d = 0.470$) and Mann-Whitney U test ($W = 6.00 \times 10^6, p < 0.001$) confirmed churners pay significantly higher monthly fees ($74.44 vs $61.27).
  - **Hypothesis 2 (Tenure)**: Welch's t-test ($t = 34.82, p < 0.001$, Cohen's $d = 0.893$) confirmed retained customers maintain over double the average tenure of churners (37.57 vs 17.98 months).
  - **Hypothesis 3 (Categorical Associations)**: Pearson's $\chi^2$ tests verified strong associations across `Contract` ($\chi^2 = 1,184.60, \text{Cramer's } V = 0.410$) and `TechSupport` ($\chi^2 = 828.20, V = 0.343$).
- **Predictive Modeling & Threshold Tuning**:
  - Stratified 80/20 train/test split with 5-fold cross-validation.
  - Multivariate Logistic Regression achieved a cross-validated AUC of **0.8459**, matching the Random Forest benchmark (**0.8450**).
  - Evaluated business cost asymmetry (cost of False Negative $\gg$ False Positive). Lowering the decision threshold via Youden's J statistic from **0.50 down to 0.26**:
    - Increased churn detection recall from **55.35% to 79.95%** (+24.6% increase).
    - Reduced missed churners (False Negatives) from **167 down to 75 accounts** (a **55.1% reduction** in lost accounts).
- **Deliverables**: [`task-3/Yuva_Internship_Task_3_Statistical_Analysis_and_Predictive_Modeling.docx`](task-3/Yuva_Internship_Task_3_Statistical_Analysis_and_Predictive_Modeling.docx), [`task-3/task3_statistical_modeling.R`](task-3/task3_statistical_modeling.R), [`task-3/report_description.txt`](task-3/report_description.txt).

---

### Task 4: Comprehensive Capstone Reporting and Presentation
- **Objective**: Consolidating all four weeks of data cleaning, visualization, hypothesis testing, and modeling into a cohesive master capstone report.
- **Key Deliverables**:
  - Executive presentation on the financial ROI of predictive churn scoring.
  - Four prioritized operational retention initiatives:
    1. *First-90-Days Customer Onboarding Success Protocol*
    2. *Fiber Optic Plan Restructuring & Value Bundling*
    3. *Automated Recurring Billing Incentive ($5 credit)*
    4. *Household & Family Plan Expansion*
  - Complete reflections on challenges overcome, lessons learned, and a technical roadmap for future iterations (SMOTE resampling, Elastic Net regularization, XGBoost stacking).
- **Deliverables**: [`task-4/Yuva_Internship_Task_4_Comprehensive_Capstone_Report.docx`](task-4/Yuva_Internship_Task_4_Comprehensive_Capstone_Report.docx), [`task-4/task4_capstone_analysis.R`](task-4/task4_capstone_analysis.R), [`task-4/report_description.txt`](task-4/report_description.txt).

---

## Primary Empirical Insights & Business Impact

| Metric / Driver | Baseline Level | Observed Impact | Strategic Decision |
| :--- | :--- | :--- | :--- |
| **Portfolio Churn** | 26.54% | Baseline across 7,043 customer accounts | Focus retention resources on high-hazard segments |
| **Contract Stability** | Month-to-Month: 42.71% | Two-Year: 2.83% ($OR = 0.253, p < 0.001$) | Transition monthly customers to 1- or 2-year commitments |
| **Broadband Pricing** | DSL: 18.96% | Fiber Optic: 41.89% (54.6% on monthly plans) | Bundle cybersecurity add-ons to offset price friction |
| **Payment Friction** | Automatic: ~15.5% | Electronic Check: 45.29% ($OR = 1.468, p < 0.001$) | Introduce a $5 monthly credit for automated billing |
| **Threshold Tuning** | Cutoff 0.50 (Recall: 55.4%) | Cutoff 0.26 (Recall: 80.0%, FN: -55.1%) | Saves ~92 additional accounts per 1,400 customers (~$130k ARR) |

---

## Requirements & Reproducibility

To run any script in this repository, ensure you have R installed (v4.0+) along with the required packages:

```r
install.packages(c(
  "tidyverse",
  "caret",
  "pROC",
  "car",
  "randomForest",
  "scales",
  "gridExtra",
  "viridis",
  "e1071"
))
```

Each script is self-contained and will automatically download the dataset if not present in the local directory.

---

## Author

**Amit Patra**  
Virtual R Data Analyst Intern — Yuva Intern  
GitHub: [@Amit-Patra-04](https://github.com/Amit-Patra-04)