# AMR Explorer
# Explore bacterial resistance using WHO GLASS data.
# Works for any bacterium, specimen and antibiotic: drop the GLASS CSV
# exports into the "data" folder and they are picked up automatically.

library(tidyverse)
library(shiny)
library(plotly)

# ---- Settings ------------------------------------------------------------
download_date <- "27 October 2026"  # date the GLASS files were downloaded
small_n       <- 30                 # flag results with fewer tested isolates

# ---- Load data -----------------------------------------------------------
# GLASS exports contain filter notes and a summary table above the
# country-level data. read_glass() reads only the country table.
# Every column is read as text first so files with slightly different
# column types (common when mixing pathogens) can still be combined.
read_glass <- function(path) {
  lines <- read_lines(path)
  start <- grep('^"Iso3"', lines)
  if (length(start) == 0) {
    warning("Skipping ", basename(path),
            ": no country table (\"Iso3\" header) found.")
    return(NULL)
  }
  read_csv(I(paste(lines[start[1]:length(lines)], collapse = "\n")),
           col_types = cols(.default = col_character()))
}

files    <- list.files("data", pattern = "\\.csv$", full.names = TRUE)
amr_data <- bind_rows(map(files, read_glass)) |>
  type_convert(col_types = cols(.default = col_guess())) |>
  distinct()   # in case the same rows appear in more than one file

# One "dataset" = one bacterium from one specimen type,
# e.g. "Escherichia coli (blood)"
amr_data <- amr_data |>
  mutate(dataset = paste0(PathogenName, " (", str_to_lower(Specimen), ")"))

# ---- Antibiotic information ----------------------------------------------
# GLASS reports some results for a whole antibiotic class and some for a
# single antibiotic. Matching ignores upper/lower case and extra spaces.
# If the console says an antibiotic is "not classified", ADD A ROW HERE.
ab_info <- tribble(
  ~AbTargets,                         ~ab_type,            ~ab_class,
  # Classes
  "Third-generation cephalosporins",  "Antibiotic class",  "Third-generation cephalosporins",
  "Fourth-generation cephalosporins", "Antibiotic class",  "Fourth-generation cephalosporins",
  "Carbapenems",                      "Antibiotic class",  "Carbapenems",
  "Fluoroquinolones",                 "Antibiotic class",  "Fluoroquinolones",
  "Aminoglycosides",                  "Antibiotic class",  "Aminoglycosides",
  "Penicillins",                      "Antibiotic class",  "Penicillins",
  "Polymyxins",                       "Antibiotic class",  "Polymyxins",
  "Macrolides",                       "Antibiotic class",  "Macrolides",
  "Glycopeptides",                    "Antibiotic class",  "Glycopeptides",
  "Tetracyclines",                    "Antibiotic class",  "Tetracyclines",
  # Cephalosporins
  "Cefoxitin",                        "Single antibiotic", "Second-generation cephalosporins",
  "Ceftriaxone",                      "Single antibiotic", "Third-generation cephalosporins",
  "Cefotaxime",                       "Single antibiotic", "Third-generation cephalosporins",
  "Ceftazidime",                      "Single antibiotic", "Third-generation cephalosporins",
  "Cefixime",                         "Single antibiotic", "Third-generation cephalosporins",
  "Cefepime",                         "Single antibiotic", "Fourth-generation cephalosporins",
  # Carbapenems
  "Imipenem",                         "Single antibiotic", "Carbapenems",
  "Meropenem",                        "Single antibiotic", "Carbapenems",
  "Ertapenem",                        "Single antibiotic", "Carbapenems",
  "Doripenem",                        "Single antibiotic", "Carbapenems",
  # Fluoroquinolones
  "Ciprofloxacin",                    "Single antibiotic", "Fluoroquinolones",
  "Levofloxacin",                     "Single antibiotic", "Fluoroquinolones",
  # Aminoglycosides
  "Gentamicin",                       "Single antibiotic", "Aminoglycosides",
  "Amikacin",                         "Single antibiotic", "Aminoglycosides",
  "Spectinomycin",                    "Single antibiotic", "Aminocyclitols",
  # Penicillins
  "Ampicillin",                       "Single antibiotic", "Penicillins",
  "Penicillin G",                     "Single antibiotic", "Penicillins",
  "Benzylpenicillin",                 "Single antibiotic", "Penicillins",
  "Oxacillin",                        "Single antibiotic", "Penicillins",
  "Methicillin",                      "Single antibiotic", "Penicillins",
  "Methicillin resistance",           "Single antibiotic", "Penicillins",
  # Others
  "Colistin",                         "Single antibiotic", "Polymyxins",
  "Azithromycin",                     "Single antibiotic", "Macrolides",
  "Erythromycin",                     "Single antibiotic", "Macrolides",
  "Vancomycin",                       "Single antibiotic", "Glycopeptides",
  "Tetracycline",                     "Single antibiotic", "Tetracyclines",
  "Minocycline",                      "Single antibiotic", "Tetracyclines",
  "Tigecycline",                      "Single antibiotic", "Glycylcyclines",
  "Linezolid",                        "Single antibiotic", "Oxazolidinones",
  "Co-trimoxazole",                   "Single antibiotic", "Sulfonamide-trimethoprim combinations"
)

ab_key <- function(x) str_to_lower(str_squish(x))

amr_data <- amr_data |>
  mutate(key = ab_key(AbTargets)) |>
  left_join(ab_info |> mutate(key = ab_key(AbTargets)) |> select(-AbTargets),
            by = "key") |>
  select(-key) |>
  mutate(ab_type  = replace_na(ab_type,  "Not yet classified"),
         ab_class = replace_na(ab_class, "Not yet classified"))

unclassified <- amr_data |>
  filter(ab_type == "Not yet classified") |>
  distinct(AbTargets) |>
  pull(AbTargets)
if (length(unclassified) > 0) {
  message("These antibiotics are not classified in ab_info yet: ",
          paste(unclassified, collapse = ", "))
}

# ---- Choices for the dropdowns -------------------------------------------
datasets <- sort(unique(amr_data$dataset))
default_dataset <- datasets[str_detect(datasets,
                                       regex("^Escherichia coli \\(blood",
                                             ignore_case = TRUE))][1]
if (is.na(default_dataset)) default_dataset <- datasets[1]

# Choices that depend on the selected bacterium/specimen
choices_for <- function(d) {
  list(antibiotics = sort(unique(d$AbTargets)),
       countries   = sort(unique(d$CountryTerritoryArea)),
       years       = sort(unique(d$Year)),
       regions     = sort(unique(d$WHORegionName)))
}

# Keep the current selection if it still exists, otherwise fall back
keep_or_default <- function(current, choices, fallback = NULL) {
  if (!is.null(current) && current %in% choices) return(current)
  if (!is.null(fallback) && fallback %in% choices) return(fallback)
  choices[1]
}

init            <- choices_for(filter(amr_data, dataset == default_dataset))
default_country <- keep_or_default(NULL, init$countries, "Indonesia")

type_colours <- c("Antibiotic class"   = "#2C7FB8",
                  "Single antibiotic"  = "#7FCDBB",
                  "Not yet classified" = "grey60")

# Explanation shown under each chart
interpretation_note <- tagList(
  h4("What am I looking at?"),
  p("Resistance (%) is the share of tested isolates of the selected
     bacterium (from the selected specimen type) that were resistant to the
     antibiotic: resistant isolates divided by isolates with an
     interpretable susceptibility test result."),
  p(strong("Keep in mind: "),
    "these are surveillance data. They describe isolates reported to GLASS,
     not the chance that an individual patient's treatment will fail.
     Testing coverage differs between countries and years.")
)

# ---- User interface ------------------------------------------------------
ui <- navbarPage(
  title = "AMR Explorer",
  
  # Bacterium selector shown above every tab
  header = fluidRow(column(12,
                           wellPanel(
                             selectInput("dataset", "Bacterium and specimen",
                                         choices = datasets,
                                         selected = default_dataset,
                                         width = "450px"),
                             helpText("This choice applies to all tabs.")
                           )
  )),
  
  # Tab 1: Overview ---------------------------------------------------------
  tabPanel("Overview",
           fluidRow(column(10,
                           h2("Explore antimicrobial resistance"),
                           p("Antimicrobial resistance (AMR) happens when bacteria are no longer
         stopped by the medicines used to treat them, which makes infections
         harder to treat. Surveillance data show how common resistance is
         among bacteria tested in laboratories."),
                           p("This dashboard uses WHO GLASS data on bacteria isolated from
         patient specimens. Choose a bacterium and specimen at the top of the
         page, then use the tabs to see how resistance changed over time in
         one country, compare antibiotics within a country, or compare
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
               selectInput("trend_antibiotic", "Antibiotic",
                           choices = init$antibiotics),
               selectInput("trend_country", "Country", choices = init$countries,
                           selected = default_country),
               sliderInput("trend_years", "Years",
                           min = min(init$years), max = max(init$years),
                           value = range(init$years), step = 1, sep = "")
             ),
             mainPanel(
               h3("Resistance over time: ", textOutput("trend_heading", inline = TRUE)),
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
               selectInput("comp_country", "Country", choices = init$countries,
                           selected = default_country),
               selectInput("comp_year", "Year", choices = rev(init$years),
                           selected = max(init$years))
             ),
             mainPanel(
               h3("Resistance by antibiotic: ", textOutput("comp_heading", inline = TRUE)),
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
               selectInput("cty_antibiotic", "Antibiotic",
                           choices = init$antibiotics),
               selectInput("cty_year", "Year", choices = rev(init$years),
                           selected = max(init$years)),
               selectInput("cty_region", "WHO region",
                           choices = c("All regions", init$regions)),
               selectInput("cty_highlight", "Highlight country",
                           choices = init$countries, selected = default_country)
             ),
             mainPanel(
               h3("Resistance by country: ", textOutput("cty_heading", inline = TRUE)),
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
  
  # Data for the selected bacterium and specimen ----------------------------
  sel_data <- reactive({
    req(input$dataset)
    amr_data |> filter(dataset == input$dataset)
  })
  
  # When the bacterium changes, refresh every dropdown so it only offers
  # antibiotics, countries, years and regions that exist for it
  observeEvent(sel_data(), {
    ch <- choices_for(sel_data())
    req(length(ch$years) > 0)
    
    for (id in c("trend_antibiotic", "cty_antibiotic")) {
      updateSelectInput(session, id, choices = ch$antibiotics,
                        selected = keep_or_default(input[[id]], ch$antibiotics))
    }
    for (id in c("trend_country", "comp_country", "cty_highlight")) {
      updateSelectInput(session, id, choices = ch$countries,
                        selected = keep_or_default(input[[id]], ch$countries,
                                                   "Indonesia"))
    }
    for (id in c("comp_year", "cty_year")) {
      updateSelectInput(session, id, choices = rev(ch$years),
                        selected = keep_or_default(input[[id]], ch$years,
                                                   max(ch$years)))
    }
    updateSelectInput(session, "cty_region",
                      choices = c("All regions", ch$regions),
                      selected = keep_or_default(input$cty_region,
                                                 c("All regions", ch$regions)))
    updateSliderInput(session, "trend_years",
                      min = min(ch$years), max = max(ch$years),
                      value = range(ch$years))
  }, ignoreInit = TRUE)
  
  output$trend_heading <- renderText(input$dataset)
  output$comp_heading  <- renderText(input$dataset)
  output$cty_heading   <- renderText(input$dataset)
  
  # Overview ----------------------------------------------------------------
  output$data_overview <- renderTable({
    amr_data |>
      group_by(Bacterium = PathogenName,
               Specimen  = str_to_lower(Specimen)) |>
      summarise(Antibiotics = paste(sort(unique(AbTargets)), collapse = ", "),
                `Countries, territories and areas` =
                  as.integer(n_distinct(CountryTerritoryArea)),
                Years = paste(range(Year), collapse = " to "),
                .groups = "drop")
  })
  
  # Trends over time --------------------------------------------------------
  trend_selected <- reactive({
    req(input$trend_antibiotic, input$trend_country, input$trend_years)
    sel_data() |>
      filter(AbTargets == input$trend_antibiotic,
             CountryTerritoryArea == input$trend_country,
             between(Year, input$trend_years[1], input$trend_years[2])) |>
      arrange(Year)
  })
  
  output$trend_plot <- renderPlotly({
    d <- trend_selected()
    validate(need(nrow(d) > 0,
                  "GLASS has no data for this bacterium, country and antibiotic in the selected years."))
    
    p <- ggplot(d, aes(x = Year, y = PercentResistant,
                       text = paste0(
                         "Year: ", Year,
                         "<br>Resistant: ", round(PercentResistant, 1), "%",
                         "<br>", Resistant, " of ", InterpretableAST,
                         " isolates tested"))) +
      geom_line(aes(group = 1)) +
      geom_point(size = 2) +
      scale_y_continuous(limits = c(0, 100)) +
      scale_x_continuous(breaks = sort(unique(d$Year))) +
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
    req(input$comp_country, input$comp_year)
    sel_data() |>
      filter(CountryTerritoryArea == input$comp_country,
             Year == as.numeric(input$comp_year)) |>
      arrange(desc(PercentResistant))
  })
  
  output$comp_plot <- renderPlotly({
    d <- comp_selected()
    validate(need(nrow(d) > 0,
                  "GLASS has no data for this bacterium and country in the selected year."))
    
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
                Class             = ab_class,
                `Isolates tested` = as.integer(InterpretableAST),
                Resistant         = as.integer(Resistant),
                `Resistant (%)`   = round(PercentResistant, 1))
  })
  
  # Compare countries -------------------------------------------------------
  cty_selected <- reactive({
    req(input$cty_antibiotic, input$cty_year, input$cty_region)
    d <- sel_data() |>
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
                  "GLASS has no data for this bacterium, antibiotic, year and region."))
    
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

