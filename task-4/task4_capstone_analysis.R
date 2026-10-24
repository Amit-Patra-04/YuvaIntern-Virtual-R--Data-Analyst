library(tidyverse)
library(caret)
library(pROC)
library(car)
library(randomForest)
library(scales)

# Data Ingestion & Setup
data_file <- "WA_Fn-UseC_-Telco-Customer-Churn.csv"
if (!file.exists(data_file)) {
  download.file("https://raw.githubusercontent.com/treselle-systems/customer_churn_analysis/master/WA_Fn-UseC_-Telco-Customer-Churn.csv",
                destfile = data_file, mode = "wb")
}

raw_df <- read.csv(data_file, stringsAsFactors = FALSE)

# Data Cleaning & Type Coercion
raw_df$TotalCharges <- as.numeric(trimws(raw_df$TotalCharges))
raw_df$TotalCharges[is.na(raw_df$TotalCharges) & raw_df$tenure == 0] <- 0

service_vars <- c("MultipleLines", "OnlineSecurity", "OnlineBackup", "DeviceProtection", 
                 "TechSupport", "StreamingTV", "StreamingMovies")
for (v in service_vars) {
  raw_df[[v]] <- ifelse(raw_df[[v]] %in% c("No internet service", "No phone service"), "No", raw_df[[v]])
}

raw_df$SeniorCitizen <- factor(raw_df$SeniorCitizen, levels = c(0, 1), labels = c("No", "Yes"))
raw_df$Churn <- factor(raw_df$Churn, levels = c("No", "Yes"))
raw_df$Churn_num <- ifelse(raw_df$Churn == "Yes", 1, 0)
raw_df$Contract <- factor(raw_df$Contract, levels = c("Month-to-month", "One year", "Two year"))

# Feature Engineering
raw_df$TotalCharges_log <- log1p(raw_df$TotalCharges)

min_max_scale <- function(x) (x - min(x)) / (max(x) - min(x))
raw_df$tenure_scaled <- min_max_scale(raw_df$tenure)
raw_df$MonthlyCharges_scaled <- min_max_scale(raw_df$MonthlyCharges)

baseline_churn <- mean(raw_df$Churn_num) * 100

# Inferential Hypothesis Testing
# Monthly charges group difference
t.test(MonthlyCharges ~ Churn, data = raw_df, var.equal = FALSE)
wilcox.test(MonthlyCharges ~ Churn, data = raw_df, exact = FALSE)

# Tenure group difference
t.test(tenure ~ Churn, data = raw_df, var.equal = FALSE)
wilcox.test(tenure ~ Churn, data = raw_df, exact = FALSE)

# Pearson Chi-Square tests
run_chi_sq <- function(var_name) {
  tab <- table(raw_df[[var_name]], raw_df$Churn)
  cs <- chisq.test(tab)
  n_tot <- sum(tab)
  v_stat <- sqrt(cs$statistic / (n_tot * (min(nrow(tab), ncol(tab)) - 1)))
  c(Chi2 = unname(cs$statistic), df = unname(cs$parameter), 
    p_val = cs$p.value, Cramers_V = unname(v_stat))
}

cat_cols <- c("Contract", "InternetService", "PaymentMethod", "TechSupport", "PaperlessBilling", "SeniorCitizen")
sapply(cat_cols, run_chi_sq)

# Supervised Classification Pipeline
model_df <- raw_df %>% select(-customerID, -Churn_num, -TotalCharges_log, -tenure_scaled, -MonthlyCharges_scaled)

# Stratified 80/20 train/test split
set.seed(42)
train_idx <- createDataPartition(model_df$Churn, p = 0.80, list = FALSE)
train_data <- model_df[train_idx, ]
test_data  <- model_df[-train_idx, ]

# Multivariate Logistic Regression
logit_model <- glm(Churn ~ ., data = train_data, family = binomial(link = "logit"))
summary(logit_model)

# Multicollinearity audit (GVIF)
car::vif(logit_model)

# Random Forest benchmark
set.seed(42)
rf_model <- randomForest(Churn ~ ., data = train_data, ntree = 150, mtry = 4, importance = TRUE)

# Out-of-Sample Evaluation on Holdout Test Set
lr_probs <- predict(logit_model, newdata = test_data, type = "response")
rf_probs <- predict(rf_model, newdata = test_data, type = "prob")[, "Yes"]

roc_lr <- roc(test_data$Churn, lr_probs, levels = c("No", "Yes"))
roc_rf <- roc(test_data$Churn, rf_probs, levels = c("No", "Yes"))

auc(roc_lr)
auc(roc_rf)

# Performance at default 0.50 cutoff
pred_default <- factor(ifelse(lr_probs >= 0.50, "Yes", "No"), levels = c("No", "Yes"))
confusionMatrix(pred_default, test_data$Churn, positive = "Yes")

# Decision threshold optimization via Youden's J statistic
youden_coords <- coords(roc_lr, "best", best.method = "youden", ret = c("threshold", "sensitivity", "specificity"))
opt_thresh <- youden_coords$threshold

pred_opt <- factor(ifelse(lr_probs >= opt_thresh, "Yes", "No"), levels = c("No", "Yes"))
confusionMatrix(pred_opt, test_data$Churn, positive = "Yes")
