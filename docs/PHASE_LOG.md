# Phase log

A record of what each development phase decided, measured, and left open.

Git holds *what changed*. This file holds *why*, and — more importantly — what is still
unresolved. Contradictions found and deferred are the entries most worth keeping, because they
do not appear in any diff.

Append at the top. One section per phase. Do not rewrite closed sections; if a later phase
overturns an earlier finding, add a new entry that says so.

---

## Phase 1 — Pump rotor dynamics and per-ring flow resistance

**Branches:** `claude/msre-benchmarking-architecture-i35tb0` (PR #5, merged),
`phase1/pump-init-fix` (PR #7, follow-up). `phase1/pump-consolidation` (PR #6) was an
abandoned attempt — see decision 5.
**Status:** implemented, compiles in Dymola. Simulation results not yet recorded.

### Decisions taken

| # | Decision | Rationale |
|---|---|---|
| 1 | Ring flow resistances get a degree of freedom but keep the value 0 | The values would have to come from Kedl, ORNL-TM-3229, which has not been obtained. Fischer et al. (2024) tuned the equivalent coefficients on their three radial groups against that same data. |
| 2 | Fuel properties stay on the existing correlation for now; ORNL-TM-4865 (Compere, 1975) deferred to Phase 2 | Changing the density at the same time as adding the rotor would mix two effects and make the regression unreadable. See the open item below — this is not a free deferral. |
| 3 | Pump rotor parameterized by one constant, `tau_shaft` | With τ_hyd ∝ ω² the rotor equation has closed-form solutions and startup and coastdown follow from the same number. Matches the paper's "typical generic pump parameters". |
| 4 | ~~One pump model with a `use_rotorDynamics` switch, not two model classes~~ | **Reversed.** See entry 5. |
| 5 | The two pump models stay separate classes: `FuelPump` (imposed speed), `FuelPump_Dynamics` (rotor solved), sharing `BaseClasses.PartialFuelPump` | Decision 4 folded both into one class with a Boolean, on the reasoning that keeping a previous state is git's job. That reasoning was about *history*, and it was applied to something that is not only history: which pump drives a given run is a modelling choice a reader has to be able to see. A Boolean buried in a parameter dialog hides it — the rotor disappeared from the package browser and stopped being visible as a thing the model does. Two named classes state the choice where it can be read. The consolidated form was never merged; it is on the abandoned branch `phase1/pump-consolidation` (PR #6), commit `6d19c7d`, if it is ever wanted. Do not delete that branch while this reference stands. |

### Numbers established

Pump rotor — only `tau_shaft` is fitted; the rest follows from the rated duty of 3.0 bar at
168 kg/s:

| Quantity | Value | Fixed by |
|---|---|---|
| Rated hydraulic power | 24.4 kW (32.8 hp) | `dp_nominal · V_flow_nominal` |
| `tau_hyd_nominal` | 251 N·m | that power ÷ (ω_n · η) |
| `tau_shaft` | 4.0 s | **fitted** |
| `J` | 8.28 kg·m² | follows from the two above |

At `tau_shaft` = 4.0 s the startup reaches 98.7 % of rated flow in 10 s; the previously fitted
exponential (3.4 s) reached 94.7 %. The paper's halved-inertia sensitivity case is
`tau_shaft` = 2.0.

Core channel hydraulics at rated flow:

| Quantity | Value |
|---|---|
| Total flow area | 0.4469 m² (Mao Table 2: 0.4315 m², −3.4 %) |
| Channel velocity | 0.182 m/s (Engel & Haubenreich quote 0.19 m/s) |
| Channel Reynolds number | **825 — laminar** |
| Core friction Δp | 243 Pa = 0.081 % of the loop Δp |

Two consequences follow from the Reynolds number, and both are load-bearing:

1. Δp ∝ v, not v². Any later tuning must not assume the turbulent square law.
2. The only mechanism that redistributes flow between rings without a fitted coefficient is the
   viscosity, μ = 8.94e-5·exp(4092/T), giving −0.496 %/K. A ring 10 K hotter draws about 5 %
   more flow on its own.

### Open items

**O-1 — The reported transit times constrain a mass, not a volume. (blocking for Phase 2)**

τ·ṁ contains no density, so what the benchmark actually pins down is the circulating inventory:

| | Mass |
|---|---|
| Core | 1606 kg |
| External loop | 2712 kg |
| Total | 4306 kg |

The volumes in `Data.Geometry` are those masses divided by ρ(908 K) = 2063.1 kg/m³ from the
current correlation. Adopting ORNL-TM-4865 (ρ = 2575 − 0.513·T[°C], giving 2249.3 kg/m³ at
908 K, **+9.03 %**) therefore invalidates the volumes rather than perturbing them:

| | current ρ = 2063.1 | Compere ρ = 2249.3 |
|---|---|---|
| V_core required by τ_C = 9.56 s | 0.77848 m³ | 0.71403 m³ |
| Channel volume (hardware-fixed, 1140 × A × H) | 0.72659 m³ | 0.72659 m³ |
| **Left for the two plenum core nodes** | +0.05189 m³ | **−0.01256 m³ — negative** |
| V_loop required by τ_L = 16.14 s | 1.31430 m³ | 1.20548 m³ (−8.3 %) |

**At the Compere density the channel volume alone exceeds the core volume the reported core
transit time allows.** The channel volume is not adjustable — it is 1140 channels of 1.626 m.
Using Mao's core geometry instead (0.4315 m² × 1.6406 m = 0.70792 m³) leaves +0.00611 m³, i.e.
about 3 litres per plenum node, which fits but is implausibly small.

Three ways out, to be decided at the start of Phase 2:

- **(A)** Adopt Compere ρ *and* Mao's core geometry, accept ~3 L plenum nodes as a stated
  assumption. Both τ_C and τ_L then match MARS.
- **(B)** Adopt Compere ρ, hold the geometry at documented ORNL hardware, and report the
  resulting τ_C shortfall as evidence that MARS is not using the Compere correlation. From a
  code-to-code standpoint this may be the more informative result.
- **(C)** *(chosen for Phase 1)* Defer the density change entirely.

**O-2 — Jeong (2026) publishes no property correlations or values.**

Section 3 says the molten-salt property models were implemented in MARS first and refers to
[18] (KNS spring meeting) and [19] (NET 58(1) 2026, 103898). Neither is in hand. Direct
comparison of the Compere correlation against "the values Jeong used" is therefore **not
possible**; the only route is the inverse one in O-1, backing a density out of the transit times
and the inventory. Obtaining [19] converts this to a direct comparison.

**O-3 — Ring resistance cannot be validated at 100 W.**

At the benchmark power the ring-to-ring temperature spread is at most 0.4 µK, so no setting of
`K_channelInlet` / `K_channelExit` produces an observable difference. Any claim about ring-level
flow distribution needs the full-power (8 MW) or natural-circulation case. Do not present the
15-ring resistance model as validated by the zero-power tests.

**O-4 — Verification models have never been run.**

`Steady_LoopBalance` and `Transient_DriftReactivity` compile but have not been simulated. Their
tolerances are stated acceptance criteria, not observed results. `Steady_LoopBalance` check 6
(delivered flow vs. rated) is the most likely to fail first and is deliberately a warning: the
loop form losses have never been exercised against the pump characteristic in a solver.

**O-5 — TRANSFORM may already ship a Compere-based fuel salt.**

Fischer et al. (2024) state that the LiF-BeF₂-ZrF₄-UF₄ properties they used are included in
TRANSFORM "based on data from Compere (1975)". If so, Phase 2 may be able to use the built-in
medium rather than restating correlations. Not verifiable from this repository — needs the
TRANSFORM library open.

### Verification status

| Check | Ran? | Result |
|---|---|---|
| Dymola compilation | yes | passes |
| `Steady_LoopBalance` (7 asserts) | no | — |
| `PumpCoastdown` rotor vs. imposed law | no | — |
| `PumpStartup` rotor vs. imposed law | no | — |
| `Analytic_DriftReactivity` | evaluated outside Modelica | passes with margin |
