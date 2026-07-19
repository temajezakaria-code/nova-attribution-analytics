-- =============================================================================
-- Nova Home Goods — Marketing Attribution & MMM Database Schema
-- =============================================================================
-- Business scenario: Nova Home Goods spends across 8 marketing channels but
-- only evaluates last-click attribution, a method known to distort channel
-- value. This dataset is entirely synthetic, with a PROGRAMMED true per-touch
-- channel effectiveness (unknown to any attribution model) so this project
-- can verify whether more sophisticated attribution models actually recover
-- the truth better than last-click, not just assert that they do.
-- =============================================================================

-- Grain: one row per completed customer journey (converted or not)
CREATE TABLE fact_journeys (
    journey_id         INTEGER PRIMARY KEY,
    journey_start_date DATE NOT NULL,
    num_touchpoints     INTEGER NOT NULL,
    converted            INTEGER NOT NULL,   -- 1/0
    revenue               DECIMAL(10,2) NOT NULL
);

-- Grain: one row per touchpoint within a journey
CREATE TABLE fact_touchpoints (
    touchpoint_id     INTEGER PRIMARY KEY,
    journey_id         INTEGER NOT NULL REFERENCES fact_journeys(journey_id),
    channel             VARCHAR(20) NOT NULL,
    touchpoint_order    INTEGER NOT NULL,     -- 1 = first touch in this journey
    is_first_touch       INTEGER NOT NULL,     -- 1/0
    is_last_touch         INTEGER NOT NULL,     -- 1/0
    touchpoint_date       DATE NOT NULL
);

-- Grain: one row per channel per week (for Media Mix Modeling)
CREATE TABLE fact_weekly_media (
    week_start_date       DATE NOT NULL,
    channel                 VARCHAR(20) NOT NULL,
    spend                     DECIMAL(10,2) NOT NULL,
    attributed_revenue_mmm    DECIMAL(10,2) NOT NULL,  -- ground-truth channel revenue contribution (for model validation)
    promo_week                 INTEGER NOT NULL,
    month                        INTEGER NOT NULL,
    PRIMARY KEY (week_start_date, channel)
);

CREATE INDEX idx_touchpoints_journey ON fact_touchpoints(journey_id);
CREATE INDEX idx_touchpoints_channel ON fact_touchpoints(channel);
CREATE INDEX idx_weekly_channel ON fact_weekly_media(channel);

-- =============================================================================
-- Note: this dataset is entirely synthetic. Real multi-touch customer journey
-- and channel-level media spend data is proprietary and never published by
-- companies — this generator (see data/generate_data.py) builds journeys with
-- a programmed TRUE per-touch channel effectiveness, allowing this project's
-- attribution models to be checked against a known ground truth rather than
-- accepted on faith.
-- =============================================================================
