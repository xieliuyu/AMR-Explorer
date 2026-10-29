# AMR Explorer
# Explore E. coli resistance in bloodstream infections using WHO GLASS data

library(tidyverse)
library(shiny)
library(plotly)

# ---- Settings ------------------------------------------------------------
download_date <- "27 October 2026"  # date the GLASS files were downloaded
small_n       <- 30                 # flag results with fewer tested isolates

# ---- Load data -----------------------------------------------------------
# GLASS exports contain filter notes and a summary table above the
# country-level data. read_glass() reads only the country table.
read_glass <- function(path) {
  lines <- read_lines(path)
  start <- grep('^"Iso3"', lines)
  read_csv(I(paste(lines[start:length(lines)], collapse = "\n")),
           show_col_types = FALSE)
}

files    <- list.files("data", pattern = "\\.csv$", full.names = TRUE)
amr_data <- map_dfr(files, read_glass)

# ---- Antibiotic information ----------------------------------------------
# GLASS reports some results for a whole antibiotic class and some for a
# single antibiotic. ADD A ROW HERE whenever you add a new antibiotic file.
ab_info <- tribble(
  ~AbTargets,                        ~ab_type,            ~ab_class,
  "Third-generation cephalosporins", "Antibiotic class",  "Third-generation cephalosporins",
  "Ceftriaxone",                     "Single antibiotic", "Third-generation cephalosporins",
  "Ciprofloxacin",                   "Single antibiotic", "Fluoroquinolones"
)

amr_data <- amr_data |>
  left_join(ab_info, by = "AbTargets") |>
  mutate(ab_type  = replace_na(ab_type,  "Not yet classified"),
         ab_class = replace_na(ab_class, "Not yet classified"))

# Choices for the dropdowns come from the data
antibiotics     <- sort(unique(amr_data$AbTargets))
countries       <- sort(unique(amr_data$CountryTerritoryArea))
years           <- sort(unique(amr_data$Year))
year_range      <- range(years)
regions         <- sort(unique(amr_data$WHORegionName))
default_country <- if ("Indonesia" %in% countries) "Indonesia" else countries[1]

type_colours <- c("Antibiotic class"   = "#2C7FB8",
                  "Single antibiotic"  = "#7FCDBB",
                  "Not yet classified" = "grey60")

# Explanation shown under each chart
interpretation_note <- tagList(
  h4("What am I looking at?"),
  p("Resistance (%) is the share of tested E. coli blood isolates that were
     resistant to the antibiotic: resistant isolates divided by isolates
     with an interpretable susceptibility test result."),
  p(strong("Keep in mind: "),
    "these are surveillance data. They describe isolates reported to GLASS,
     not the chance that an individual patient's treatment will fail.
     Testing coverage differs between countries and years.")
)

# ---- User interface ------------------------------------------------------
ui <- navbarPage(
  title = "AMR Explorer",

  # Tab 1: Overview ---------------------------------------------------------
  tabPanel("Overview",
    fluidRow(column(8,
      h2("Explore antimicrobial resistance in E. coli"),
      p("Antimicrobial resistance (AMR) happens when bacteria are no longer
         stopped by the medicines used to treat them, which makes infections
         harder to treat. Surveillance data show how common resistance is
         among bacteria tested in laboratories."),
      p("This dashboard uses WHO GLASS data on E. coli from bloodstream
         infections. Use the tabs above to see how resistance changed over
         time in one country, compare antibiotics within a country, or compare
         countries for one antibiotic."),
      h3("About the data"),
      tableOutput("data_overview"),
      p("Source: WHO Global Antimicrobial Resistance and Use Surveillance
         System (GLASS) dashboard, ",
        a("worldhealthorg.shinyapps.io/glass-dashboard",
          href = "https://worldhealthorg.shinyapps.io/glass-dashboard/",
          target = "_blank"),
        ". Data downloaded ", download_date, "."),
      p("GLASS time series only include countries that reported data for at
         least 70% of the years from 2018 to 2023, so some countries are not
         shown.")
    ))
  ),

  # Tab 2: Trends over time -------------------------------------------------
  tabPanel("Trends over time",
    sidebarLayout(
      sidebarPanel(
        selectInput("trend_antibiotic", "Antibiotic", choices = antibiotics),
        selectInput("trend_country", "Country", choices = countries,
                    selected = default_country),
        sliderInput("trend_years", "Years",
                    min = year_range[1], max = year_range[2],
                    value = year_range, step = 1, sep = "")
      ),
      mainPanel(
        h3("Resistance over time"),
        plotlyOutput("trend_plot"),
        textOutput("trend_small_n"),
        h3("Data for this selection"),
        tableOutput("trend_table"),
        interpretation_note
      )
    )
  ),

  # Tab 3: Compare antibiotics ----------------------------------------------
  tabPanel("Compare antibiotics",
    sidebarLayout(
      sidebarPanel(
        selectInput("comp_country", "Country", choices = countries,
                    selected = default_country),
        selectInput("comp_year", "Year", choices = rev(years),
                    selected = max(years))
      ),
      mainPanel(
        h3("Resistance by antibiotic"),
        plotlyOutput("comp_plot"),
        textOutput("comp_small_n"),
        p(em("A class result covers the antibiotics in that class, so it
              overlaps with single antibiotics from the same class (for
              example, ceftriaxone is a third-generation cephalosporin).
              These bars are not independent of each other.")),
        h3("Data for this selection"),
        tableOutput("comp_table"),
        interpretation_note
      )
    )
  ),

  # Tab 4: Compare countries ------------------------------------------------
  tabPanel("Compare countries",
    sidebarLayout(
      sidebarPanel(
        selectInput("cty_antibiotic", "Antibiotic", choices = antibiotics),
        selectInput("cty_year", "Year", choices = rev(years),
                    selected = max(years)),
        selectInput("cty_region", "WHO region",
                    choices = c("All regions", regions)),
        selectInput("cty_highlight", "Highlight country", choices = countries,
                    selected = default_country)
      ),
      mainPanel(
        h3("Resistance by country"),
        plotlyOutput("cty_plot", height = "800px"),
        textOutput("cty_note"),
        p(em("Countries differ in how many patients are tested and which
              laboratories report to GLASS, so differences between countries
              may partly reflect testing practices, not resistance alone.")),
        h3("Data for this selection"),
        tableOutput("cty_table"),
        interpretation_note
      )
    )
  )
)

# ---- Server --------------------------------------------------------------
server <- function(input, output, session) {

  # Overview ----------------------------------------------------------------
  output$data_overview <- renderTable({
    tibble(
      Item  = c("Pathogen", "Specimen", "Antibiotics",
                "Countries, territories and areas", "Years"),
      Value = c(paste(sort(unique(amr_data$PathogenName)), collapse = ", "),
                paste(sort(unique(amr_data$Specimen)), collapse = ", "),
                paste(antibiotics, collapse = ", "),
                as.character(length(countries)),
                paste(year_range, collapse = " to "))
    )
  })

  # Trends over time --------------------------------------------------------
  trend_selected <- reactive({
    amr_data |>
      filter(AbTargets == input$trend_antibiotic,
             CountryTerritoryArea == input$trend_country,
             between(Year, input$trend_years[1], input$trend_years[2])) |>
      arrange(Year)
  })

  output$trend_plot <- renderPlotly({
    d <- trend_selected()
    validate(need(nrow(d) > 0,
                  "GLASS has no data for this country and antibiotic in the selected years."))

    p <- ggplot(d, aes(x = Year, y = PercentResistant,
                       text = paste0(
                         "Year: ", Year,
                         "<br>Resistant: ", round(PercentResistant, 1), "%",
                         "<br>", Resistant, " of ", InterpretableAST,
                         " isolates tested"))) +
      geom_line(aes(group = 1)) +
      geom_point(size = 2) +
      scale_y_continuous(limits = c(0, 100)) +
      scale_x_continuous(breaks = years) +
      labs(x = NULL, y = "Resistant (%)") +
      theme_minimal()

    ggplotly(p, tooltip = "text")
  })

  output$trend_small_n <- renderText({
    few <- trend_selected() |> filter(InterpretableAST < small_n)
    if (nrow(few) == 0) return("")
    paste0("Caution: fewer than ", small_n, " isolates were tested in ",
           paste(few$Year, collapse = ", "),
           ", so those percentages are less reliable.")
  })

  output$trend_table <- renderTable({
    trend_selected() |>
      transmute(Year              = as.integer(Year),
                `Isolates tested` = as.integer(InterpretableAST),
                Resistant         = as.integer(Resistant),
                `Resistant (%)`   = round(PercentResistant, 1))
  })

  # Compare antibiotics -----------------------------------------------------
  comp_selected <- reactive({
    amr_data |>
      filter(CountryTerritoryArea == input$comp_country,
             Year == as.numeric(input$comp_year)) |>
      arrange(desc(PercentResistant))
  })

  output$comp_plot <- renderPlotly({
    d <- comp_selected()
    validate(need(nrow(d) > 0,
                  "GLASS has no data for this country in the selected year."))

    p <- ggplot(d, aes(x = reorder(AbTargets, PercentResistant),
                       y = PercentResistant,
                       fill = ab_type,
                       text = paste0(
                         AbTargets, " (", ab_type, ")",
                         "<br>Resistant: ", round(PercentResistant, 1), "%",
                         "<br>", Resistant, " of ", InterpretableAST,
                         " isolates tested"))) +
      geom_col(width = 0.6) +
      coord_flip() +
      scale_y_continuous(limits = c(0, 100)) +
      scale_fill_manual(values = type_colours) +
      labs(x = NULL, y = "Resistant (%)", fill = NULL) +
      theme_minimal()

    ggplotly(p, tooltip = "text")
  })

  output$comp_small_n <- renderText({
    few <- comp_selected() |> filter(InterpretableAST < small_n)
    if (nrow(few) == 0) return("")
    paste0("Caution: fewer than ", small_n, " isolates were tested for ",
           paste(few$AbTargets, collapse = ", "),
           ", so those percentages are less reliable.")
  })

  output$comp_table <- renderTable({
    comp_selected() |>
      transmute(Antibiotic        = AbTargets,
                Type              = ab_type,
                `Isolates tested` = as.integer(InterpretableAST),
                Resistant         = as.integer(Resistant),
                `Resistant (%)`   = round(PercentResistant, 1))
  })

  # Compare countries -------------------------------------------------------
  cty_selected <- reactive({
    d <- amr_data |>
      filter(AbTargets == input$cty_antibiotic,
             Year == as.numeric(input$cty_year))
    if (input$cty_region != "All regions") {
      d <- d |> filter(WHORegionName == input$cty_region)
    }
    d |>
      mutate(highlight = if_else(CountryTerritoryArea == input$cty_highlight,
                                 "Highlighted country", "Other countries"),
             # mark small samples with * in the chart labels
             label = if_else(InterpretableAST < small_n,
                             paste0(CountryTerritoryArea, " *"),
                             CountryTerritoryArea)) |>
      arrange(desc(PercentResistant))
  })

  output$cty_plot <- renderPlotly({
    d <- cty_selected()
    validate(need(nrow(d) > 0,
                  "GLASS has no data for this antibiotic, year and region."))

    p <- ggplot(d, aes(x = reorder(label, PercentResistant),
                       y = PercentResistant,
                       fill = highlight,
                       text = paste0(
                         CountryTerritoryArea, " (", WHORegionName, ")",
                         "<br>Resistant: ", round(PercentResistant, 1), "%",
                         "<br>", Resistant, " of ", InterpretableAST,
                         " isolates tested"))) +
      geom_col(width = 0.7) +
      coord_flip() +
      scale_y_continuous(limits = c(0, 100)) +
      scale_fill_manual(values = c("Highlighted country" = "#D95F02",
                                   "Other countries"     = "grey70")) +
      labs(x = NULL, y = "Resistant (%)", fill = NULL) +
      theme_minimal()

    ggplotly(p, tooltip = "text")
  })

  output$cty_note <- renderText({
    d <- cty_selected()
    notes <- character(0)
    if (any(d$InterpretableAST < small_n)) {
      notes <- c(notes, paste0("* Fewer than ", small_n,
                               " isolates tested, so the percentage is less reliable."))
    }
    if (!(input$cty_highlight %in% d$CountryTerritoryArea)) {
      notes <- c(notes, paste0(input$cty_highlight,
                               " is not shown: no data for this antibiotic, year and region."))
    }
    paste(notes, collapse = " ")
  })

  output$cty_table <- renderTable({
    cty_selected() |>
      transmute(Country           = CountryTerritoryArea,
                `WHO region`      = WHORegionName,
                `Isolates tested` = as.integer(InterpretableAST),
                Resistant         = as.integer(Resistant),
                `Resistant (%)`   = round(PercentResistant, 1))
  })
}

shinyApp(ui, server)
