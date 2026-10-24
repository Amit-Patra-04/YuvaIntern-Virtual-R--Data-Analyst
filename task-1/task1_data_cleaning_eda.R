library(tidyverse)
library(scales)

# Data Ingestion
data_file <- "WA_Fn-UseC_-Telco-Customer-Churn.csv"
if (!file.exists(data_file)) {
  download.file("https://raw.githubusercontent.com/treselle-systems/customer_churn_analysis/master/WA_Fn-UseC_-Telco-Customer-Churn.csv",
                destfile = data_file, mode = "wb")
}

raw_df <- read.csv(data_file, stringsAsFactors = FALSE)
str(raw_df)
summary(raw_df)

# Data Cleaning & Type Coercion
clean_df <- raw_df

# Handle whitespace in TotalCharges and impute 0 for new accounts (tenure == 0)
clean_df$TotalCharges <- as.numeric(trimws(clean_df$TotalCharges))
clean_df$TotalCharges[is.na(clean_df$TotalCharges) & clean_df$tenure == 0] <- 0

# Standardize redundant service categories
binary_cols <- c("MultipleLines", "OnlineSecurity", "OnlineBackup", 
                 "DeviceProtection", "TechSupport", "StreamingTV", "StreamingMovies")
for (col in binary_cols) {
  clean_df[[col]] <- ifelse(clean_df[[col]] %in% c("No internet service", "No phone service"), "No", clean_df[[col]])
}

# Factor recoding
clean_df$SeniorCitizen <- factor(clean_df$SeniorCitizen, levels = c(0, 1), labels = c("No", "Yes"))
clean_df$Churn <- factor(clean_df$Churn, levels = c("No", "Yes"))
clean_df$Contract <- factor(clean_df$Contract, levels = c("Month-to-month", "One year", "Two year"))
clean_df$Churn_Binary <- ifelse(clean_df$Churn == "Yes", 1, 0)

# Outlier Audit (Tukey's 1.5 x IQR)
calc_iqr_bounds <- function(x) {
  q <- quantile(x, probs = c(0.25, 0.75), na.rm = TRUE)
  iqr <- diff(q)
  lower <- q[1] - 1.5 * iqr
  upper <- q[2] + 1.5 * iqr
  c(Q1 = q[[1]], Q3 = q[[2]], IQR = iqr, Lower = lower, Upper = upper,
    Outliers = sum(x < lower | x > upper, na.rm = TRUE))
}

sapply(clean_df[c("tenure", "MonthlyCharges", "TotalCharges")], calc_iqr_bounds)

# Feature Scaling & Transformations
clean_df$TotalCharges_log <- log1p(clean_df$TotalCharges)

min_max_scale <- function(x) (x - min(x)) / (max(x) - min(x))
clean_df$tenure_norm <- min_max_scale(clean_df$tenure)
clean_df$MonthlyCharges_norm <- min_max_scale(clean_df$MonthlyCharges)

clean_df$tenure_z <- as.vector(scale(clean_df$tenure))
clean_df$MonthlyCharges_z <- as.vector(scale(clean_df$MonthlyCharges))
clean_df$TotalCharges_z <- as.vector(scale(clean_df$TotalCharges))

# Ordinal & Dummy Encoding
contract_ranks <- c("Month-to-month" = 1, "One year" = 2, "Two year" = 3)
clean_df$Contract_Ordinal <- contract_ranks[as.character(clean_df$Contract)]

dummy_mat <- model.matrix(~ InternetService + PaymentMethod - 1, data = clean_df)

# Summary Statistics & Correlation
clean_df %>%
  summarise(across(c(tenure, MonthlyCharges, TotalCharges),
                   list(mean = mean, median = median, sd = sd, iqr = IQR)))

prop.table(table(clean_df$Churn)) * 100
prop.table(table(clean_df$Contract, clean_df$Churn), margin = 1) * 100
prop.table(table(clean_df$InternetService, clean_df$Churn), margin = 1) * 100
prop.table(table(clean_df$PaymentMethod, clean_df$Churn), margin = 1) * 100

cor(clean_df[c("tenure", "MonthlyCharges", "TotalCharges", "TotalCharges_log", "Churn_Binary")])

# Exploratory Visualizations
theme_set(theme_minimal(base_family = "sans", base_size = 11))

# Tenure distribution by churn outcome
ggplot(clean_df, aes(x = tenure, fill = Churn)) +
  geom_histogram(binwidth = 4, position = "dodge", alpha = 0.85, color = "white") +
  scale_fill_manual(values = c("No" = "#2b5c8f", "Yes" = "#d9534f")) +
  labs(title = "Customer Tenure Distribution by Churn Status",
       x = "Tenure (Months)", y = "Customer Count") +
  theme(legend.position = "bottom")

# Monthly charges density by churn outcome
ggplot(clean_df, aes(x = MonthlyCharges, fill = Churn)) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(values = c("No" = "#2b5c8f", "Yes" = "#d9534f")) +
  labs(title = "Monthly Charges Density by Churn Status",
       x = "Monthly Charges ($)", y = "Density") +
  theme(legend.position = "bottom")

# Contract commitment vs churn proportion
ggplot(clean_df, aes(x = Contract, fill = Churn)) +
  geom_bar(position = "fill", width = 0.55, alpha = 0.85) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c("No" = "#4a90e2", "Yes" = "#e74c3c")) +
  labs(title = "Churn Proportion Across Contract Terms",
       x = "Contract Duration", y = "Proportion") +
  theme(legend.position = "bottom")

# Total charges boxplot by churn
ggplot(clean_df, aes(x = Churn, y = TotalCharges, fill = Churn)) +
  geom_boxplot(alpha = 0.75, width = 0.45, outlier.size = 1) +
  scale_fill_manual(values = c("No" = "#2b5c8f", "Yes" = "#d9534f")) +
  labs(title = "Total Charges Distribution Across Churn Status",
       x = "Churn Status", y = "Total Charges ($)") +
  theme(legend.position = "none")
