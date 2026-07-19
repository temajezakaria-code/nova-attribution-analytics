"""
Nova Home Goods — Marketing Attribution & Media Mix Modeling Data Generator
==================================================================
Business scenario: Nova Home Goods, a DTC home goods brand, spends across 8
marketing channels but only evaluates performance with last-click
attribution — a method known to systematically over-credit "closing"
channels (Paid Search, Direct, Email) and under-credit upper-funnel
"opening" channels (Display, Video, Paid Social) that appear earlier in the
customer journey. Real multi-touch customer journey and media-spend data is
never published by companies — this generator builds journeys with a
PROGRAMMED true per-touch channel effectiveness (ground truth), so this
project can verify whether multi-touch attribution models actually recover
the truth better than last-click, rather than just asserting it.
"""
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
import random

random.seed(42)
np.random.seed(42)

OUT_DIR = "/home/claude/nova-attribution/data"
START_DATE = datetime(2024, 1, 1)
END_DATE = datetime(2025, 12, 31)
N_DAYS = (END_DATE - START_DATE).days + 1
N_WEEKS = N_DAYS // 7

CHANNELS = ["Display", "Video", "Paid Social", "Organic Search", "Affiliate", "Email", "Paid Search", "Direct"]

# ---------------------------------------------------------------------------
# GROUND TRUTH: true per-touch incremental effectiveness (unknown to any
# attribution model -- this is what a GOOD model should recover).
# Deliberately: Direct has LOW true value despite being a frequent closer
# (people who type the URL directly were often already going to convert
# anyway -- classic "attribution laundering" case). Display/Video/Paid
# Social have real value but rarely close, so last-click will undervalue them.
# ---------------------------------------------------------------------------
TRUE_WEIGHT = {
    "Display": 0.045, "Video": 0.050, "Paid Social": 0.055, "Organic Search": 0.040,
    "Affiliate": 0.035, "Email": 0.060, "Paid Search": 0.070, "Direct": 0.030,
}

# Journey-position tendency: which channels tend to open, sit in the middle, or close
OPENER_POOL = ["Display", "Video", "Paid Social", "Organic Search"]
MIDDLE_POOL = ["Affiliate", "Paid Social", "Email", "Organic Search", "Video"]
CLOSER_POOL = ["Paid Search", "Direct", "Email"]

BASELINE_CONVERSION = 0.02
AVG_ORDER_VALUE = 92.0

# ---------------------------------------------------------------------------
# FACT: CUSTOMER JOURNEYS (touchpoint-level)
# ---------------------------------------------------------------------------
print("Generating customer journeys...")
touchpoint_rows = []
journey_rows = []
touchpoint_id = 1
journey_id = 1

N_JOURNEYS = 20000
for _ in range(N_JOURNEYS):
    n_touches = np.random.choice([1,2,3,4,5,6], p=[0.18,0.25,0.22,0.16,0.11,0.08])
    journey_start = START_DATE + timedelta(days=random.randint(0, N_DAYS-14))

    sequence = []
    if n_touches == 1:
        sequence = [random.choice(CHANNELS)]
    else:
        sequence.append(random.choice(OPENER_POOL))
        for _ in range(n_touches - 2):
            sequence.append(random.choice(MIDDLE_POOL))
        sequence.append(random.choice(CLOSER_POOL))

    # True conversion probability = baseline + sum of true weights of touches in this journey
    true_prob = BASELINE_CONVERSION + sum(TRUE_WEIGHT[c] for c in sequence)
    true_prob = np.clip(true_prob, 0, 0.95)
    converted = np.random.random() < true_prob
    revenue = round(np.random.gamma(2.2, AVG_ORDER_VALUE/2.2), 2) if converted else 0.0

    journey_rows.append({
        "journey_id": journey_id, "journey_start_date": journey_start.date().isoformat(),
        "num_touchpoints": n_touches, "converted": int(converted), "revenue": revenue,
    })

    touch_date = journey_start
    for order, channel in enumerate(sequence, start=1):
        touch_date = touch_date + timedelta(days=random.randint(0,3)) if order > 1 else touch_date
        touchpoint_rows.append({
            "touchpoint_id": touchpoint_id, "journey_id": journey_id, "channel": channel,
            "touchpoint_order": order, "is_last_touch": int(order == n_touches),
            "is_first_touch": int(order == 1), "touchpoint_date": touch_date.date().isoformat(),
        })
        touchpoint_id += 1
    journey_id += 1

journeys = pd.DataFrame(journey_rows)
touchpoints = pd.DataFrame(touchpoint_rows)
print(f"  Journeys: {len(journeys):,} | Touchpoints: {len(touchpoints):,}")
print(f"  Overall conversion rate: {journeys['converted'].mean()*100:.2f}%")

# ---------------------------------------------------------------------------
# FACT: WEEKLY MEDIA SPEND & OUTCOMES (for Media Mix Modeling)
# Diminishing-returns (saturating) response curve per channel:
#   incremental_revenue = alpha * (1 - exp(-beta * spend))
# ---------------------------------------------------------------------------
print("Generating weekly media spend and outcomes...")
mmm_params = {
    "Display":        {"base_spend": 8000,  "alpha": 3200,  "beta": 0.00025},
    "Video":          {"base_spend": 10000, "alpha": 4800,  "beta": 0.00022},
    "Paid Social":    {"base_spend": 14000, "alpha": 7800,  "beta": 0.00028},
    "Organic Search": {"base_spend": 0,     "alpha": 0,     "beta": 0},       # unpaid, no spend
    "Affiliate":       {"base_spend": 6000,  "alpha": 2600,  "beta": 0.00030},
    "Email":           {"base_spend": 1500,  "alpha": 3400,  "beta": 0.00060},
    "Paid Search":     {"base_spend": 16000, "alpha": 9200,  "beta": 0.00022},
    "Direct":          {"base_spend": 0,     "alpha": 0,     "beta": 0},       # unpaid
}

weekly_rows = []
for w in range(N_WEEKS):
    week_start = START_DATE + timedelta(weeks=w)
    month = week_start.month
    seasonal = 1.6 if month in (11,12) else (0.85 if month == 1 else 1.0)
    promo_week = 1 if random.random() < 0.08 else 0

    total_revenue = 15000  # baseline organic/brand revenue floor
    for channel, p in mmm_params.items():
        if p["alpha"] == 0:
            spend = 0
            channel_revenue = np.random.normal(6000 if channel=="Direct" else 9000, 800) * seasonal
        else:
            spend = max(0, np.random.normal(p["base_spend"] * seasonal * (1.25 if promo_week else 1), p["base_spend"]*0.15))
            channel_revenue = p["alpha"] * (1 - np.exp(-p["beta"] * spend)) * seasonal
        total_revenue += channel_revenue
        weekly_rows.append({
            "week_start_date": week_start.date().isoformat(), "channel": channel,
            "spend": round(spend, 2), "attributed_revenue_mmm": round(channel_revenue, 2),
            "promo_week": promo_week, "month": month,
        })

weekly_media = pd.DataFrame(weekly_rows)
print(f"  Weekly media rows: {len(weekly_media):,} ({N_WEEKS} weeks x {len(mmm_params)} channels)")

# ---------------------------------------------------------------------------
# SAVE
# ---------------------------------------------------------------------------
journeys.to_csv(f"{OUT_DIR}/fact_journeys.csv", index=False)
touchpoints.to_csv(f"{OUT_DIR}/fact_touchpoints.csv", index=False)
weekly_media.to_csv(f"{OUT_DIR}/fact_weekly_media.csv", index=False)

total = len(journeys) + len(touchpoints) + len(weekly_media)
print(f"\nTOTAL ROWS ACROSS ALL TABLES: {total:,}")
