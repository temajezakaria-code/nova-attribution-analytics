-- =============================================================================
-- Nova Home Goods — Marketing Attribution SQL Analysis
-- 10 queries covering multiple attribution models, path analysis, and media
-- spend efficiency. Tested and verified against nova_attribution.db (SQLite).
-- =============================================================================

-- =============================================================================
-- QUERY 1: LAST-CLICK ATTRIBUTION (THE NAIVE, DEFAULT MODEL)
-- Techniques: JOIN, aggregate, filtering
-- =============================================================================
-- WHY: Establishes the baseline every marketing team already has — whatever
-- the current default reporting shows — as the explicit starting point to
-- compare more rigorous models against.
-- BUSINESS VALUE: Without a documented baseline, it's impossible to show
-- stakeholders how much their current budget allocation might be misinformed.
-- =============================================================================
SELECT
    t.channel,
    COUNT(*) AS conversions_credited,
    ROUND(SUM(j.revenue), 2) AS revenue_credited
FROM fact_touchpoints t
JOIN fact_journeys j ON j.journey_id = t.journey_id
WHERE t.is_last_touch = 1 AND j.converted = 1
GROUP BY t.channel
ORDER BY revenue_credited DESC;


-- =============================================================================
-- QUERY 2: FIRST-TOUCH ATTRIBUTION (THE OPPOSITE NAIVE MODEL)
-- Techniques: JOIN, aggregate, filtering
-- =============================================================================
-- WHY: Shows the other naive extreme — crediting only the first touch — to
-- make clear that neither single-touch model is defensible on its own: the
-- truth should sit somewhere in between, informed by an actual multi-touch
-- model.
-- BUSINESS VALUE: A large gap between first-touch and last-click credit for
-- the same channel is itself evidence that single-touch attribution is
-- unreliable for that channel specifically.
-- =============================================================================
SELECT
    t.channel,
    COUNT(*) AS conversions_credited,
    ROUND(SUM(j.revenue), 2) AS revenue_credited
FROM fact_touchpoints t
JOIN fact_journeys j ON j.journey_id = t.journey_id
WHERE t.is_first_touch = 1 AND j.converted = 1
GROUP BY t.channel
ORDER BY revenue_credited DESC;


-- =============================================================================
-- QUERY 3: LINEAR (EQUAL-CREDIT) ATTRIBUTION
-- Techniques: CTE, JOIN, aggregate, weighted distribution
-- =============================================================================
-- WHY: Splits each converted journey's revenue equally across every
-- touchpoint in that journey — a simple multi-touch model that at least
-- acknowledges every channel that participated, unlike the single-touch
-- models above.
-- BUSINESS VALUE: A useful middle-ground sanity check before investing in a
-- more complex model — if linear attribution already tells a very different
-- story than last-click, that's a strong signal current reporting is
-- materially misleading budget decisions.
-- =============================================================================
WITH journey_credit AS (
    SELECT t.channel, t.journey_id, j.revenue / j.num_touchpoints AS credited_revenue
    FROM fact_touchpoints t
    JOIN fact_journeys j ON j.journey_id = t.journey_id
    WHERE j.converted = 1
)
SELECT channel, ROUND(SUM(credited_revenue), 2) AS revenue_credited
FROM journey_credit
GROUP BY channel
ORDER BY revenue_credited DESC;


-- =============================================================================
-- QUERY 4: TIME-DECAY ATTRIBUTION
-- Techniques: CTE, window function, weighted distribution, CASE
-- =============================================================================
-- WHY: Weights credit toward touchpoints closer to conversion (exponential
-- decay by position), a more nuanced middle ground than linear attribution
-- that still doesn't require a full behavioral model.
-- BUSINESS VALUE: If time-decay and linear attribution roughly agree with
-- each other but both disagree sharply with last-click, that's strong
-- triangulating evidence the last-click default is the outlier, not the
-- more sophisticated models.
-- =============================================================================
WITH weighted AS (
    SELECT
        t.channel, t.journey_id, j.revenue,
        POWER(2, t.touchpoint_order - j.num_touchpoints) AS decay_weight   -- most recent touch = weight 1, each step back halves
    FROM fact_touchpoints t
    JOIN fact_journeys j ON j.journey_id = t.journey_id
    WHERE j.converted = 1
),
totals AS (
    SELECT journey_id, SUM(decay_weight) AS total_weight FROM weighted GROUP BY journey_id
)
SELECT
    w.channel,
    ROUND(SUM(w.revenue * w.decay_weight / t.total_weight), 2) AS revenue_credited
FROM weighted w JOIN totals t ON t.journey_id = w.journey_id
GROUP BY w.channel
ORDER BY revenue_credited DESC;


-- =============================================================================
-- QUERY 5: MOST COMMON CONVERTING PATHS (PATH ANALYSIS)
-- Techniques: CTE, string aggregation, ranking
-- =============================================================================
-- WHY: Shows the actual multi-channel sequences customers follow before
-- converting — a level of detail no single-touch attribution model can
-- reveal at all.
-- BUSINESS VALUE: Informs channel sequencing/retargeting strategy (e.g.,
-- "Display then Paid Search" being a common path suggests retargeting
-- Display-exposed users with Paid Search is a validated, not just assumed,
-- strategy).
-- =============================================================================
WITH paths AS (
    SELECT journey_id, GROUP_CONCAT(channel, ' -> ') AS path
    FROM (SELECT * FROM fact_touchpoints ORDER BY journey_id, touchpoint_order) t
    GROUP BY journey_id
)
SELECT p.path, COUNT(*) AS journey_count, ROUND(SUM(j.revenue),0) AS total_revenue
FROM paths p JOIN fact_journeys j ON j.journey_id = p.journey_id
WHERE j.converted = 1
GROUP BY p.path
ORDER BY journey_count DESC
LIMIT 10;


-- =============================================================================
-- QUERY 6: TOUCHPOINT COUNT: CONVERTED VS. NON-CONVERTED JOURNEYS
-- Techniques: aggregate, CASE, comparison
-- =============================================================================
-- WHY: Tests whether more channel exposure actually correlates with
-- converting, or whether journey length is unrelated to outcome.
-- BUSINESS VALUE: If converted journeys show meaningfully more touchpoints,
-- that supports continued multi-channel investment: if not, it may suggest
-- diminishing or redundant exposure past a certain point.
-- =============================================================================
SELECT
    converted,
    COUNT(*) AS journey_count,
    ROUND(AVG(num_touchpoints), 2) AS avg_touchpoints
FROM fact_journeys
GROUP BY converted;


-- =============================================================================
-- QUERY 7: MEDIA SPEND EFFICIENCY BY CHANNEL (REVENUE PER DOLLAR SPENT)
-- Techniques: aggregate, ranking, business-formula calculation
-- =============================================================================
-- WHY: Combines weekly spend and revenue data to compute a simple ROI-style
-- efficiency metric per paid channel.
-- BUSINESS VALUE: A direct, budget-relevant metric — "for every dollar spent
-- on this channel, how much revenue resulted" — that's easier for a CFO to
-- act on than a raw attribution percentage.
-- =============================================================================
SELECT
    channel,
    ROUND(SUM(spend), 0) AS total_spend,
    ROUND(SUM(attributed_revenue_mmm), 0) AS total_attributed_revenue,
    ROUND(SUM(attributed_revenue_mmm) / SUM(spend), 2) AS revenue_per_dollar_spent
FROM fact_weekly_media
WHERE spend > 0
GROUP BY channel
ORDER BY revenue_per_dollar_spent DESC;


-- =============================================================================
-- QUERY 8: MONTHLY SPEND TREND WITH ROLLING AVERAGE
-- Techniques: CTE, window function, time series analysis
-- =============================================================================
-- WHY: Smooths weekly spend volatility to show the real underlying budget
-- trend across the 2-year window, including the seasonal Nov-Dec increase.
-- BUSINESS VALUE: Confirms budget pacing matches the intended seasonal
-- strategy rather than drifting unintentionally.
-- =============================================================================
WITH monthly AS (
    SELECT strftime('%Y-%m', week_start_date) AS year_month, SUM(spend) AS total_spend
    FROM fact_weekly_media
    GROUP BY year_month
)
SELECT
    year_month, total_spend,
    ROUND(AVG(total_spend) OVER (ORDER BY year_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0) AS rolling_3mo_avg
FROM monthly
ORDER BY year_month;


-- =============================================================================
-- QUERY 9: CHANNEL CO-OCCURRENCE IN CONVERTING JOURNEYS
-- Techniques: self-join, aggregate, ranking
-- =============================================================================
-- WHY: Identifies which pairs of channels most often appear together in the
-- same converting journey — a "market basket"-style analysis applied to
-- marketing touchpoints instead of retail products.
-- BUSINESS VALUE: Informs cross-channel campaign coordination (e.g., if
-- Display + Paid Search co-occur constantly, media planning should
-- coordinate timing between those two teams, not run them independently).
-- =============================================================================
SELECT
    t1.channel AS channel_a, t2.channel AS channel_b, COUNT(DISTINCT t1.journey_id) AS co_occurring_journeys
FROM fact_touchpoints t1
JOIN fact_touchpoints t2 ON t1.journey_id = t2.journey_id AND t1.channel < t2.channel
JOIN fact_journeys j ON j.journey_id = t1.journey_id
WHERE j.converted = 1
GROUP BY channel_a, channel_b
ORDER BY co_occurring_journeys DESC
LIMIT 10;


-- =============================================================================
-- QUERY 10: ATTRIBUTION MODEL COMPARISON SUMMARY (LAST-CLICK VS. LINEAR)
-- Techniques: CTE, JOIN, CASE, business interpretation
-- =============================================================================
-- WHY: Puts last-click and linear attribution side by side for every
-- channel in one table, with the percentage-point difference calculated
-- directly, making the distortion immediately visible without needing to
-- cross-reference two separate query outputs.
-- BUSINESS VALUE: This is the single table most useful for a stakeholder
-- meeting — one view showing exactly how much the current (last-click)
-- reporting over- or under-states each channel's contribution.
-- =============================================================================
WITH last_click AS (
    SELECT t.channel, SUM(j.revenue) AS lc_revenue
    FROM fact_touchpoints t JOIN fact_journeys j ON j.journey_id = t.journey_id
    WHERE t.is_last_touch = 1 AND j.converted = 1
    GROUP BY t.channel
),
linear AS (
    SELECT t.channel, SUM(j.revenue / j.num_touchpoints) AS lin_revenue
    FROM fact_touchpoints t JOIN fact_journeys j ON j.journey_id = t.journey_id
    WHERE j.converted = 1
    GROUP BY t.channel
)
SELECT
    l.channel,
    ROUND(lc.lc_revenue, 0) AS last_click_revenue,
    ROUND(l.lin_revenue, 0) AS linear_revenue,
    ROUND((l.lin_revenue - lc.lc_revenue) / lc.lc_revenue * 100, 1) AS pct_difference,
    CASE WHEN l.lin_revenue > lc.lc_revenue * 1.2 THEN 'UNDERVALUED by last-click'
         WHEN l.lin_revenue < lc.lc_revenue * 0.8 THEN 'OVERVALUED by last-click'
         ELSE 'Roughly consistent' END AS assessment
FROM linear l JOIN last_click lc ON lc.channel = l.channel
ORDER BY pct_difference DESC;
