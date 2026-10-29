# AMR Explorer
# Interactive Dashboard for Exploring Antimicrobial Resistance Patterns

# Load packages
library(tidyverse)
library(shiny)
library(plotly)

# Load the dataset ------------------------------------------------------
# GLASS exports contain filter notes and a summary table above the
# country-level data. read_glass() finds the country table header
# ("Iso3", ...) and reads only from there.
read_glass <- function(path) {
  lines <- read_lines(path)
  start <- grep('^"Iso3"', lines)
  read_csv(I(paste(lines[start:length(lines)], collapse = "\n")),
           show_col_types = FALSE)
}

files <- list.files("data", pattern = "\\.csv$", full.names = TRUE)
files   # should show your 3 E. coli files

amr_data <- map_dfr(files, read_glass)

# Inspect the dataset ---------------------------------------------------
names(amr_data)
glimpse(amr_data)
dim(amr_data)

# First checks ------------------------------------------------------------
count(amr_data, PathogenName, AbTargets)   # all E. coli? which antibiotics?
count(amr_data, Specimen)                  # all BLOOD?
range(amr_data$Year)                       # 2018-2023?
"IDN" %in% amr_data$Iso3                   # is Indonesia in the data?
n_distinct(amr_data$CountryTerritoryArea)  # how many countries?
colSums(is.na(amr_data))                   # missing values
sum(duplicated(amr_data))                  # duplicate rows

# Validation: PercentResistant should equal Resistant / InterpretableAST
amr_data |>
  mutate(my_pct = Resistant / InterpretableAST * 100,
         diff   = abs(my_pct - PercentResistant)) |>
  summarise(max_diff = max(diff, na.rm = TRUE))
years_check <- amr_data |>
  count(AbTargets, CountryTerritoryArea, name = "n_years") |>
  filter(n_years < 6)

indonesia <- amr_data |>
  filter(Iso3 == "IDN") |>
  select(Year, AbTargets, InterpretableAST, Resistant, PercentResistant) |>
  arrange(AbTargets, Year)

small_n <- amr_data |>
  filter(InterpretableAST < 30) |>
  count(AbTargets)

View(years_check)
View(indonesia)
View(small_n)

# Save results -----------------------------------------------------------
dir.create("outputs", showWarnings = FALSE)

write_csv(years_check, "outputs/countries_missing_years.csv")
write_csv(indonesia,   "outputs/indonesia_data.csv")
write_csv(small_n,     "outputs/small_sample_sizes.csv")

# First chart: Indonesia's resistance over time --------------------------
indonesia_plot <- amr_data |>
  filter(Iso3 == "IDN") |>
  ggplot(aes(x = Year, y = PercentResistant, colour = AbTargets)) +
  geom_line() +
  geom_point() +
  scale_y_continuous(limits = c(0, 100)) +
  labs(title = "E. coli bloodstream isolates, Indonesia",
       x = NULL, y = "Resistant (%)", colour = "Antibiotic") +
  theme_minimal()

indonesia_plot
ggsave("outputs/indonesia_trend.png", indonesia_plot,
       width = 8, height = 5, dpi = 300)
