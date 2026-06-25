---
name: trace
description: Evidence-driven causal tracing with competing hypotheses, ranked evidence, and discriminating probes
argument-hint: "<observation to trace>"
---

# Trace Skill

Use this skill for ambiguous, causal, evidence-heavy questions where the goal is to explain **why** an observed result happened, not to jump directly into fixing or rewriting code.

Use the `tracer` agent as the lane worker when available. If the `tracer` agent is unavailable, each lane should be run as a focused subagent (or as a sequential investigation pass) — the lane structure, evidence contract, and rebuttal round still apply. The goal is to make tracing a reusable operating lane: restate the observation, generate competing explanations, gather evidence in parallel, rank the explanations, and propose the next probe that would collapse uncertainty fastest.

## Good entry cases

Use `/trace` when:

- **Two or more genuinely different explanations could account for the observation AND you cannot yet determine which is correct from available evidence** — this is the core entry gate
- The problem is causal: you need to explain *why* an observed result happened, not just fix it
- The failure is ambiguous enough that a single-lane diagnosis would miss real alternatives
- The analysis benefits from parallel evidence-gathering across competing hypotheses

Examples:
- runtime bugs and regressions
- performance / latency / resource behavior
- architecture / premortem / postmortem analysis
- scientific or experimental result tracing
- config / routing / orchestration behavior explanation
- "given this output, trace back the likely causes"

## When Not to Use

- The root cause is already known and the task is to implement the fix — use `executor`
- The goal is to confirm a change works, not explain why something happened — use `verify`
- A single most-likely cause exists and competing hypotheses add no value — use `debug`
- The user explicitly wants code written or changed, not a causal explanation
- The failure is a straightforward error message with a single obvious cause (e.g. a missing import, a typo in a config key)

## Examples

**Good:** "Auth works in dev but silently fails in prod — trace why"
→ Competing explanations: config mismatch vs. env-specific auth service vs. measurement error in the prod log query. Spawn 3 lanes.

**Good:** "Our benchmark shows 40% slower throughput after the cache refactor — trace the regression"
→ Ambiguous: could be the refactor, a measurement artifact, or a concurrent env change. 3 lanes.

**Bad:** "/trace fix the null pointer on line 40"
→ Cause is known. Use `executor` to fix it.

**Bad:** "/trace confirm the refactor didn't break anything"
→ That is verification. Use `verify`.

**Bad:** "/trace why is there a syntax error in auth.ts line 12"
→ Single obvious cause. Use `debug`.

## Core tracing contract

Always preserve these distinctions:

1. **Observation** -- what was actually observed
2. **Hypotheses** -- competing explanations
3. **Evidence For** -- what supports each explanation
4. **Evidence Against / Gaps** -- what contradicts it or is still missing
5. **Current Best Explanation** -- the leading explanation right now
6. **Critical Unknown** -- the missing fact keeping the top explanations apart
7. **Discriminating Probe** -- the highest-value next step to collapse uncertainty

Do **not** collapse into:
- a generic fix-it coding loop
- a generic debugger summary
- a raw dump of worker output
- fake certainty when evidence is incomplete

## Evidence strength hierarchy

Treat evidence as ranked, not flat.

From strongest to weakest:

1. **Controlled reproductions / direct experiments / uniquely discriminating artifacts**
2. **Primary source artifacts with tight provenance** (trace events, logs, metrics, benchmark outputs, configs, git history, file:line behavior)
3. **Multiple independent sources converging on the same explanation**
4. **Single-source code-path or behavioral inference**
5. **Weak circumstantial clues** (timing, naming, stack order, resemblance to prior bugs)
6. **Intuition / analogy / speculation**

Explicitly down-rank hypotheses that depend mostly on lower tiers when stronger contradictory evidence exists.

## Strong falsification / disconfirmation rules

Every serious `/trace` run must try to falsify its own favorite explanation.

For each top hypothesis:

- collect evidence **for** it
- collect evidence **against** it
- state what distinctive prediction it makes
- state what observation would be hard to reconcile with it
- identify the cheapest probe that would discriminate it from the next-best alternative

Down-rank a hypothesis when:

- direct evidence contradicts it
- it survives only by adding new unverified assumptions
- it makes no distinctive prediction compared with rivals
- a stronger alternative explains the same facts with fewer assumptions
- its support is mostly circumstantial while the rival has stronger evidence tiers

## Orchestration shape

The lead should:

1. Restate the observed result or "why" question precisely
2. Extract the tracing target
3. Generate multiple deliberately different candidate hypotheses
4. Spawn **3 tracer lanes by default** using subagents. Fewer lanes are appropriate when: the problem space genuinely has only 1–2 distinguishable explanations. In that case, spawn only as many lanes as there are distinct hypotheses and state the reason for the reduced count. Do not manufacture artificial lanes to reach 3.
5. Assign one tracer worker per lane
6. Instruct each tracer worker to gather evidence **for** and **against** its lane
7. Run a **rebuttal round** between the leading hypothesis and the strongest remaining alternative
8. Detect whether the top lanes genuinely differ or actually converge on the same root cause
9. Merge findings into a ranked synthesis with an explicit critical unknown and discriminating probe

Important: workers should pursue deliberately different explanations, not the same explanation in parallel.

## Default hypothesis lanes

Unless the prompt strongly suggests a better partition, use these 3 default lanes:

1. **Code-path / implementation cause**
2. **Config / environment / orchestration cause**
3. **Measurement / artifact / assumption mismatch cause** — covers verification-method defects, not just system defects. Examples: the verification query reuses a single key across distinct entities; the comparison filter shape does not match the schema grain; the column name was assumed portable across runtimes without enumeration.

For lane 3, cross-entity discrepancies need a premise audit before escalation: enumerate entity dimensions and check whether a zero-row or mismatch result came from applying one key across multiple entities rather than from a system defect.

## Mandatory cross-check lenses

After the initial evidence pass, pressure-test the leaders with these lenses when relevant:

- **Systems lens** -- queues, retries, backpressure, feedback loops, upstream/downstream dependencies, boundary failures, coordination effects
- **Premortem lens** -- assume the current best explanation is incomplete or wrong; what failure mode would embarrass the trace later?
- **Science lens** -- controls, confounders, measurement bias, alternative variables, falsifiable predictions

These lenses are not filler. Use them when they can surface a missed explanation, hidden dependency, or weak inference.

## Worker contract

Each worker should own exactly one hypothesis lane and must:

- restate its lane hypothesis explicitly
- gather evidence **for** the lane
- gather evidence **against** the lane
- rank the evidence strength behind its case
- call out missing evidence, failed predictions, and remaining uncertainty
- name the **critical unknown** for the lane
- recommend the best lane-specific **discriminating probe**
- avoid collapsing into implementation unless explicitly told to do so

Recommended worker return structure:

1. **Lane**
2. **Hypothesis**
3. **Evidence For**
4. **Evidence Against / Gaps**
5. **Evidence Strength**
6. **Critical Unknown**
7. **Best Discriminating Probe**
8. **Confidence**

## Leader synthesis contract

The final `/trace` answer should synthesize, not just concatenate.

Return:

1. **Observed Result**
2. **Ranked Hypotheses**
3. **Evidence Summary by Hypothesis**
4. **Evidence Against / Missing Evidence**
5. **Rebuttal Round**
6. **Convergence / Separation Notes**
7. **Most Likely Explanation**
8. **Critical Unknown**
9. **Recommended Discriminating Probe**
10. **Additional Trace Lanes** (optional, only if uncertainty remains high)

Preserve a ranked shortlist even if one explanation is currently dominant.

## Rebuttal round and convergence detection

Before closing the trace:

- let the strongest non-leading lane present its best rebuttal to the current leader
- force the leader to answer the rebuttal with evidence, not assertion
- if the rebuttal materially weakens the leader, re-rank the table
- if two "different" hypotheses reduce to the same underlying mechanism, merge them and say so explicitly
- if two hypotheses still imply different next probes, keep them separate even if they sound similar

Do not claim convergence just because multiple workers use similar language. Convergence requires either:

- the same root causal mechanism, or
- independent evidence streams pointing to the same explanation

## Explicit down-ranking guidance

The lead should explicitly say why a hypothesis moved down:

- contradicted by stronger evidence
- lacks the observation it predicted
- requires extra ad hoc assumptions
- explains fewer facts than the leader
- lost the rebuttal round
- converged into a stronger parent explanation

## Output quality bar

Good `/trace` output is:

- evidence-backed
- concise but rigorous
- skeptical of premature certainty
- explicit about missing evidence
- practical about the next action
- explicit about why weaker explanations were down-ranked

## Example final synthesis shape

### Observed Result
[What happened]

### Ranked Hypotheses
| Rank | Hypothesis | Confidence | Evidence Strength | Why it leads |
|------|------------|------------|-------------------|--------------|
| 1 | ... | High / Medium / Low | Strong / Moderate / Weak | ... |

### Evidence Summary by Hypothesis
- Hypothesis 1: ...
- Hypothesis 2: ...
- Hypothesis 3: ...

### Evidence Against / Missing Evidence
- Hypothesis 1: ...
- Hypothesis 2: ...
- Hypothesis 3: ...

### Rebuttal Round
- Best rebuttal to leader: ...
- Why leader held / failed: ...

### Convergence / Separation Notes
- ...

### Most Likely Explanation
[Current best explanation]

### Critical Unknown
[Single missing fact keeping uncertainty open]

### Recommended Discriminating Probe
[Single next probe]

### Additional Trace Lanes
[Only if uncertainty remains high]
