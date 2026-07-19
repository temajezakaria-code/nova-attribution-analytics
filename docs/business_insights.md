# Nova Home Goods — Marketing Attribution: Findings & Recommendations

All figures below derive directly from the SQL analysis and Python notebooks in this
repository (20,000 customer journeys, 59,849 touchpoints, 832 weekly media
observations, 2024-2025). This project employs a synthetic dataset with a programmed
ground truth for per-touch channel effectiveness; where a finding depends on this
ground truth, that dependency is stated explicitly rather than presented as an
observed fact about real consumer behavior.

---

## 15 Findings

1. **Last-click attribution exhibits the weakest correspondence with true channel
   value** of the four models evaluated (Spearman rank correlation = 0.476), a
   marked deficit relative to Linear (0.619), Shapley Value (0.619), and Markov
   Chain (0.595) attribution.
2. **Direct is materially overvalued under last-click attribution**: it receives
   28.1% of attributed revenue under this method despite ranking last (7.8% true
   share) among the eight channels examined — the largest single discrepancy in the
   dataset.
3. **Paid Social is the most severely undervalued channel under last-click
   attribution**, receiving only 0.9% of credit versus a 14.3% true share — a 1,721%
   undervaluation relative to Linear attribution.
4. **Four additional channels — Organic Search, Video, Affiliate, and Display — are
   each undervalued by last-click attribution by more than 680%** relative to their
   Linear-attributed share, indicating the distortion is systemic rather than
   confined to a single channel.
5. **Shapley Value attribution satisfies its theoretical efficiency property
   exactly**: the sum of all channel credits equals total converted revenue
   ($306,126) to the cent, providing independent mathematical verification of the
   implementation's correctness.
6. **Shapley Value and simple Linear attribution achieve statistically
   indistinguishable rank correlation with ground truth (0.619 each)** in this
   dataset — a finding reported without embellishment, as it does not favor the more
   computationally sophisticated method on this particular accuracy criterion.
7. **The five most common converting multi-channel paths all involve an
   upper-funnel channel (Paid Social, Video, or Display) followed by a closing
   channel (Paid Search or Email)** — a sequencing pattern invisible to any
   single-touch attribution model by construction.
8. **Email is the only evaluated paid channel operating above revenue breakeven**
   ($1.40 revenue per dollar of spend); all five other paid channels return less
   than one dollar of attributed revenue per dollar spent.
9. **Paid Search, the largest line item in the media budget ($1.77M over the
   analysis period), returns only $0.57 per dollar spent** — a result consistent
   with the channel's estimated response curve indicating substantial market
   saturation at current spend levels.
10. **The estimated response curves indicate diminishing marginal returns across
    every paid channel**, with several channels' spend levels positioned well
    beyond the point of efficient marginal return.
11. **Journey length is distributed across one to six touchpoints**, with the modal
    journey comprising two touchpoints (25% of journeys) — evidence against a
    single-touchpoint model of customer decision-making.
12. **Four channels — Display, Organic Search, Paid Social, and Video — account for
    the substantial majority of first touchpoints**, consistent with their intended
    role as upper-funnel awareness drivers.
13. **Three channels — Paid Search, Direct, and Email — account for the substantial
    majority of final touchpoints**, consistent with their intended role as
    conversion-closing channels.
14. **The Markov chain's baseline absorption probability (0.16565) matches the
    dataset's observed conversion rate (0.16565) to five decimal places**, confirming
    the chain construction faithfully represents the underlying transition data.
15. **No attribution model examined — including the two more sophisticated
    methods — perfectly recovers the true channel ranking**; Shapley Value and
    Linear attribution each correctly rank only a subset of channels in their exact
    true order, indicating a ceiling on achievable accuracy from observational
    attribution data alone.

---

## 10 Risks

1. **Continued reliance on last-click attribution risks systematic misallocation of
   media budget away from upper-funnel channels that are demonstrably undervalued**
   by this method.
2. **The apparent effectiveness of Direct traffic under last-click attribution risks
   being mistaken for a channel worth direct investment**, when Direct traffic is,
   by construction, largely a downstream artifact of prior exposure to other
   channels.
3. **Sustained spend on Paid Search at current levels, given its estimated position
   on the response curve, risks continued sub-breakeven marginal returns** without a
   change in budget allocation.
4. **The tie in accuracy between Shapley Value and Linear attribution risks being
   over-interpreted as evidence that simpler methods are always sufficient** — this
   result reflects this dataset's particular structure and should not be
   generalized without re-validation on other data.
5. **Any single attribution model, however sophisticated, risks being treated as
   ground truth in practice**, when in fact this analysis demonstrates that even the
   best-performing models achieve only partial correspondence with true channel
   value.
6. **Reallocating budget toward upper-funnel channels without monitoring response
   curves risks pushing those channels into the same saturation regime currently
   observed for Paid Search.**
7. **The independence of the touchpoint-level and weekly-aggregate datasets (see
   Limitations) risks confusion if the two are conflated when communicating results
   to stakeholders.**
8. **Path analysis findings, while suggestive of channel sequencing effects, risk
   being interpreted as causal evidence of a required sequence** absent a controlled
   experiment.
9. **Attribution modeling of this kind risks being treated as a one-time exercise**
   rather than an ongoing measurement practice, allowing budget allocation to drift
   back toward last-click intuitions over time.
10. **The synthetic nature of this dataset risks understating the true complexity of
    real customer journey data**, which typically includes measurement gaps,
    cross-device identity resolution challenges, and longer time horizons than
    modeled here.

---

## 15 Recommendations

1. **Discontinue last-click attribution as the primary basis for media budget
   allocation decisions**, given its demonstrated weakest correspondence with true
   channel value among the methods evaluated.
2. **Adopt Shapley Value or Linear attribution as the primary allocation
   framework**, given their superior (and statistically tied) performance against
   ground truth in this analysis.
3. **Reduce Paid Search spend toward the point of efficient marginal return**
   indicated by its estimated response curve, reallocating the difference toward
   underinvested upper-funnel channels.
4. **Increase investment in Paid Social specifically**, given both its substantial
   undervaluation under the current attribution method and its comparatively
   favorable position on its estimated response curve.
5. **Treat Direct traffic as a downstream indicator of upper-funnel effectiveness
   rather than an independently investable channel.**
6. **Formalize the two most common converting paths (Paid Social → Paid Search;
   Paid Social → Email) into coordinated cross-channel campaign planning**, rather
   than managing each channel's budget independently.
7. **Increase Email investment**, given it is the only channel currently operating
   above revenue breakeven and shows no evidence of approaching saturation at
   current spend levels.
8. **Establish a recurring (e.g., quarterly) re-estimation of this attribution
   analysis**, rather than treating the current findings as static.
9. **Validate the path-sequencing findings with a controlled experiment** (e.g., a
   holdout test withholding Paid Search exposure from a subset of Paid-Social-
   exposed users) before treating sequencing effects as causal.
10. **Present both Shapley Value and Linear attribution results to stakeholders
    jointly**, rather than a single model in isolation, given their comparable
    performance and distinct theoretical properties.
11. **Commission a unified data architecture** that links touchpoint-level and
    weekly-aggregate marketing data, addressing the independence limitation
    identified in this analysis.
12. **Monitor newly-favored channels' response curves after reallocation**, to
    detect early signs of approaching saturation before overinvestment recurs.
13. **Incorporate the removal-effect framework from the Markov chain analysis into
    ongoing channel-level reporting**, as a complement to (not replacement for)
    Shapley Value attribution.
14. **Communicate the "no model perfectly recovers ground truth" finding
    explicitly to leadership**, to calibrate expectations appropriately rather than
    presenting any single model's output as definitive.
15. **Treat Recommendations 1 through 4 as the priority sequence**, given they
    follow most directly from the analysis's strongest and most consistent
    findings.

---

## 10 Near-Term Actions

1. Communicate the last-click distortion finding, and specifically the Direct and
   Paid Social results, in the next media planning review.
2. Begin tracking Linear and Shapley Value attribution alongside (not instead of)
   existing last-click reporting, to build stakeholder familiarity before a full
   transition.
3. Flag Paid Search's sub-breakeven return on the current dashboard as a standing
   item for budget review.
4. Identify the specific creative or landing-page assets associated with the
   Paid Social → Paid Search and Paid Social → Email paths for cross-team
   coordination.
5. Share the response-curve visualization for Paid Search directly with whoever
   holds budget authority for that channel.
6. Add channel-level Spearman correlation tracking as a standing model-validation
   metric wherever ground truth or proxy validation is available.
7. Circulate the Shapley Value efficiency-property verification as a simple proof
   point of methodological rigor in any internal presentation of this work.
8. Increase Email budget incrementally and monitor the response curve for early
   signs of approaching saturation.
9. Document the two independent datasets (touchpoint-level and weekly-aggregate)
   clearly in any internal data catalog to prevent future conflation.
10. Schedule the first quarterly re-estimation of this analysis on the calendar
    now, rather than treating it as an open-ended future task.

---

## 10 Longer-Term Opportunities

1. Develop a unified customer data platform linking individual touchpoint records
   to weekly aggregate spend and revenue, resolving the current architectural
   separation between the two data sources used in this analysis.
2. Design and execute a holdout-based incrementality experiment to validate the
   Markov chain removal-effect estimates against a true experimental
   counterfactual.
3. Extend the Shapley Value framework to incorporate touchpoint recency and
   frequency as additional game-theoretic dimensions, beyond simple channel
   membership.
4. Build a formal marketing mix optimization model that uses the estimated
   response curves to recommend an optimal budget allocation directly, rather than
   requiring manual interpretation of the curves.
5. Investigate cross-device and cross-session identity resolution to extend
   journey tracking beyond what this single-session-equivalent dataset models.
6. Develop channel-specific creative testing informed by the path-sequencing
   findings (e.g., testing Paid Search ad copy specifically for users previously
   exposed to Paid Social).
7. Build automated model monitoring that flags when attribution model rankings
   diverge meaningfully from the prior period, prompting investigation.
8. Extend this analysis's validation methodology (rank correlation against known
   ground truth) into a standard practice for evaluating any future attribution
   methodology change.
9. Explore Bayesian media mix modeling approaches to formally quantify uncertainty
   in the response-curve estimates presented here.
10. Revisit this entire analysis in twelve months to assess whether reallocation
    toward upper-funnel channels achieved the anticipated efficiency gains.

---

## Limitations and Methodological Notes

An analysis of this kind should state its limitations explicitly rather than
allow methodological rigor in some areas to imply certainty in all areas.

**Limitations of this analysis:**
- **This dataset is entirely synthetic**, constructed with a programmed true
  per-touch channel effectiveness specifically so that attribution models could be
  validated against a known quantity. Real, multi-touch, user-level customer
  journey data of this kind is not published by companies; this is disclosed as a
  necessary methodological choice, not concealed.
- **The touchpoint-level journey dataset and the weekly-aggregate media dataset
  were generated independently** and are not designed to reconcile numerically
  (total converted revenue from journeys, $306,126, and total MMM-attributed
  revenue from weekly channel spend, $3.18M, represent two distinct analytical
  lenses — individual-journey attribution and aggregate channel-level response
  curves — rather than two measurements of the same underlying quantity). This
  should be stated explicitly whenever both figures are presented together, to
  avoid the appearance of an unreconciled discrepancy.
- **No model in this analysis achieves perfect correspondence with ground truth.**
  The finding that Shapley Value and Linear attribution tie in rank correlation
  should not be generalized to other datasets without independent validation — the
  relative performance of attribution methods is known in the literature to depend
  on the specific structure of the underlying customer journey data.
- **The path-sequencing findings are descriptive, not causal.** Observing that
  certain channel sequences co-occur frequently in converting journeys does not
  establish that the sequence itself caused conversion; a controlled experiment
  would be required to support a causal claim.

**Planned extensions:**
- Validate the Markov chain removal-effect and Shapley Value estimates against a
  true experimental holdout, rather than relying solely on the programmed-ground-
  truth validation used in this version.
- Unify the two independently-generated datasets into a single coherent data
  architecture, enabling touchpoint-level and spend-level analysis to be conducted
  jointly rather than separately.
- Extend the response-curve estimation to a formal budget optimization
  recommendation, rather than requiring manual interpretation of the curves
  presented here.
