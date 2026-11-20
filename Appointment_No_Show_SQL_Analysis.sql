/*
PROJECT: Medical Appointment No-Show Analysis
DATASET: KaggleV2-May-2016 (Brazilian medical appointments)
DATABASE: PostgreSQL
SOURCE TABLE: clinical_trial.patients

Purpose:
Explore appointment attendance, no-show patterns, lead time, patient
demographics, neighbourhoods, SMS reminders and health indicators.

IMPORTANT:
- This script assumes the imported raw table is clinical_trial.patients.
- It uses the original source columns; it does not modify or delete raw data.
- "Yes" in no_show means the patient did not attend.
- SMS comparisons are descriptive and do not prove that SMS caused attendance.
*/

-- =========================================================
-- 1. OVERALL DATASET SUMMARY
-- =========================================================
SELECT
    COUNT(*) AS total_appointments,
    COUNT(DISTINCT appointmentid) AS unique_appointments,
    COUNT(DISTINCT patientid) AS unique_patients,
    COUNT(*) FILTER (WHERE no_show = 'Yes') AS no_show_appointments,
    COUNT(*) FILTER (WHERE no_show = 'No') AS attended_appointments,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    ) AS no_show_percentage
FROM clinical_trial.patients;


-- =========================================================
-- 2. CHECK DATA QUALITY
-- =========================================================
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE appointmentid IS NULL) AS missing_appointment_id,
    COUNT(*) FILTER (WHERE patientid IS NULL) AS missing_patient_id,
    COUNT(*) FILTER (WHERE appointmentday IS NULL) AS missing_appointment_day,
    COUNT(*) FILTER (WHERE scheduledday IS NULL) AS missing_scheduled_day,
    COUNT(*) FILTER (WHERE no_show IS NULL) AS missing_outcome
FROM clinical_trial.patients;

-- Check whether appointment IDs occur more than once.
SELECT
    appointmentid,
    COUNT(*) AS row_count
FROM clinical_trial.patients
GROUP BY appointmentid
HAVING COUNT(*) > 1
ORDER BY row_count DESC;


-- =========================================================
-- 3. NO-SHOW RATE BY GENDER
-- =========================================================
SELECT
    gender,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show = 'Yes') AS no_shows,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    ) AS no_show_rate_percent
FROM clinical_trial.patients
GROUP BY gender
ORDER BY no_show_rate_percent DESC;


-- =========================================================
-- 4. NO-SHOW RATE BY AGE GROUP
-- Excludes invalid ages outside 0-100 from age-group analysis.
-- =========================================================
SELECT
    CASE
        WHEN age BETWEEN 0 AND 12 THEN '0-12'
        WHEN age BETWEEN 13 AND 19 THEN '13-19'
        WHEN age BETWEEN 20 AND 35 THEN '20-35'
        WHEN age BETWEEN 36 AND 50 THEN '36-50'
        WHEN age BETWEEN 51 AND 65 THEN '51-65'
        WHEN age BETWEEN 66 AND 100 THEN '66-100'
    END AS age_group,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show = 'Yes') AS no_shows,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    ) AS no_show_rate_percent
FROM clinical_trial.patients
WHERE age BETWEEN 0 AND 100
GROUP BY age_group
ORDER BY MIN(age);


-- =========================================================
-- 5. NO-SHOW RATE BY APPOINTMENT WEEKDAY
-- =========================================================
SELECT
    TO_CHAR(appointmentday::date, 'FMDay') AS appointment_weekday,
    EXTRACT(ISODOW FROM appointmentday::date) AS weekday_sort,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show = 'Yes') AS no_shows,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    ) AS no_show_rate_percent
FROM clinical_trial.patients
GROUP BY appointmentday::date
ORDER BY weekday_sort;


-- Weekday-level aggregation (one row per weekday).
SELECT
    TO_CHAR(appointmentday::date, 'FMDay') AS appointment_weekday,
    EXTRACT(ISODOW FROM appointmentday::date) AS weekday_sort,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show = 'Yes') AS no_shows,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    ) AS no_show_rate_percent
FROM clinical_trial.patients
GROUP BY
    EXTRACT(ISODOW FROM appointmentday::date),
    TO_CHAR(appointmentday::date, 'FMDay')
ORDER BY weekday_sort;


-- =========================================================
-- 6. LEAD TIME ANALYSIS
-- Lead time here is calendar-date difference:
-- appointment date minus scheduled/booking date.
-- =========================================================
WITH appointment_lead AS (
    SELECT
        appointmentid,
        no_show,
        (appointmentday::date - scheduledday::date) AS lead_time_days
    FROM clinical_trial.patients
    WHERE appointmentday IS NOT NULL
      AND scheduledday IS NOT NULL
)
SELECT
    CASE
        WHEN lead_time_days <= 0 THEN 'Same day'
        WHEN lead_time_days BETWEEN 1 AND 3 THEN '1-3 days'
        WHEN lead_time_days BETWEEN 4 AND 7 THEN '4-7 days'
        WHEN lead_time_days BETWEEN 8 AND 14 THEN '8-14 days'
        WHEN lead_time_days BETWEEN 15 AND 30 THEN '15-30 days'
        ELSE '31+ days'
    END AS lead_time_bucket,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show = 'Yes') AS no_shows,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    ) AS no_show_rate_percent
FROM appointment_lead
GROUP BY lead_time_bucket
ORDER BY MIN(lead_time_days);


-- =========================================================
-- 7. SMS RECEIVED VS NO-SHOW RATE
-- Descriptive comparison only; not a causal analysis.
-- =========================================================
SELECT
    sms_received,
    CASE
        WHEN sms_received = 1 THEN 'SMS received'
        WHEN sms_received = 0 THEN 'No SMS'
        ELSE 'Unknown'
    END AS sms_group,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show = 'Yes') AS no_shows,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    ) AS no_show_rate_percent
FROM clinical_trial.patients
GROUP BY sms_received
ORDER BY sms_received;


-- =========================================================
-- 8. TOP 15 NEIGHBOURHOODS BY NO-SHOW RATE
-- Minimum 100 appointments to reduce unstable small-group rates.
-- =========================================================
SELECT
    neighbourhood,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show = 'Yes') AS no_shows,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    ) AS no_show_rate_percent
FROM clinical_trial.patients
GROUP BY neighbourhood
HAVING COUNT(*) >= 100
ORDER BY no_show_rate_percent DESC
LIMIT 15;


-- =========================================================
-- 9. NO-SHOW RATE BY HEALTH CONDITIONS
-- =========================================================
SELECT
    'Hypertension' AS health_condition,
    hypertension AS condition_present,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show = 'Yes') AS no_shows,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    ) AS no_show_rate_percent
FROM clinical_trial.patients
GROUP BY hypertension

UNION ALL

SELECT
    'Diabetes',
    diabetes,
    COUNT(*),
    COUNT(*) FILTER (WHERE no_show = 'Yes'),
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    )
FROM clinical_trial.patients
GROUP BY diabetes

UNION ALL

SELECT
    'Alcoholism',
    alcoholism,
    COUNT(*),
    COUNT(*) FILTER (WHERE no_show = 'Yes'),
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    )
FROM clinical_trial.patients
GROUP BY alcoholism

ORDER BY health_condition, condition_present;


-- =========================================================
-- 10. MONTHLY APPOINTMENT TREND
-- =========================================================
SELECT
    TO_CHAR(appointmentday::date, 'YYYY-MM') AS appointment_month,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE no_show = 'Yes') AS no_shows,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE no_show = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    ) AS no_show_rate_percent
FROM clinical_trial.patients
GROUP BY TO_CHAR(appointmentday::date, 'YYYY-MM')
ORDER BY appointment_month;


-- =========================================================
-- 11. FINAL COMPARISON: ATTENDED VS DID NOT ATTEND
-- =========================================================
SELECT
    no_show AS appointment_outcome,
    COUNT(*) AS appointment_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2
    ) AS percentage_of_appointments
FROM clinical_trial.patients
GROUP BY no_show
ORDER BY appointment_count DESC;


-- =========================================================
-- END OF ANALYSIS
-- Interpretation note:
-- These results describe associations and attendance patterns in
-- this historical dataset. They do not establish causation.
-- The lead-time calculation above uses direct date subtraction;
-- the dashboard's engineered lead_time_days field may use a
-- different convention. Keep definitions consistent when comparing.
-- =========================================================
