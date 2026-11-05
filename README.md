# AMR Explorer: An Interactive Dashboard for Exploring Antimicrobial Resistance Patterns

## Project Overview

AMR Explorer is a biomedical data analysis project that aims to develop an interactive dashboard using R, RStudio, and Shiny. The dashboard will allow users to explore reported antimicrobial resistance (AMR) patterns using data from the World Health Organization (WHO) Global Antimicrobial Resistance and Use Surveillance System (GLASS).

The project is intended to help biomedical science students and other learners understand how reported antimicrobial resistance patterns vary across bacterial pathogens, antibiotics, countries, and years.

## Research Question

How do reported antimicrobial resistance patterns vary over time across selected bacterial pathogens, antibiotics, and countries?

## Project Objectives

- Explore publicly available WHO GLASS antimicrobial resistance surveillance data.
- Visualize selected resistance indicators over time using interactive graphs.
- Allow users to filter the data based on available variables.
- Present summary information and explain the meaning and limitations of the selected indicators.
- Develop a beginner-friendly dashboard for exploring AMR surveillance data.

## Data Source

Data were downloaded from the [WHO GLASS Dashboard](https://worldhealthorg.shinyapps.io/glass-dashboard/) on [DATE] as CSV files.

| Pathogen | Antibiotic(s) | File(s) |
|---|---|---|
| *Escherichia coli* | Third-generation cephalosporins, ceftriaxone, ciprofloxacin | `ecoli_3gc.csv`, `ecoli_ceftriaxone.csv`, `ecoli_ciprofloxacin.csv` |
| *Streptococcus pneumoniae* | Ceftriaxone, penicillin | `pneumonia_cefriaxone.csv`, `pneumonia_penicillin.csv` |
| *Salmonella* spp. | Ceftriaxone, ciprofloxacin | `salmonella_cefriaxone.csv`, `salmonella_ciproflaxin.csv` |
| *Staphylococcus aureus* | Methicillin (MRSA) | `straphylococcusareus_methicillin.csv` |

- **Reporting period:** [e.g. 2018–2023]
- **Countries:** [list, or "all countries reporting to GLASS"]
- **Main variable:** resistance proportion (%), [plus number of isolates tested, if included]

## Tools and Technologies

- **R:** Data processing and analysis.
- **RStudio:** Development environment.
- **Shiny:** Interactive dashboard development.
- **ggplot2:** Data visualization.
- **GitHub:** Project version control and documentation.

## Planned Features

The minimum viable product (MVP) will include:

- Data import and inspection.
- Filters for variables supported by the dataset.
- A line graph showing a selected resistance indicator over time.
- Summary information about the selected data.
- Explanations of the indicator and relevant data limitations.

Additional features may be considered after the minimum viable product has been tested and validated.

## Scientific Considerations

The dashboard will describe reported surveillance data rather than predict individual patient outcomes or recommend antibiotic treatments. Missing data, differences in reporting coverage, and indicator definitions will be considered during analysis and interpretation.

## Project Status

**Status: In Development**

The project will proceed through dataset selection and inspection, data preparation, visualization, Shiny application development, testing, and scientific validation.

## AI-Assisted Development

AI assistance will be documented throughout the project, including prompts, code changes, debugging issues, assumptions identified during review, and validation checks.

## License

The code in this repository is licensed under [LICENSE NAME]; see `LICENSE.md`.
The data in `data/` are from WHO GLASS and remain subject to WHO's terms of use; they are not covered by this repository's license.

## How to Run the App

1. Download this repository (green **Code** button → **Download ZIP**) and unzip it.
2. Open `AMR_Explorer.Rproj` in RStudio.
3. Install the required packages by running this in the Console:
   ```r
   renv::restore()
   ```
4. Open `app.R` and click **Run App**.

Requires R (version 4.6.1 was used for development) and RStudio.

## Repository Structure

- `app.R` — the Shiny dashboard
- `explore.R` — data inspection and exploration script
- `data/` — WHO GLASS data files (CSV)
- `renv.lock`, `renv/`, `.Rprofile` — package environment for reproducibility
- 
