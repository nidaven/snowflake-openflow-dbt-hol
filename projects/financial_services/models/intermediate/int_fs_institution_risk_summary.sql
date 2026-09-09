-- ---------------------------------------------------------------------------
-- int_fs_institution_risk_summary
--
-- Institution-level credit-risk rollup for portfolio monitoring. This keeps
-- the additive exposure measures separate from the average risk measures and
-- makes the collateral completeness control visible at the same grain.
--
-- Grain: one row per institution_id.
-- ---------------------------------------------------------------------------

{{ config(materialized='view') }}

with relationships as (

    select * from {{ ref('int_fs_risk_relationships') }}

),

aggregated as (

    select

        -- ---- key ------------------------------------------------------------
        institution_id,

        -- ---- exposure -------------------------------------------------------
        sum(total_exposure) as total_exposure,
        sum(risk_weighted_exposure) as total_risk_weighted_exposure,

        -- ---- risk and coverage ----------------------------------------------
        avg(base_risk_score) as average_base_risk_score,
        count(*) as relationship_count,
        avg(case when is_collateral_unassessed then 1.0 else 0.0 end) as unassessed_collateral_rate

    from relationships

    group by institution_id

)

select * from aggregated
