# Crowdsourced Spam-Call Tagging Layer — Requirements

## 1. Problem Statement

STIR/SHAKEN authenticates *where* a call entered the network, not *who's calling or why*. Spammers exploit this gap by rotating through thousands of originating numbers, so number-based blocklists are always a step behind. A crowdsourced tagging layer adds a signal STIR/SHAKEN structurally cannot provide: real-time, distributed human judgment about call intent, aggregated across the very number-rotation behavior that defeats static blocklists.

Core idea: if N or more distinct users independently tag a number as spam within a short window, the system escalates that number's risk score before it reaches the next batch of recipients — closing the gap between "spammer picks up a new number" and "carrier flags it."

## 2. Goals / Non-Goals

**Goals**
- Let any user flag an incoming or recent call as spam/scam/robocall with one tap.
- Aggregate tags across users in near-real-time to build a trust score per number.
- Auto-escalate (label, silence, or block) once a configurable threshold (default: 10 unique taggers) is crossed.
- Resist gaming by both spammers (mass self-clearing) and bad actors (mass false-flagging a legitimate number).
- Feed the aggregate signal back into carrier-level STIR/SHAKEN attestation and reputation systems, not just an app-siloed blocklist.

**Non-Goals (v1)**
- Not replacing STIR/SHAKEN — this is a complementary signal layered on top.
- Not doing real-time call-audio analysis or voice biometrics (separate workstream).
- Not a general call-recording product — tagging must work from metadata alone, no consent/wiretap issues.

## 3. Phased Rollout Strategy

**Phase 1 — App-level (v1 target):** Ship entirely within the app's own tagging/scoring loop. No carrier dependency, no shared reputation API. Goal is to prove out tagging participation rates, threshold accuracy, and abuse-resistance at real scale before asking any carrier to integrate.

**Phase 2 — Carrier approach (post-traction):** Once app-level usage and accuracy metrics are strong enough to be a credible pitch (tagging volume, false-positive rate, demonstrated reduction in repeat exposure), take the scored dataset to carriers as a reputation feed they can subscribe to or integrate into their existing STIR/SHAKEN + analytics stack. Traction numbers *are* the pitch — carriers won't integrate a speculative feed, but they will integrate a proven one.

This means cross-carrier sharing and the shared governance model (see FR-14 and §8 Open Questions) are explicitly deferred to Phase 2 and should not block Phase 1 architecture — but Phase 1 should still be built so the scoring/reputation data is exportable later without a rearchitecture (i.e., don't hard-code assumptions that only make sense in a single-app silo).

## 4. Functional Requirements

### 4.1 Tagging mechanism
- FR-1: User can tag a number as spam from the native call log, an in-call banner, or a missed-call notification, within one tap.
- FR-2: Tag categories: Spam/Telemarketing, Scam/Fraud, Robocall, Not Spam (unflag/correction).
- FR-3: Tag is timestamped, geo-region-tagged (coarse, e.g. area code / region — not precise location), and tied to a pseudonymous, non-reversible user ID.
- FR-4: A user can only submit one active tag per number per rolling 24-hour window (prevents single-account flooding).

### 4.2 Aggregation & thresholding
- FR-5: System maintains a rolling count of unique taggers per number over a configurable window (default: 7 days).
- FR-6: Default escalation threshold = 10 unique taggers, but must be configurable per deployment/carrier and adjustable by call-volume-normalized rate (10 tags on a number with 12 calls total is a much stronger signal than 10 tags on a number with 50,000 calls).
- FR-7: Support graduated response tiers, not just binary block:
  - Tier 1 (low confidence, e.g. 3–9 tags): "Suspected Spam" label shown, call still rings normally.
  - Tier 2 (threshold met, e.g. 10+ tags): Call routed to silent/spam folder, notification suppressed.
  - Tier 3 (high confidence + corroborating signal, e.g. 50+ tags or matched to known SIM-farm pattern): Number blocked network-side, reported to carrier reputation feed.
- FR-8: Decay function — tag weight ages out over time so a number that goes dormant and gets resold/reassigned isn't permanently poisoned.

### 4.3 Anti-abuse / integrity
- FR-9: Sybil resistance — tagging weight must scale with account trust (device age, SIM/account tenure, prior tagging accuracy) rather than raw tag count, to prevent spammers spinning up fake users to clear their own numbers or competitors mass-flagging legitimate businesses.
- FR-10: Rate-limit and anomaly-detect tagging bursts from a single device cluster, IP range, or newly created account cohort.
- FR-11: Appeal/dispute path for legitimate callers (businesses, pharmacies, schools, new customers wrongly caught by a stale score) — **v1 governance approach:** the flagged party (or their carrier, on their behalf) submits an unblock request/attestation letter; a lightweight human/semi-automated review clears the number and resets its score. This keeps Phase 1 governance simple and app-owned rather than requiring a shared cross-party dispute framework up front. Broader governance (who arbitrates disputes when multiple carriers/vendors share the reputation feed, who owns false-positive liability) is explicitly a Phase 2 problem — see §3 and §8.
- FR-12: Tagger accuracy tracking — users whose tags are frequently overturned on appeal have their vote weight reduced over time (reputation-weighted voting, not one-user-one-vote).

### 4.4 Data & signal fusion
- FR-13: Crowdsourced score must combine with existing signals: STIR/SHAKEN attestation level, carrier reputation data, call-pattern anomalies (rapid cycling, SIM-box indicators), and known DNO (Do-Not-Originate) lists.
- FR-14: *(Phase 2)* Cross-carrier sharing — the network-wide value of this system grows once app-level traction is proven; requires either (a) a shared reputation API carriers subscribe to, or (b) participation in an existing consortium framework (e.g. extending TNS/Analytics Engine-style reputation feeds). Not required for Phase 1 launch.
- FR-15: Number-reassignment awareness — telecom numbers get recycled; score must reset or heavily decay when a number is confirmed reassigned (via carrier porting/reassignment data) to avoid punishing an innocent new owner.

### 4.5 Browsable spam directory
This turns the aggregate tagging data into a user-facing feature, not just a background block signal.
- FR-19: Users can browse/search flagged numbers, filterable and sortable by: **company/caller name** (self-reported by taggers or matched via reverse lookup), **number**, **carrier/origin network**, **content/category** (loan scam, IRS/government impersonation, extended-warranty, robocall-telemarketing, etc.), **timing** (time of day, day of week, campaign burst window), and **volume** (tag count / reports-per-day).
- FR-20: "Content" here is category-based, not audio-based — tags are drawn from a fixed taxonomy users select at tag time (see FR-2), not transcription or recording. This keeps FR-19/20 consistent with the no-recording constraint and avoids wiretap/consent exposure. If richer content signal is wanted later, the path is: expand the taxonomy and/or let users optionally submit a free-text note, not audio capture.
- FR-21: Support additional data points as they become available and useful: number-reassignment/porting status, associated business registration (if a caller self-identifies or is matched against a business directory), cross-reference to known DNO lists, and campaign clustering (numbers likely belonging to the same underlying operator based on timing/category/volume similarity — pattern-based, not content-based).
- FR-22: Directory should support both a personal view ("numbers relevant to my area/history") and a global view, to keep the experience useful even for users who haven't personally received a given spam call.

### 4.6 User experience
- FR-16: Post-call prompt should be optional/dismissible, not a forced interstitial — friction kills participation rate.
- FR-17: Transparency: user should be able to see why a number was flagged (tag count, category breakdown) if they tap into call details.
- FR-18: Aggregate stats (e.g. "reported by 1,240 users this week") build trust in the system and encourage participation — consider surfacing this.

## 5. Non-Functional Requirements

- NFR-1: **Latency** — tag ingestion to score update should be near-real-time (target: <60s) so the threshold effect actually helps the *next* wave of recipients, not just historical reporting.
- NFR-2: **Scale** — must handle burst campaigns (e.g. one number generating millions of calls in hours, per the loan-scam example rotating 50,000+ numbers in a month) without the aggregation pipeline falling behind.
- NFR-3: **Privacy** — tagging must not require recording or transcribing call content; metadata-only (number, timestamp, category) avoids wiretap/consent law issues (state two-party consent laws, etc.).
- NFR-4: **Data minimization** — user IDs used for tagging should be pseudonymous and not exportable/linkable to identity outside abuse-investigation contexts.
- NFR-5: **Auditability** — every escalation decision (why a number got blocked) must be reconstructable for regulatory/dispute purposes — ties directly into FCC's existing Robocall Mitigation Database transparency expectations.
- NFR-6: **Regulatory alignment** — design should anticipate FCC/TCPA scrutiny; blocking legitimate calls (schools, pharmacies, banks) carries legal risk carriers are already sensitive to.

## 6. Privacy Non-Negotiables

To ensure legal compliance across all global jurisdictions (including GDPR, CCPA, NDPR, and DPDPA) and maintain absolute user trust, the platform must enforce these strict, non-negotiable architectural boundaries:

*   **No Contact List Upload or Access (Ever):** The app must never request, read, or upload the user's native contact list. The global directory must be built solely on first-party behavior-based tagging (calls actually received by users), never by harvesting contact lists without consent (avoiding the core driver of GDPR/NDPR liability faced by platforms like Truecaller).
*   **Explicit, Opt-In Data Toggles Only:** There must be no pre-checked, auto-enabled, or hidden data-sharing toggles. Any telemetry or reputation sharing must be disabled by default, requiring explicit, per-feature, opt-in consent from the user.
*   **No Arbitrary Reverse-Lookup/Scraping:** Users cannot query the directory for arbitrary numbers or people who have never interacted with them. Lookup searches are restricted to actual inbound caller identification and verification of numbers from active or recent calls to prevent weaponization and doxxing.
*   **No Call Recording or Voice Transcription:** No call audio is ever recorded, processed, or transcribed. Tagging relies purely on metadata (caller number, timestamp, category).
*   **No Data Brokering or Monetization:** The underlying crowdsourced reports and device identifiers must never be sold, leased, or commercialized to third parties.
*   **No SMS or Message Scanning:** The app must never scan or read SMS, message contents, or other application notifications to build financial or behavioral user profiles.

## 7. System Architecture (high level)

1. **Client SDK / app layer** — captures tag events, enforces one-tag-per-user-per-number-per-window locally before submission.
2. **Ingestion pipeline** — streaming ingestion (e.g. Kafka/Kinesis-style) to handle burst volume; writes to a fast key-value store keyed by number.
3. **Scoring service** — computes weighted, decayed, volume-normalized trust score per number in near-real-time; combines crowdsourced signal with STIR/SHAKEN attestation and carrier reputation data.
4. **Reputation API** — exposes score + tier to carriers, call-blocking apps, and (optionally) a shared industry feed.
5. **Abuse-detection layer** — anomaly detection on tagging patterns themselves (this is a second fraud-detection problem layered on top of the first — tag-farm detection mirrors SIM-farm detection).
6. **Appeals/dispute service** — human or semi-automated review queue for flagged legitimate callers, with SLA.

## 8. Success Metrics

- Time from "spammer activates new number" to "number crosses Tier 1 threshold" (target: minutes, not days).
- False-positive rate on legitimate business numbers (must stay very low — this is the metric regulators and carriers will scrutinize most).
- Participation rate (% of users who tag when prompted).
- Reduction in repeat exposure — same underlying spam campaign (tracked via pattern clustering across rotated numbers) reaching fewer total recipients before full-tier escalation.

## 9. Open Questions

**Resolved for v1:**
- ~~Carrier vs. app-level first~~ → App-level first (Phase 1), carrier approach after traction (Phase 2) — see §3.
- ~~Recording/content analysis~~ → No recording. "Content" signal comes from user-selected category taxonomy only (FR-20).
- ~~Governance model~~ → Deferred. Interim v1 mechanism is a carrier/business unblock-request letter to clear false positives (FR-11); full multi-party governance model to be designed once Phase 2 (carrier integration) is actually on the table.

**Still open:**
- Pattern-based campaign clustering — do we cluster rotated numbers from the same underlying operator via timing/category/volume similarity (FR-21) in v1, or defer that to a later release once the core tagging loop is proven?
- Taxonomy ownership — who defines and updates the category list (FR-2, FR-20) as new scam types emerge (e.g. AI voice-clone scams), and how often?
- What specific data points, beyond the ones listed in FR-19/21, would be most valuable to expose in the directory once real usage data starts coming in? Worth revisiting after Phase 1 data exists rather than speculating now.
