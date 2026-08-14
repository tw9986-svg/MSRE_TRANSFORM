# Phase log

A record of what each development phase decided, measured, and left open.

Git holds *what changed*. This file holds *why*, and — more importantly — what is still
unresolved. Contradictions found and deferred are the entries most worth keeping, because they
do not appear in any diff.

One section per phase, in order, newest at the bottom — this is meant to be read forwards. Do
not rewrite closed sections; if a later phase overturns an earlier finding, add a new entry
that says so and strike the old one through.

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
| Total flow area | 0.4469 m² (Mao Table 2: 0.4315 m², −3.4 %) — *superseded in Phase 2, see decision 9* |
| Channel velocity | 0.182 m/s (Engel & Haubenreich quote 0.19 m/s) |
| Channel Reynolds number | **825 — laminar** (855 after Phase 2) |
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

---

## Phase 2 — Fuel salt density traced to ORNL-TM-4865

**Branch:** `phase2/properties-compere`
**Status:** density replaced. Volumes deliberately not re-derived — see O-6, which is now the
main open item in the library.

### Decisions taken

| # | Decision | Rationale |
|---|---|---|
| 6 | Fuel salt density becomes `2575 − 0.513·T[°C]` (Compere et al., ORNL-TM-4865, 1975) | The previous `2575.3 − 0.5641·T[K]` could not be traced to a source and runs ~9 % low. The new one is independently corroborated: it is Mao et al. Eq. (10), and it is the correlation behind the TRANSFORM medium Fischer et al. (2024) used. |
| 7 | Only the density is traced; cₚ, μ, k are carried over unchanged | Deliberate ordering, not an unfinished job. The density is the property the benchmark is sensitive to — it converts volumes into transit times, and Eq. 8 depends on nothing else. cₚ does not enter the zero-power tests at all; μ and k act only through friction and heat transfer, neither of which matters at 100 W. Trace them before reporting any full-power result. |
| 8 | Geometry left as it is, so the library no longer reproduces the reported transit times | Option B as agreed. The inconsistency is left visible and computable (`Geometry.err_m_core`, `err_m_loop`) rather than absorbed by re-fitting volumes around the new density. |

### The finding, and why it contradicts what option B was chosen to show

Option B was adopted on the expectation that the τ_C deviation would be evidence that **MARS
did not use the Compere density**. The numbers say the opposite, and the reasoning that gets
there does not use any volume this library calibrated.

A transit time times a mass flow rate is a **mass**, with no density in it. The reported
τ_C = 9.56 s at 168 kg/s therefore states that the MARS core holds **1606 kg** of fuel salt,
whatever correlation produced it. The MARS core is its fuel channels plus two small plenum
nodes, and the channel volume is documented hardware. Their ratio is an independent estimate of
the density MARS used:

| Core volume used | Implied density | vs Compere 2249 | vs old correlation 2063 |
|---|---|---|---|
| 1140 channels × 1.626 m (this library) | 2210 kg/m³ | −1.7 % | +7.1 % |
| 0.4315 m² × 1.6406 m (Mao Table 2) | 2269 kg/m³ | **+0.9 %** | +10.0 % |

Both land within ~2 % of Compere and 7–10 % from the correlation the library used before.
**MARS almost certainly did use a Compere-like density; what was wrong was this library's
correlation.** Nothing here is circular — no calibrated volume enters.

Confirming it from the other direction: adopting Mao's published core flow area together with
the Compere density gives τ_C = 9.64 s against the reported 9.56 s, **with nothing fitted.**

### Numbers established

| Quantity | Old (2063 kg/m³) | New (2249 kg/m³) |
|---|---|---|
| ρ at 908 K | 2063.1 | 2249.3 (+9.03 %) |
| ρ at 922 K | 2055.2 | 2242.1 |
| β (thermal expansion) | 2.7448e−4 | 2.2880e−4 |
| τ_C / τ_L / τ_sys at 168 kg/s | 9.56 / 16.14 / 25.70 s | 10.42 / 17.60 / 28.02 s |
| Drift reactivity (Eq. 8) | 228.4 pcm | 218.8 pcm |
| Pump: P_hyd / τ_hyd / J | 24.4 kW / 251 N·m / 8.28 kg·m² | 22.4 kW / 231 N·m / 7.59 kg·m² |

Measured drift reactivity is 227.3 pcm, so with the volumes unchanged the agreement moves from
+0.5 % to −3.7 %. `tau_pump_shaft` is unchanged, so the pump speed histories are identical.

### Open items

**O-6 — The volumes are now inconsistent with the reported transit times. This is the live item.**

Both inventories are 9.0 % high (`Geometry.err_m_core`, `err_m_loop`). Two checks now fail
knowingly and have been downgraded to warnings with the reason stated in the message:
`Steady_LoopBalance` check 2 (τ_sys 28.02 s vs 25.63 s) and `Analytic_DriftReactivity`'s natural
circulation check (0.74 / 5.67 pcm vs 0.9 / 6.7 pcm). They must not be re-tightened by editing
tolerances.

Resolution differs by side. The **core** is close to resolvable from published data: adopting
Mao's core flow area (0.4315 m², 1.6406 m) gives τ_C = 9.64 s unfitted. The **loop** is not —
`V_downcomer` was always the item that absorbed the balance of the inventory, so it has no
independent value and would simply be re-derived from `m_fuel_loop_paper`.

**O-5 is unchanged** — TRANSFORM's built-in medium may already be Compere-based, which would
make `Media.FuelSalt` redundant. Still needs the TRANSFORM library open to check.

---

## Phase 2b — Core volume re-derived from published channel hardware

**Branch:** `phase2/properties-compere` (continues the section above)
**Status:** implemented. Not yet compiled or simulated.

### Decision

| # | Decision | Rationale |
|---|---|---|
| 9 | Core geometry taken from Mao et al. Table 2: total flow area 0.4315 m², height 1.6406 m | Resolves O-6 on the core side. The library's own 1140 × 3.9198e-4 × 1.626 was not sourced; the Mao figures are published and are the ones that agree with the ORNL-TM-4865 density to within 1 %. |
| 10 | Plena nodalized non-uniformly; the core-boundary node is a thin slice | The node the kinetics counts as core (120-03, 190-01) is 0.86 % of the core volume, not a third of the plenum. `SaltPipe` gained `Vs_nodes`, holding the bore uniform and letting node lengths differ. |
| 11 | `V_downcomer` re-derived from `m_fuel_loop_paper` (0.5869 → 0.4324 m³) | It has always been the item that absorbs the balance of the loop inventory and has no published value to check against. Recorded as arithmetic, not agreement. |

### The result, and what it is worth

| | value | fitted? |
|---|---|---|
| τ_C | **9.5600 s** (reported 9.56) | **no** |
| τ_L | 16.1400 s (reported 16.14) | yes — `V_downcomer` |
| τ_sys | 25.70 s (reported 25.63, measured 25.2) | — |
| Drift reactivity, Eq. 8 | **228.35 pcm** (reported 228.4, measured 227.3) | — |
| β_eff circulating | 0.00450 | — |
| Natural circulation (U-233) | 0.87 / 6.53 pcm (paper 0.9 / 6.7) | — |

**τ_C is a prediction.** Its inputs are a published flow area, a published height and a
published density correlation, none of them adjusted. Since Eq. 8 depends on the transit times
and nothing else, this is the one place the model reproduces the benchmark from independent
data. τ_L is not and must not be presented as if it were.

Both checks downgraded to warnings in Phase 2 now pass again and have been restored to error
level: `Steady_LoopBalance` check 2 (25.70 s vs 25.63) and the natural circulation check in
`Analytic_DriftReactivity` (0.87 / 6.53 vs 0.9 / 6.7).

### Consequential changes

`A_graphite_perChannel` is now derived rather than tabulated: stack area (π/4 × 1.26²) minus
the channel area, shared over 1140 channels, giving 7.153e-4 m² against the previous 7.018e-4.
`r_graphite_inner` 0.014036 → 0.013553 m, `r_graphite_outer` 0.020503 → 0.020282 m,
`V_graphite` 1.3009 → 1.3377 m³. Channel Reynolds number 825 → 855, still laminar.

### Open items

**O-6 is closed on the core side, still open on the loop side.** `V_downcomer` remains
un-checkable. Any statement about loop transit time agreement is circular.

**O-7 — The plenum core-node length does not reconcile with the paper. (new)**

The core node comes out at 3.055 L, which at the assumed plenum bore is an axial length of
12 mm. The paper's core-boundary sensitivity study states Volume 190-01 as 63.5 mm — five times
longer. The transit times depend on volume, not length, so nothing above is affected, but the
plenum bore assumed here is not the one MARS used. Resolving it needs the MARS node dimensions,
which are not published. Note that `corePowerShape` uses the node *length*, so the axial power
shape near the core boundary carries this discrepancy.

**O-8 — `Dh_channel` was not re-derived. (new)**

It stays at 0.01778 m (0.7 in) while the flow area dropped 3.4 %, so the implied wetted
perimeter moved from 0.0882 to 0.0852 m. Both are documented hardware in different sources and
they are no longer mutually consistent. Affects the heat transfer area, not the transit times.
