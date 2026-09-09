-- ---------------------------------------------------------------------------
-- stg_risk_assess_monthly_assessments
--
-- The time-series fact: one row per source assessment. 25,200 rows covering
-- 2022-01-01 to 2024-12-01.
--
-- `risk_change_from_previous` is left as VARCHAR here on purpose. The first
-- assessment of each source risk profile has no previous value, producing 700
-- NULLs after seeding. Converting or defaulting it is a business decision, so it
-- happens in the intermediate layer rather than staging.
-- ---------------------------------------------------------------------------

{{ config(materialized='view') }}

with source as (

    select * from {{ ref('risk_assess_monthly_assessments') }}

),

renamed as (

    select

        -- ---- keys ---------------------------------------------------------
        cast(assessment_id as number(38, 0)) as assessment_id,

        -- The workshop seed contains 36 ordered monthly assessments per risk
        -- profile but omits the relationship key. Recover it from that stable
        -- sequence so downstream joins do not multiply multi-product pairs.
        cast(ceil(cast(assessment_id as number(38, 0)) / 36) as number(38, 0)) as risk_profile_id,

        cast(customer_id as varchar) as customer_id,
        cast(institution_id as varchar) as institution_id,

        -- ---- time -----------------------------------------------------------
        -- Source Postgres column is `text` holding ISO YYYY-MM-DD.
        cast(date as date) as assessment_date,
        cast(month as number(38, 0)) as assessment_month,
        cast(year as number(38, 0)) as assessment_year,

        -- ---- risk facts --------------------------------------------------------
        cast(current_risk_score as number(9, 4)) as current_risk_score,
        cast(risk_level as varchar) as risk_level,
        cast(fraud_probability as number(9, 4)) as fraud_probability,

        -- Left as text. Converted in int_fs_monthly_risk_enriched.
        cast(risk_change_from_previous as varchar) as risk_change_from_previous_raw,

        -- ---- anomaly detection -----------------------------------------------------
        case
            when upper(cast(is_anomaly as varchar)) = 'TRUE' then true
            else false
        end as is_anomaly,

        cast(anomaly_type as varchar) as anomaly_type,

        -- ---- transaction activity -----------------------------------------------------
        cast(monthly_transaction_volume as number(18, 2)) as monthly_transaction_volume,
        cast(transaction_count as number(38, 0)) as transaction_count,

        -- ---- decisioning ------------------------------------------------------------
        cast(approval_recommendation as varchar) as approval_recommendation,
        cast(approval_confidence as number(9, 4)) as approval_confidence,
        cast(primary_explanation_factors as varchar) as primary_explanation_factors

    from source

)

select * from renamed
