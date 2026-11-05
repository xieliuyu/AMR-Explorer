# AMR Explorer: An Interactive Dashboard for Exploring Antimicrobial Resistance Patterns

## Project Overview

AMR Explorer is an interactive dashboard built with R and Shiny that allows users to explore reported antimicrobial resistance (AMR) patterns using data from the World Health Organization (WHO) Global Antimicrobial Resistance and Use Surveillance System (GLASS).

The project is intended to help biomedical science students and other learners understand how reported antimicrobial resistance patterns vary across bacterial pathogens, antibiotics, countries, and years.

## How to Run the App

1. Download this repository (green **Code** button → **Download ZIP**) and unzip it.
2. Open `AMR_Explorer.Rproj` in RStudio.
3. Install the required packages by running this in the Console:
   ```r
   renv::restore()
   ```
4. Open `app.R` and click **Run App**.

Requires R (version 4.6.1 was used for development) and RStudio.

## Research Question

How do reported antimicrobial resistance patterns vary over time across selected bacterial pathogens, antibiotics, and countries?

## Project Objectives

- Explore publicly available WHO GLASS antimicrobial resistance surveillance data.
- Visualize selected resistance indicators over time using interactive graphs.
- Allow users to filter the data based on available variables.
- Present summary information and explain the meaning and limitations of the selected indicators.
- Develop a beginner-friendly dashboard for exploring AMR surveillance data.

## Data Source

Data were downloaded from the [WHO GLASS Dashboard](https://worldhealthorg.shinyapps.io/glass-dashboard/) on October 2026 as CSV files.

| Pathogen | Antibiotic(s) | File(s) |
|---|---|---|
| *Escherichia coli* | Third-generation cephalosporins, ceftriaxone, ciprofloxacin | `ecoli_3gc.csv`, `ecoli_ceftriaxone.csv`, `ecoli_ciprofloxacin.csv` |
| *Streptococcus pneumoniae* | Ceftriaxone, penicillin | `pneumonia_cefriaxone.csv`, `pneumonia_penicillin.csv` |
| *Salmonella* spp. | Ceftriaxone, ciprofloxacin | `salmonella_cefriaxone.csv`, `salmonella_ciproflaxin.csv` |
| *Staphylococcus aureus* | Methicillin (MRSA) | `straphylococcusareus_methicillin.csv` |

- **Reporting period:** 2018–2023
- **Countries:** all countries reporting data to GLASS for each pathogen–antibiotic combination
- **Main variable:** percentage of resistant isolates (%)

## Tools and Technologies

- **R:** Data processing and analysis.
- **RStudio:** Development environment.
- **Shiny:** Interactive dashboard development.
- **ggplot2:** Data visualization.
- **GitHub:** Project version control and documentation.

## Current Features

The dashboard has three interactive tabs, with data available for four pathogens:

- **Pathogen selection:** choose between *E. coli*, *S. pneumoniae*, *Salmonella* spp., and *S. aureus*.
- **Trends over time:** select an antibiotic and a country from drop-down menus and set a year range with a slider. An interactive line graph shows the percentage of resistant isolates for each year.
- **Compare antibiotics:** select a country and a year to compare resistance across the available antibiotics in a bar chart. Colours distinguish an antibiotic class (third-generation cephalosporins) from single antibiotics, and a note explains that these results overlap because ceftriaxone belongs to that class.
- **Compare countries:** select an antibiotic and a year to rank countries by resistance in a bar chart. Results can be filtered by WHO region, and one country can be highlighted for easier comparison.

## Planned Features

- Scientific validation of dashboard outputs against the source data.

## Scientific Considerations

The dashboard will describe reported surveillance data rather than predict individual patient outcomes or recommend antibiotic treatments. Missing data, differences in reporting coverage, and indicator definitions will be considered during analysis and interpretation.

## Project Status

**Status: MVP complete, validation in progress**

The core dashboard is working. Current work focuses on scientific validation of outputs against the source data and adding further features.

## AI-Assisted Development

AI assistance will be documented throughout the project, including prompts, code changes, debugging issues, assumptions identified during review, and validation checks.

## License

The code in this repository is licensed under the MIT License. See `LICENSE.md` for details.

The data in `data/` were obtained from WHO GLASS and remain subject to WHO's terms of use. They are not covered by this repository's license.


## Repository Structure

- `app.R` — the Shiny dashboard
- `explore.R` — data inspection and exploration script
- `data/` — WHO GLASS data files (CSV)
- `renv.lock`, `renv/`, `.Rprofile` — package environment for reproducibility
