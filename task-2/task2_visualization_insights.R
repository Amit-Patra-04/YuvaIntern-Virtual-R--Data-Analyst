library(tidyverse)
library(scales)
library(gridExtra)

# Data Ingestion & Setup
data_file <- "WA_Fn-UseC_-Telco-Customer-Churn.csv"
if (!file.exists(data_file)) {
  download.file("https://raw.githubusercontent.com/treselle-systems/customer_churn_analysis/master/WA_Fn-UseC_-Telco-Customer-Churn.csv",
                destfile = data_file, mode = "wb")
}

churn_df <- read.csv(data_file, stringsAsFactors = FALSE)

# Clean TotalCharges missing values (new accounts with tenure == 0)
churn_df$TotalCharges <- as.numeric(trimws(churn_df$TotalCharges))
churn_df$TotalCharges[is.na(churn_df$TotalCharges)] <- 0

churn_df$SeniorCitizen <- factor(churn_df$SeniorCitizen, levels = c(0, 1), labels = c("No", "Yes"))
churn_df$Churn_num <- ifelse(churn_df$Churn == "Yes", 1, 0)
churn_df$Contract <- factor(churn_df$Contract, levels = c("Month-to-month", "One year", "Two year"))

baseline_churn <- mean(churn_df$Churn_num) * 100

# Base plotting theme
theme_clean <- function(base_size = 11) {
  theme_minimal(base_size = base_size, base_family = "sans") +
    theme(
      plot.title = element_text(face = "bold", size = rel(1.15), color = "#1F4E79", margin = margin(b = 6)),
      plot.subtitle = element_text(size = rel(0.95), color = "#555555", margin = margin(b = 10)),
      axis.title = element_text(face = "bold", size = rel(0.95), color = "#333333"),
      axis.text = element_text(size = rel(0.9), color = "#444444"),
      panel.grid.major = element_line(color = "#EBF0F5", linewidth = 0.5),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}
theme_set(theme_clean())

# 1. Customer Retention Trajectory Across Tenure (Line Chart)
tenure_trajectory <- churn_df %>%
  group_by(tenure) %>%
  summarise(
    total = n(),
    churn_rate = mean(Churn_num) * 100,
    .groups = "drop"
  ) %>%
  mutate(churn_smooth = stats::filter(churn_rate, rep(1/5, 5), sides = 2))

ggplot(tenure_trajectory, aes(x = tenure)) +
  annotate("rect", xmin = 0, xmax = 12, ymin = 0, ymax = 70, fill = "#FDE8E7", alpha = 0.6) +
  geom_line(aes(y = churn_rate), color = "#8DA0CB", alpha = 0.45, linewidth = 0.8) +
  geom_line(aes(y = churn_smooth), color = "#E74C3C", linewidth = 1.4) +
  geom_hline(yintercept = baseline_churn, linetype = "dashed", color = "#2C3E50", linewidth = 0.8) +
  annotate("text", x = 14, y = 58, label = "Year 1 Hazard Zone (Month 1 Churn > 50%)", 
           color = "#C0392B", fontface = "bold", size = 3.5, hjust = 0) +
  labs(title = "Figure 1: Customer Attrition Trajectory Across Account Tenure",
       subtitle = "Observed churn rate drops significantly after month 12 onboarding window",
       x = "Tenure (Months)", y = "Churn Rate (%)")

# 2. Monthly Charges Distribution Across Broadband Tiers (Violin-Boxplot)
ggplot(churn_df, aes(x = InternetService, y = MonthlyCharges, fill = Churn)) +
  geom_violin(position = position_dodge(0.8), alpha = 0.75, trim = FALSE) +
  geom_boxplot(position = position_dodge(0.8), width = 0.2, color = "#262626", outlier.size = 0.8) +
  scale_fill_manual(values = c("No" = "#2980B9", "Yes" = "#E74C3C")) +
  scale_y_continuous(labels = scales::dollar_format()) +
  labs(title = "Figure 2: Monthly Recurring Charges by Broadband Tier and Churn Outcome",
       x = "Internet Service Tier", y = "Monthly Charges ($)", fill = "Churn")

# 3. Multivariate Interaction Matrix (Contract x Broadband Tier)
heatmap_data <- churn_df %>%
  group_by(Contract, InternetService) %>%
  summarise(churn_rate = mean(Churn_num) * 100, .groups = "drop")

ggplot(heatmap_data, aes(x = InternetService, y = Contract, fill = churn_rate)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = sprintf("%.1f%%", churn_rate)), color = "black", fontface = "bold", size = 4.5) +
  scale_fill_gradient(low = "#FFF5EB", high = "#D94801", name = "Churn Rate (%)") +
  labs(title = "Figure 3: Churn Rate Heatmap by Contract Terms and Internet Service",
       x = "Internet Service Type", y = "Contract Commitment")

# 4. Monthly vs Total Lifetime Charges (Faceted Scatter with Trendline)
ggplot(churn_df, aes(x = MonthlyCharges, y = TotalCharges, color = Churn)) +
  geom_point(alpha = 0.35, size = 1.3) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 1.1) +
  facet_wrap(~ Contract) +
  scale_color_manual(values = c("No" = "#1F77B4", "Yes" = "#D62728")) +
  scale_x_continuous(labels = scales::dollar_format()) +
  scale_y_continuous(labels = scales::dollar_format()) +
  labs(title = "Figure 4: Monthly Recurring Fees vs Cumulative Spend Across Contract Types",
       x = "Monthly Fee ($)", y = "Cumulative Spend ($)", color = "Churn")

# 5. Payment Channel Benchmark (Lollipop Chart)
pm_summary <- churn_df %>%
  group_by(PaymentMethod) %>%
  summarise(churn_rate = mean(Churn_num) * 100, .groups = "drop") %>%
  arrange(churn_rate) %>%
  mutate(PaymentMethod = factor(PaymentMethod, levels = PaymentMethod))

ggplot(pm_summary, aes(x = churn_rate, y = PaymentMethod)) +
  geom_segment(aes(x = baseline_churn, xend = churn_rate, yend = PaymentMethod),
               color = "#BDC3C7", linewidth = 1.2) +
  geom_point(aes(color = churn_rate > baseline_churn), size = 5) +
  geom_vline(xintercept = baseline_churn, linetype = "dashed", color = "#2C3E50", linewidth = 0.8) +
  scale_color_manual(values = c("FALSE" = "#27AE60", "TRUE" = "#C0392B"), guide = "none") +
  geom_text(aes(label = sprintf("%.1f%%", churn_rate)), hjust = -0.3, size = 3.5, fontface = "bold") +
  scale_x_continuous(limits = c(10, 55), labels = function(x) paste0(x, "%")) +
  labs(title = "Figure 5: Payment Channel Churn Rates Relative to Portfolio Average",
       x = "Churn Rate (%)", y = "Payment Channel")

# 6. Demographic Intersections (Faceted Grouped Bar Chart)
demo_summary <- churn_df %>%
  group_by(SeniorCitizen, Partner, Dependents) %>%
  summarise(churn_rate = mean(Churn_num) * 100, .groups = "drop")

ggplot(demo_summary, aes(x = Partner, y = churn_rate, fill = Dependents)) +
  geom_bar(stat = "identity", position = position_dodge(0.8), width = 0.65) +
  geom_hline(yintercept = baseline_churn, linetype = "dotted", color = "black", linewidth = 0.8) +
  facet_wrap(~ SeniorCitizen, labeller = as_labeller(c("No" = "Non-Senior", "Yes" = "Senior Citizen"))) +
  scale_fill_manual(values = c("No" = "#E67E22", "Yes" = "#2980B9")) +
  scale_y_continuous(limits = c(0, 55), labels = function(x) paste0(x, "%")) +
  labs(title = "Figure 6: Household Demographics and Churn Rates",
       x = "Domestic Partner", y = "Churn Rate (%)", fill = "Has Dependents")

# 7. Diverging Risk Factors Relative to Baseline
risk_factors <- tribble(
  ~Segment, ~Observed_Rate,
  "Contract: Two Year", 2.83,
  "Tenure > 48 Months", 9.42,
  "Contract: One Year", 11.27,
  "Tech Support: Yes", 15.17,
  "Credit Card (Auto)", 15.24,
  "Bank Transfer (Auto)", 16.71,
  "Senior Citizen: Yes", 41.68,
  "Internet: Fiber Optic", 41.89,
  "Contract: Month-to-Month", 42.71,
  "Payment: Electronic Check", 45.29,
  "Tenure <= 12 Months", 47.68
) %>%
  mutate(
    risk_delta = (Observed_Rate - baseline_churn) / baseline_churn * 100,
    impact = ifelse(risk_delta > 0, "Risk Hazard", "Protective Factor"),
    Segment = factor(Segment, levels = Segment[order(risk_delta)])
  )

ggplot(risk_factors, aes(x = risk_delta, y = Segment, fill = impact)) +
  geom_col(width = 0.65) +
  geom_vline(xintercept = 0, color = "#2C3E50", linewidth = 0.9) +
  geom_text(aes(label = sprintf("%+0.1f%%", risk_delta)),
            hjust = ifelse(risk_factors$risk_delta > 0, -0.15, 1.15),
            size = 3.3, fontface = "bold") +
  scale_fill_manual(values = c("Risk Hazard" = "#C0392B", "Protective Factor" = "#27AE60")) +
  scale_x_continuous(limits = c(-105, 95), labels = function(x) paste0(x, "%")) +
  labs(title = "Figure 7: Operational Factors Ranked by Relative Risk Variance",
       x = "Percentage Shift Relative to Portfolio Baseline (26.5%)", y = "Operational Feature",
       fill = "Category")
