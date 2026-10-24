library(tidyverse)
library(caret)
library(pROC)
library(car)
library(randomForest)

# Data Ingestion & Hygiene
data_file <- "WA_Fn-UseC_-Telco-Customer-Churn.csv"
if (!file.exists(data_file)) {
  download.file("https://raw.githubusercontent.com/treselle-systems/customer_churn_analysis/master/WA_Fn-UseC_-Telco-Customer-Churn.csv",
                destfile = data_file, mode = "wb")
}

churn_df <- read.csv(data_file, stringsAsFactors = FALSE)

churn_df$TotalCharges <- as.numeric(trimws(churn_df$TotalCharges))
churn_df$TotalCharges[is.na(churn_df$TotalCharges) & churn_df$tenure == 0] <- 0

service_cols <- c("MultipleLines", "OnlineSecurity", "OnlineBackup", 
                  "DeviceProtection", "TechSupport", "StreamingTV", "StreamingMovies")
for (col in service_cols) {
  churn_df[[col]] <- ifelse(churn_df[[col]] %in% c("No internet service", "No phone service"), "No", churn_df[[col]])
}

churn_df$SeniorCitizen <- factor(churn_df$SeniorCitizen, levels = c(0, 1), labels = c("No", "Yes"))
churn_df$Churn <- factor(churn_df$Churn, levels = c("No", "Yes"))
churn_df$Contract <- factor(churn_df$Contract, levels = c("Month-to-month", "One year", "Two year"))

# Hypothesis Testing
# H1: Monthly Charges difference across churn status
t.test(MonthlyCharges ~ Churn, data = churn_df, var.equal = FALSE)
wilcox.test(MonthlyCharges ~ Churn, data = churn_df, exact = FALSE)

# H2: Account tenure difference across churn status
t.test(tenure ~ Churn, data = churn_df, var.equal = FALSE)
wilcox.test(tenure ~ Churn, data = churn_df, exact = FALSE)

# H3: Pearson Chi-Square tests of independence
test_categorical_association <- function(feature_name) {
  tab <- table(churn_df[[feature_name]], churn_df$Churn)
  chi <- chisq.test(tab)
  n <- sum(tab)
  v <- sqrt(chi$statistic / (n * (min(nrow(tab), ncol(tab)) - 1)))
  c(Chi2 = unname(chi$statistic), df = unname(chi$parameter), 
    p_val = chi$p.value, Cramers_V = unname(v))
}

cat_vars <- c("Contract", "InternetService", "PaymentMethod", "SeniorCitizen", "TechSupport", "PaperlessBilling")
sapply(cat_vars, test_categorical_association)

# Supervised Predictive Modeling
model_data <- churn_df %>% select(-customerID)

# Stratified 80/20 train/test split
set.seed(42)
train_idx <- createDataPartition(model_data$Churn, p = 0.80, list = FALSE)
train_set <- model_data[train_idx, ]
test_set  <- model_data[-train_idx, ]

# Multivariate Logistic Regression
logit_fit <- glm(Churn ~ ., data = train_set, family = binomial(link = "logit"))
summary(logit_fit)

# Odds Ratios & 95% Confidence Intervals
odds_ratios <- exp(coef(logit_fit))
conf_intervals <- exp(confint.default(logit_fit))
cbind(Odds_Ratio = odds_ratios, conf_intervals)

# Multicollinearity check (GVIF)
car::vif(logit_fit)

# Model Evaluation on Test Set
pred_probs <- predict(logit_fit, newdata = test_set, type = "response")

# Default threshold (0.50)
pred_default <- factor(ifelse(pred_probs >= 0.50, "Yes", "No"), levels = c("No", "Yes"))
confusionMatrix(pred_default, test_set$Churn, positive = "Yes")

# ROC Curve and Area Under Curve
roc_curve_lr <- roc(test_set$Churn, pred_probs, levels = c("No", "Yes"))
auc(roc_curve_lr)

# Threshold Optimization via Youden's J Index (Sensitivity + Specificity - 1)
optimal_coords <- coords(roc_curve_lr, "best", best.method = "youden", ret = c("threshold", "sensitivity", "specificity"))
optimal_threshold <- optimal_coords$threshold

pred_optimal <- factor(ifelse(pred_probs >= optimal_threshold, "Yes", "No"), levels = c("No", "Yes"))
confusionMatrix(pred_optimal, test_set$Churn, positive = "Yes")

# Random Forest Benchmark
set.seed(42)
rf_fit <- randomForest(Churn ~ ., data = train_set, ntree = 150, mtry = 4, importance = TRUE)
rf_probs <- predict(rf_fit, newdata = test_set, type = "prob")[, "Yes"]
roc_curve_rf <- roc(test_set$Churn, rf_probs, levels = c("No", "Yes"))
auc(roc_curve_rf)

# Top Feature Importance Ranking
varImpPlot(rf_fit)
