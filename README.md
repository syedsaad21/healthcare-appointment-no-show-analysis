healthcare-appointment-no-show-analysis/
│
├── Dashboard/
│   └── Appointment_No_Show_Interactive_Dashboard.html
│
├── Dataset/
│   └── Appointments_Combined_Clean.csv
│
├── Analysis/
│   ├── Analysis_Report.md
│   ├── Data_Quality_and_Findings.txt
│   └── Dashboard_Build_Guide.md
│
├── DAX/
│   └── DAX_Measures.dax
│
├── Power_Query/
│   └── Power_Query_M.m
│
├── Theme/
│   └── PowerBI_Theme.json
│
└── README.md
# Healthcare Appointment No-Show Analysis

## Project Overview
An end-to-end healthcare data analytics project focused on understanding patient appointment attendance patterns and identifying factors associated with missed appointments.

The project combines two healthcare datasets containing 110,527 appointment records to analyze attendance outcomes, historical patient behaviour, appointment lead times and risk categories.

## Dataset Overview
- Total appointments: 110,527
- Unique patients: 61,744
- Neighbourhoods: 81
- Observed no-shows: 22,319
- Observed no-show rate: 20.19%

## Tools & Technologies
- Python (Pandas)
- Data Cleaning and Data Integration
- Exploratory Data Analysis
- HTML and JavaScript
- Plotly Interactive Visualizations
- DAX and Power Query reference files

## Project Workflow
1. Dataset inspection and validation.
2. Integration of two datasets using Appointment ID.
3. Data cleaning and preparation.
4. Analysis of appointment attendance outcomes.
5. Risk-tier and patient-history analysis.
6. Interactive dashboard development.
7. Analytical findings and documentation.

## Dashboard Features
- Appointment KPI cards
- Actual no-show rate analysis
- Weekday attendance patterns
- Lead-time analysis
- Risk-tier comparisons
- Neighbourhood-level analysis
- SMS receipt comparisons
- Appointment-level detail table
- Interactive filters and CSV export

## Key Finding
The overall observed appointment no-show rate was 20.19%, representing 22,319 missed appointments out of 110,527 records.

## Project Limitations
This is historical observational data from 2016. Associations do not establish causation. The supplied risk tiers are treated as existing classifications, not as a newly validated predictive model.

## Dashboard
Open `Dashboard/Appointment_No_Show_Interactive_Dashboard.html` locally in a browser to explore the interactive dashboard.

## Author
Healthcare Data Analytics Portfolio Project
