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
`phase1/pump-init-fix` (PR #7, merged). `phase1/pump-consolidation` (PR #6) was an abandoned
attempt that nevertheless reached `main` and had to be reverted — see decision 5 and the
process note below.
**Status:** implemented, compiles in Dymola. Simulation results not yet recorded.

### Decisions taken

| # | Decision | Rationale |
|---|---|---|
| 1 | Ring flow resistances get a degree of freedom but keep the value 0 | The values would have to come from Kedl, ORNL-TM-3229, which has not been obtained. Fischer et al. (2024) tuned the equivalent coefficients on their three radial groups against that same data. |
| 2 | Fuel properties stay on the existing correlation for now; ORNL-TM-4865 (Compere, 1975) deferred to Phase 2 | Changing the density at the same time as adding the rotor would mix two effects and make the regression unreadable. See the open item below — this is not a free deferral. |
| 3 | Pump rotor parameterized by one constant, `tau_shaft` | With τ_hyd ∝ ω² the rotor equation has closed-form solutions and startup and coastdown follow from the same number. Matches the paper's "typical generic pump parameters". |
| 4 | ~~One pump model with a `use_rotorDynamics` switch, not two model classes~~ | **Reversed.** See entry 5. |
| 5 | The two pump models stay separate classes: `FuelPump` (imposed speed), `FuelPump_Dynamics` (rotor solved), sharing `BaseClasses.PartialFuelPump` | Decision 4 folded both into one class with a Boolean, on the reasoning that keeping a previous state is git's job. That reasoning was about *history*, and it was applied to something that is not only history: which pump drives a given run is a modelling choice a reader has to be able to see. A Boolean buried in a parameter dialog hides it — the rotor disappeared from the package browser and stopped being visible as a thing the model does. Two named classes state the choice where it can be read. The consolidated form is on `phase1/pump-consolidation`, commit `6d19c7d`, if it is ever wanted; do not delete that branch while this reference stands. It was merged to `main` as PR #6 after this decision had already reversed it, and backed out again by PR #8 — see the process note at the end of Phase 1. |

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

### Process note — an abandoned branch reached `main`

PR #6 carried the consolidation of decision 4. That decision was reversed before the PR was
acted on, and the reversal was pushed to a different branch, but PR #6 stayed open and was
merged anyway. `main` then held the structure the project had just decided against, and the
next two branches — both cut before the merge — could not be merged into it at all: the pump
files were deleted on one side and modified on the other, and `docs/PHASE_LOG.md` existed on
both with different contents.

Backing it out was clean, because the merge was reverted rather than rebased over:
`git revert -m 1 22c846d` (PR #8) restored `main` byte-for-byte to `bb5bb2e`, after which PR #7
and PR #9 merged without conflict. Merge order matters here and was: revert, then Phase 1, then
Phase 2.

The rule this produces: **a branch whose direction has been abandoned must have its PR closed
at the moment of the decision, not left open with a note.** An open PR is an instruction to
merge, whatever the conversation around it says.

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

**Branch:** `phase2/properties-compere` (PR #9, merged)
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

**Branch:** `phase2/properties-compere` (PR #9, merged — same branch as the section above)
**Status:** implemented and merged. Not yet compiled or simulated.

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

## Toolchain note — MSL 4.1.0 `massFraction` breaks every TRANSFORM medium

**Branch:** `claude/msre-massfraction-errors-erzuuf`
**Status:** implemented. Not yet compiled — the fix has to be confirmed by a Dymola check.

Checking `Verification.Steady_LoopBalance` under Dymola 2026x produced ~120 instances of

> Redeclaration requires a subtype. But missing public function massFraction.

against every `redeclare package Medium` in the loop, plus the same complaint about
`Medium_coolant`, which is a TRANSFORM built-in that this library never touched.

**Cause.** Modelica Standard Library 4.1.0 (2025-05-23) added

```modelica
replaceable partial function massFraction "Return independent mass fractions (if any)"
  input ThermodynamicState state;
  output MassFraction Xi[nXi];
end massFraction;
```

to `Modelica.Media.Interfaces.PartialMedium`. TRANSFORM does not extend that package — it
carries its own copy of the media interfaces
(`TRANSFORM.Media.Interfaces.Fluids.PartialMedium`, which extends only
`Modelica.Media.Interfaces.Types`), so a TRANSFORM medium is a subtype of MSL's `PartialMedium`
only structurally. One added function is enough to break that match, and `PartialMedium` is the
constraining package of every `Medium` in `Modelica.Fluid.Interfaces` and in the TRANSFORM
closure relations. So no TRANSFORM-based medium can be redeclared into any fluid component
under MSL 4.1.0. It is not specific to the fuel salt and not caused by anything in this library.
Comparing the two `PartialMedium` packages class by class, `massFraction` is the only member MSL
has and TRANSFORM lacks.

**Fix.** Declare the function on this library's two media, with the empty body MSL itself uses
in `PartialPureSubstance` (both salts are single substances, so `nXi = 0`):

- `MSRE.Media.FuelSalt` gains `massFraction`, inherited by `FuelSalt_U235` and `FuelSalt_U233`.
- `MSRE.Media.CoolantSalt` changes from an alias of
  `TRANSFORM.Media.Fluids.FLiBe.LinearFLiBe_9999Li7_pT` to a package that extends it and adds
  the same function. Nothing else about the coolant salt changes.

The function is never called by any model here and is inert under MSL 4.0.0, so the fix is
backward compatible. It does not patch TRANSFORM: any *other* TRANSFORM medium redeclared into
a fluid component under MSL 4.1.0 will fail the same way and needs the same three lines.

### Not part of this fix

The same check reported `Class or component 'N_pump_start' not found in PrimarySystem msre`.
`N_pump_start` has been a parameter of `PrimarySystem` since commit d55b826 (PR #7, merged), so
either the working copy under check predates that merge or the message is a knock-on of the
failed medium redeclaration. Re-check after pulling `main`.

---

## Phase 3 — Fuel salt property set replaced with Cantor / ORNL-TM-2316 (INL VTB/SAM basis)

**Scope:** the `MSRE.Media.FuelSalt` medium only. Geometry, pump models, kinetics and transient
test parameters were deliberately not touched.

### Decisions taken

| # | Decision | Rationale |
|---|---|---|
| 10 | All four fuel-salt properties come from S. Cantor, ORNL-TM-2316 (1968), in the form used by the INL MSRE VTB/SAM model | Replaces a mixed set — one traced density (Compere, ORNL-TM-4865) plus three untraced values — with a single self-consistent set from one primary source that a public reference implementation also uses. Closes decision 7 of Phase 2, which deferred cₚ, μ and k. |
| 11 | The density fit is implemented as `2553.3 − 0.562·(T[K] − 273.15)` | The published fit takes **°C**. Implemented against a kelvin argument it gives 2035 kg/m³ at 922 K instead of 2189 — the same class of unit error Phase 2 found in the old `2575.3 − 0.5641·T[K]`. Cross-checked against the INL SAM value 2285.31 kg/m³ at 476.85 °C. |
| 12 | The viscosity fit `8.4e-5·exp(4340/T)` is implemented against **kelvin**, with no conversion | The two fits do not use the same temperature unit; this is stated at every implementation site so it cannot be "tidied up" into consistency. |
| 13 | The superseded values are kept as reference-only functions in `MSRE.Media.MSRE_Properties`, not deleted | `Properties_TransitTime` and `Analytic_DriftReactivity` call `d_Compere` explicitly, and the geometry volumes were derived against it. Active and legacy sets are labelled ACTIVE / REFERENCE ONLY so they cannot be mixed. |
| 14 | Geometry volumes and pump parameters left unchanged, so the reported transit times move by the density ratio | Same policy as Phase 2 option B: the inconsistency stays computable rather than being absorbed by re-fitting volumes around a new density. Mixing a property change with a geometry change makes the regression unreadable. |
| 15 | `T_melt = 722.15 K` recorded as a constant in `MSRE_Properties`, not added to the medium | The TRANSFORM `PartialLinearFluid` interface has no melting-temperature parameter and no model here needs one. Not worth a structural change to the medium interface. |

### Numbers established

| Property | Legacy | Cantor (active) | Δ @ 922 K |
|---|---|---|---|
| ρ | 2575 − 0.513·T[°C] | **2553.3 − 0.562·T[°C]** | 2242.14 → **2188.65** kg/m³ (−2.39 %) |
| μ | 8.94e-5·exp(4092/T) | **8.4e-5·exp(4340/T)** | 7.565e-3 → **9.302e-3** Pa·s (+23.0 %) |
| cₚ | 1967 | **2009.66** J/(kg·K) | +2.17 % |
| k | 1.44 | **1.0** W/(m·K) | −30.6 % |
| T_melt | not represented | **722.15 K** | — |

Over the operating range (core inlet 908 K, average 922 K, outlet 936 K):

| T | ρ [kg/m³] | μ [Pa·s] | cₚ [J/(kg·K)] | k [W/(m·K)] |
|---|---|---|---|---|
| 908 K | 2196.51 | 1.0002e-2 | 2009.66 | 1.0 |
| 922 K | 2188.65 | 9.3019e-3 | 2009.66 | 1.0 |
| 936 K | 2180.78 | 8.6695e-3 | 2009.66 | 1.0 |

All four are strictly positive at all three temperatures.

`beta_const` moved 2.2880e-4 → **2.5678e-4 1/K**. It is not an independent datum: it is
`0.562/2188.65`, the isobaric expansion coefficient of the new density fit at the reference
temperature, and it moves whenever the fit moves.

### Retained assumptions

No new source was established for these, so they keep their existing values —
*retained existing model assumption, not modified in this property update*:

- `FuelSalt.kappa_const = 2.89e-10 1/Pa` (from the TRANSFORM FLiBe model; only sets the stiff
  acoustic time scale, the primary system is essentially incompressible here)
- `FuelSalt.MM_const = 0.0331 kg/mol`
- `FuelSalt.reference_p = 1e5 Pa`, `reference_s = 0`, and the `reference_h` convention
  `cp·(T_ref − 273.15)`
- `Data.Geometry.d_fuel_ref = 2249.3 kg/m³` and `PartialFuelPump.d_nominal = 2242 kg/m³` —
  ORNL-TM-4865 numbers on the geometry/pump side, out of scope for a property-only change

### Consequential changes, and what was left alone

`PrimarySystem.density_ref` is evaluated from the medium, so it — and with it `tau_core`,
`tau_loop`, `tau_system` — falls by 2.39 %. That is the intended visible consequence.
Nothing else was edited: `Data/Geometry.mo`, `PartialFuelPump.mo`, `FuelPump.mo`,
`FuelPump_Dynamics.mo`, the kinetics and the transient test parameters are untouched, and the
two verification models that quote a density call `MSRE_Properties.d_Compere` explicitly rather
than the medium, so their numbers and asserts are unchanged by this commit. They now describe
the *geometry's* reference density rather than the medium's, which is a real divergence and is
recorded as the open item below.

### Open items

- **O-9.** The geometry volumes were derived against the Compere density (Phase 2/2b) and the
  medium now runs on Cantor. `Verification/Properties_TransitTime.mo` and
  `Verification/Analytic_DriftReactivity.mo` still evaluate `d_Compere`. Either the volumes are
  re-derived at the Cantor density or those two models are restated against it — a geometry
  decision, deliberately not taken inside a property-only change.
- **O-10.** The `CoreChannel` documentation quotes the legacy viscosity slope
  (−4092/T² = −0.481 %/K). The Cantor fit gives −4340/T² = −0.511 %/K, so the argument holds in
  substance but the quoted number is now the legacy one.
- **O-11.** The thermal conductivity fell 30 % and the viscosity rose 23 %. Neither reaches the
  zero-power pump tests (100 W), but both act directly on any full-power heat-transfer result.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain (`omc`, Dymola) and no MSL/TRANSFORM installation is
present in this environment, so `checkModel` and the property verification model were not run.
The correlations were verified numerically outside Modelica against the values in the table
above; the edited files were checked for Modelica string/comment balance.

---

## Phase 4 — Core geometry rebuilt from ORNL/INL hardware dimensions

**Scope:** the fuel-channel block of `Data/Geometry.mo` and the matching component defaults.
Plenum, downcomer and external-loop geometry are deliberately left for the next commit.

### Decisions taken

| # | Decision | Rationale |
|---|---|---|
| 16 | The Mao et al. core geometry (`A_core_total = 0.4315 m²`, `H_channels = 1.6406 m`) is retired | It is 32 % larger than the documented channel cross-section of 1140 MSRE channels. It was the quantity that made `tau_core_nominal` land on the reported 9.56 s, so keeping it meant the benchmark was reproduced by an unsourced area. |
| 17 | Core geometry is derived from hardware dimensions, not entered | `w_channel`, `h_channel`, `r_channelCorner`, `H_channels` and `nChannels_total` are the only inputs; `A_channel`, `perimeter_channel`, `Dh_channel`, `A_core_total` and `V_channels` are all `final parameter`. `Dh_channel` in particular was previously a hand-entered 0.7 in that did not follow from any area or perimeter in the record. |
| 18 | Volumes are **not** re-derived from the Cantor density to restore the reported transit times | Doing so makes geometry a function of the property correlation and zeroes `err_m_core`, which is the only indicator that anything disagrees. This is the same option-B policy as Phase 2. |
| 19 | The Mao values are retained as an inert legacy block, labelled *Mao et al. reference geometry — not active* | Provenance change stays a computable comparison (`err_V_channels_Mao`) instead of a remark in a commit message. |
| 20 | `D_graphiteStack` becomes the core container inner diameter, 1.40335 m (55.25 in) | The previous 1.26 m had no stated source. Graphite volume follows from it and the channel area. |
| 21 | INL RZ porous-medium parameters (`core_porosity = 0.2228` and the equivalent-geometry set) are **not** adopted | This baseline is a 1-D channel model, not an RZ multiphysics model. Porosity is an output of the channel geometry here, not an input. |

### Numbers established

| Quantity | Mao (legacy) | ORNL/INL hardware (active) | Δ |
|---|---|---|---|
| `A_channel` | 3.785088e-4 m² | **2.875244e-4 m²** | −24.0 % |
| `perimeter_channel` | 0.085154 m | **0.072559 m** | −14.8 % |
| `Dh_channel` | 0.01778 m (hand-entered) | **0.015851 m** (derived) | −10.9 % |
| `A_core_total` | 0.4315 m² | **0.327778 m²** | −24.0 % |
| `H_channels` | 1.6406 m | **1.6256 m** | −0.9 % |
| `V_channels` | 0.707919 m³ | **0.532836 m³** | −24.7 % |
| `V_graphite` | 1.33774 m³ | **1.98157 m³** | +48.1 % |
| `r_graphite_inner` / `outer` | 0.013553 / 0.020282 m | **0.011548 / 0.021765 m** | — |

Derived at `d_fuel_ref = 2249.3 kg/m³` (unchanged, ORNL-TM-4865 at 908 K):

| | paper | this record | error |
|---|---|---|---|
| core mass | 1606 kg | **1212 kg** | `err_m_core` **−24.5 %** |
| loop mass | 2712 kg | 2712 kg | `err_m_loop` 0.0 % |
| `tau_core_nominal` | 9.56 s | **7.22 s** | −24.5 % |
| `tau_system_nominal` | 25.63 s | **23.36 s** | −8.9 % |

### The finding

**1606 kg of fuel salt does not fit in 1140 channels of documented cross-section.** It would
need 3014 kg/m³, against 2196.5 (Cantor) and 2249.3 (ORNL-TM-4865) — 34 % high. Earlier
revisions of this record read the same comparison in the opposite direction, using an untraced
channel volume of 0.7266 m³ and the Mao area, and concluded the *density* was wrong. With the
channel geometry built from hardware that conclusion no longer follows: the discrepancy points
at **what the MARS core node contains** (plenum, bypass or annulus salt counted as core?)
rather than at any property correlation.

### Consequential assert failures — expected, not fixed

Three asserts now fail, and they fail because they are doing their job. None was relaxed:

| Model | Assert | Value | Limit |
|---|---|---|---|
| `Verification/Steady_LoopBalance.mo:60` | `tau_system_nominal` vs 25.63 s | **23.36 s** | ±0.15 s |
| `Verification/Properties_TransitTime.mo:79` | implied vs Compere density | **+34.0 %** | ±5 % |
| `Verification/Analytic_DriftReactivity.mo:64` | natural-circulation drift | **1.49 / 10.13 pcm** | 0.9 ± 0.2 / 6.7 ± 0.5 pcm |

Forced-circulation drift reactivity (U-235, Eq. 8, Cantor at 908 K) moves from 231.0 pcm to
**277.0 pcm** against the paper's 228.4 pcm — a +48.6 pcm gap, well outside
`Transient_DriftReactivity.tol_rho_pcm = 8`.

### Open items

- **O-12.** Definition of the MARS core node. Blocks any reconciliation of the −24.5 %.
- **O-13.** `d_fuel_ref = 2249.3 kg/m³` is still the ORNL-TM-4865 value while the medium runs on
  Cantor. It cannot simply be switched: `V_flow_pump_nominal`, `P_pump_hydraulic`,
  `tau_pump_hyd_nominal` and `J_pump` are all derived from it, and pump parameters were out of
  scope here. Needs a decision on whether the pump duty follows the medium.
- **O-14.** The three failing asserts need to be restated as reported diagnostics or given
  hardware-based targets. They must not be silently widened.
- **O-15.** `dz_channels = 1.626 m` still differs from `H_channels = 1.6256 m` by 0.4 mm. Left
  alone because the elevation set closes through `dz_downcomer`, which is next-commit scope.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain in this environment. All values above were computed
by hand outside Modelica from the same expressions now in the record; `Data/Geometry.mo` was
checked for Modelica string and comment balance.

---

## Phase 5 — Plenum, downcomer and external-loop geometry

**Scope:** the vessel/downcomer and piping block of `Data/Geometry.mo`. Continues Phase 4 and
closes the deferral noted there. The heat exchanger is **not** included — see below.

### Decisions taken

| # | Decision | Rationale |
|---|---|---|
| 22 | The downcomer becomes the vessel/core-container annulus | `V_downcomer` was never a measurement: it was set to whatever made the loop inventory reproduce the reported loop transit time. Reactor vessel ID 58 in and core container OD 56 in (55.5 in bore + 2 × 0.25 in wall) give a 25.4 mm annular gap, so `A_downcomer` and `Dh_downcomer` now follow from hardware. |
| 23 | `Dh_downcomer = 0.1163 m` is retired | It was not the annulus of any vessel in the record; it travelled with the fitted volume. The hardware value is 0.0508 m. |
| 24 | `D_pipe` 0.1286 → 0.127 m | The 5 in figure the INL MSRE description gives, in place of the 5 in schedule 40 bore. The only piping quantity with a published counterpart. |
| 25 | Unsourced loop quantities keep their values and are labelled as estimates, not replaced by invented ones | Plenum volumes, core-boundary plenum nodes, `V_pumpBowl`, `L_downcomer`, the three pipe lengths and the elevation set have no published counterpart in the ORNL/INL material available. Marked *estimate, no published source* in the record rather than guessed at. |
| 26 | `V_lowerPlenum_core` / `V_upperPlenum_core` are **not** re-derived | Their 3.055 litre value was the remainder of the reported 1606 kg core inventory once the *old* channel volume was removed. That derivation is void after Phase 4, and redoing it would fit geometry to the reported inventory — the practice this whole line of work is removing. Kept as unsourced small nodes. |
| 27 | The heat exchanger is left alone | Its shell-side hydraulic diameter (0.05606 m here vs 0.0209 m in the INL description) feeds `f_shellHT` and `Nu_floor_shell`, which are explicitly calibration parameters and out of scope. Changing the shell geometry without them would silently rescale the full-power duty. Recorded as O-16. |

### Numbers established

| Quantity | fitted / previous | ORNL/INL hardware (active) | Δ |
|---|---|---|---|
| `A_downcomer` | 0.180155 m² (implied) | **0.115529 m²** | −35.9 % |
| `Dh_downcomer` | 0.1163 m | **0.0508 m** | −56.3 % |
| `V_downcomer` | 0.432371 m³ | **0.277270 m³** | −35.9 % |
| `D_pipe` | 0.1286 m | **0.127 m** | −1.2 % (−2.5 % on volume) |
| `V_loop` | 1.205483 m³ | **1.045243 m³** | −13.3 % |
| `V_total` | 1.744429 m³ | **1.584189 m³** | −9.2 % |

At `d_fuel_ref = 2249.3 kg/m³` (unchanged):

| | paper | this record | error |
|---|---|---|---|
| core mass | 1606 kg | 1212 kg | `err_m_core` −24.5 % |
| loop mass | 2712 kg | **2351 kg** | `err_m_loop` **−13.3 %** |
| circulating mass | 4318 kg | **3563 kg** | **−17.5 %** |
| `tau_core_nominal` | 9.56 s | 7.22 s | −24.5 % |
| `tau_loop_nominal` | 16.14 s | **13.99 s** | **−13.3 %** |
| `tau_system_nominal` | 25.63 s | **21.21 s** | −17.2 % |

Forced-circulation drift reactivity (U-235, Eq. 8, Cantor at 908 K): **269.9 pcm** against the
paper's 228.4 pcm, improved from Phase 4's 277.0 pcm because shortening the loop transit time
partly offsets the shortened core transit time. Natural-circulation drift is unchanged at
1.49 / 10.12 pcm.

Hydraulic sanity at rated flow: downcomer 0.65 m/s, Re ≈ 7.4e3; main piping 5.90 m/s,
Re ≈ 1.7e5. Both remain turbulent.

### What the loop error now means

`err_m_loop` used to be exactly 0.0 %, and that was not agreement — it was
`V_downcomer := m_fuel_loop_paper/d_fuel_ref` read back out. It is now −13.3 %, a real
measurement. The missing 0.1603 m³ is 1.39 m of extra downcomer length, or a pump bowl twice
the assumed size, or salt the MARS input counts as loop and this record does not. The available
dimensions cannot distinguish those.

Taken with Phase 4: **the reported circulating inventory is 4318 kg and hardware-based geometry
holds 3563 kg of it, 17.5 % short.** That single number is what any reconciliation now has to
explain, and it is the deliverable of Phases 4–5.

### Open items

- **O-16.** Heat-exchanger shell geometry. INL gives shell diameter 0.41 m and shell-side
  Dh 0.0209 m against 0.05606 m here. Coupled to `f_shellHT` / `Nu_floor_shell`, so it needs to
  move together with the HX calibration, not before it.
- **O-17.** `L_downcomer = 2.40 m`, `V_pumpBowl = 0.150 m³`, the two plenum volumes and the
  three pipe lengths remain unsourced. These are now the entire remaining freedom in the loop
  volume.
- **O-12 / O-13 / O-14 / O-15** from Phase 4 are unchanged and still open. O-14 (three failing
  asserts) is now more pressing: `tau_system_nominal` is 21.21 s against a 25.63 ± 0.15 s
  assert.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain in this environment. All values computed by hand
outside Modelica from the expressions now in the record; `Data/Geometry.mo` checked for
Modelica string and comment balance.

---

## Phase 6 — Geometry provenance cleanup (O-12 + O-17)

**Scope:** provenance classification and documentation only. No active geometry *value* was
changed in this commit; the only new numbers are reference and diagnostic quantities that
nothing depends on.

### O-12 — Jeong core boundary

```
Jeong core boundary confirmed:
120-03 + 300 channel cells + 190-01.
190-01 baseline axial length = 0.0635 m.
Former 0.003055 m3 boundary-node volumes were inventory-derived legacy values
and are no longer accepted as physical provenance.
120-03 physical geometry remains unresolved.
190-01 physical volume remains unresolved unless an independent area source is found.
```

The control-volume **definition** from Jeong et al., *Nuclear Engineering and Technology* 58
(2026) 104438 is confirmed and kept unchanged: `iLP_core = nLP`, `iUP_core = 1`,
`nV_core = nRings*nAxial + 2`, 15 rings × 20 axial nodes, 3 + 3 plenum nodes. No component
architecture was touched.

The boundary-node **volumes** are demoted. `V_lowerPlenum_core` and `V_upperPlenum_core` keep
their 0.003055 m³ — no independently sourced replacement exists and inventing one is exactly
what this work is removing — but they are now tagged **LEGACY / OPEN** in their own description
strings and in the record documentation.

**What the paper's own sensitivity implies.** Lengthening 190-01 by 0.0800 m is reported to
move `tau_core` by +1.11 s and `tau_loop` by −1.11 s. A transit time is a volume over a
volumetric flow, so:

| Diagnostic | Value | Note |
|---|---|---|
| `V_flow_ref` | 0.074690 m³/s | 168 kg/s at `d_fuel_ref` |
| `A_190_01_JeongEq` | **1.0363 m²** | 66 % of the core container bore (1.5608 m²) |
| `V_190_01_JeongEq` | **0.065806 m³** | **21.5×** the legacy 0.003055 m³; **85 %** of the whole assumed upper plenum |
| `V_core_JeongEq` | 0.714035 m³ | from the reported `tau_C`, not used as active |
| `V_120_03_JeongEq` | **0.115393 m³** | **148 %** of the whole assumed lower plenum |

`L_upperPlenum_core` as modelled is **0.0118 m** against the **0.0635 m** the paper states for
190-01 — the clearest single sign that 0.003055 m³ is not the paper's node.

Two readings survive and the data does not choose between them: either the MARS plena are much
larger than the 0.0777 m³ assumed here, or MARS counts as core-boundary nodes a region this
record counts as plenum and downcomer. Both would explain part of the 17.5 % inventory
shortfall. Setting `V_upperPlenum_core := V_190_01_JeongEq` was **not** done: that figure is
derived from a MARS result, not from hardware, and adopting it would reinstate transit-time
fitting. It is reported and left disconnected on purpose.

### O-17 — Loop parameter reclassification

```
Remaining loop-volume uncertainty is no longer absorbed into the downcomer.
Unsourced component dimensions remain explicit assumptions.
No component volume is adjusted to reproduce tau_C, tau_L or total inventory.
```

Six tags, carried in each parameter's own description string so they travel with the value:
**PHYSICAL**, **DERIVED**, **REFERENCE**, **ASSUMPTION**, **LEGACY**, **BENCHMARK-EQUIVALENT**.

| Parameter | Value | Class | Provenance |
|---|---|---|---|
| `V_lowerPlenum_core` (120-03) | 0.003055 m³ | **LEGACY / OPEN** | former paper-inventory balance |
| `V_upperPlenum_core` (190-01) | 0.003055 m³ | **LEGACY / OPEN** | former paper-inventory balance |
| `L_190_01_Jeong` | 0.0635 m | REFERENCE | Jeong 2026 |
| `dL_190_01_Jeong`, `dtau_core_Jeong` | 0.0800 m, 1.11 s | REFERENCE | Jeong 2026 sensitivity |
| `A_190_01_JeongEq`, `V_190_01_JeongEq` | 1.0363 m², 0.065806 m³ | BENCHMARK-EQUIVALENT | not physical |
| `V_core_JeongEq`, `V_120_03_JeongEq` | 0.714035, 0.115393 m³ | BENCHMARK-EQUIVALENT | not physical |
| `V_lowerPlenum`, `V_upperPlenum` | 0.0777 m³ each | ASSUMPTION | no published source |
| `L_lowerPlenum`, `L_upperPlenum` | 0.30 m each | ASSUMPTION | no published source |
| `D_vessel_inner`, `th_vessel`, `D_coreContainer_inner`, `th_coreContainer` | 1.4732, 0.0254, 1.4097, 0.00635 m | PHYSICAL | ORNL/INL hardware |
| `A_downcomer` | 0.115529 m² | DERIVED | vessel/container annulus |
| `Dh_downcomer` | 0.0508 m | DERIVED | vessel/container annulus |
| `V_downcomer` | 0.277270 m³ | DERIVED | hardware area × assumed length |
| `L_downcomer` | 2.40 m | ASSUMPTION | no published source |
| `D_pipe` | 0.127 m | REFERENCE | INL MSRE description, 5 in |
| `L_outletPipe`, `L_pumpToHX`, `L_hxToVessel` | 4.00, 5.00, 7.00 m | ASSUMPTION | none confirmed |
| `V_pumpBowl`, `L_pumpBowl` | 0.150 m³, 0.60 m | ASSUMPTION | no published source |
| `V_hxShell` | 0.266 m³ | ASSUMPTION | frozen with the HX, O-16 |
| `V_downcomer_fitted`, `Dh_downcomer_fitted`, `D_pipe_sch40`, `*_Mao` | — | LEGACY | retired fits, inert |

The core channel set (`nChannels_total`, `H_channels`, `w_channel`, `h_channel`,
`r_channelCorner`, `D_graphiteStack`) is PHYSICAL and everything computed from it
(`A_channel`, `perimeter_channel`, `Dh_channel`, `A_core_total`, `V_channels`) is DERIVED.

`V_core` is tagged **PARTIAL_GEOMETRY_BASELINE**: its channel term is hardware, its two
boundary-node terms are LEGACY/OPEN.

### Inventory and transit times (unchanged by this commit)

| | active | Jeong / MARS | experiment |
|---|---|---|---|
| `V_channels` | 0.532836 m³ | — | — |
| `V_120_03_active` | 0.003055 m³ (LEGACY) | unresolved | — |
| `V_190_01_active` | 0.003055 m³ (LEGACY) | unresolved | — |
| `V_core_active` | 0.538946 m³ | — | — |
| plena (outside core) | 0.074645 m³ × 2 | — | — |
| `V_downcomer` | 0.277270 m³ | — | — |
| `V_pipes` | 0.202683 m³ | — | — |
| `V_pumpBowl` / `V_hxShell` | 0.150 / 0.266 m³ | — | — |
| `V_loop` | 1.045243 m³ | — | — |
| `tau_core` | 7.216 s | 9.56 s | — |
| `tau_loop` | 13.994 s | 16.14 s | — |
| `tau_total` | 21.210 s | 25.63 s | 25.2 s |

Comparison only. No geometry was adjusted toward the right-hand columns.

### Verification asserts

`EXPECTED_MISMATCH_DURING_PARTIAL_GEOMETRY_BASELINE`. The failures listed in Phases 4 and 5
stand unchanged and **no tolerance was widened**: `Steady_LoopBalance` (τ_system 21.21 s vs
25.63 ± 0.15 s), `Properties_TransitTime` (implied density +34.0 % vs ±5 %),
`Analytic_DriftReactivity` (1.49 / 10.12 pcm vs 0.9 ± 0.2 / 6.7 ± 0.5 pcm), and
`Transient_DriftReactivity` (forced-circulation drift 269.9 pcm vs 228.4, `tol_rho_pcm = 8`).
They are the intended output of a hardware baseline that is not fitted to the benchmark.

### Open items

- **O-12** narrowed, not closed: the boundary-node *definition* is settled; the *physical*
  volumes of 120-03 and 190-01 remain OPEN pending an independent flow-area source.
- **O-17** closed as a classification task: every loop parameter now carries a provenance tag.
  The underlying uncertainty is unchanged and is now explicit rather than absorbed.
- **O-13**, **O-14**, **O-15**, **O-16** unchanged.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain in this environment. Diagnostics computed by hand
outside Modelica from the same expressions now in the record; `Data/Geometry.mo` and
`Components/ReactorCore.mo` checked for Modelica string and comment balance.

---

## Phase 7 — O-13: reference-density decoupling

**Scope:** density *roles*, not density *values in geometry*. No physical volume was rescaled.

```
O-13 RESOLUTION:
The geometry/inventory reference density was migrated from the
legacy ORNL-TM-4865/Compere value to the active Cantor property model.
No physical volume was rescaled.
Pump-density dependencies were audited and separated from the geometry
reference density wherever required.
Changes in mass and transit time are derived consequences of the new
property model, not geometry fitting.
Jeong-equivalent O-12 diagnostics were recomputed with the Cantor density
but remain non-physical and inactive.
```

### Dependency graph, audited before any value changed

```
d_fuel_ref  (was 2249.3, ORNL-TM-4865)
 ├─ m_fuel_core_model / m_fuel_loop_model ......... KEEP      (inventory reporting)
 ├─ err_m_core / err_m_loop ....................... KEEP
 ├─ tau_core_nominal / tau_loop_nominal / system .. KEEP
 ├─ V_flow_ref -> A_190_01_JeongEq -> V_190_01_JeongEq ... KEEP (O-12 diagnostics)
 ├─ V_core_JeongEq -> V_120_03_JeongEq ............ KEEP
 ├─ V_flow_pump_nominal ........................... DECOUPLE  -> d_pump_ref
 ├─ P_pump_hydraulic .............................. DECOUPLE  -> d_pump_ref
 ├─ tau_pump_hyd_nominal .......................... DECOUPLE  -> d_pump_ref
 └─ J_pump ........................................ DECOUPLE  -> d_pump_ref

PrimarySystem.density_ref = Medium_fuel.density(p_system, T_start=908 K)
 ├─ pump.d_nominal ................................ ALREADY OVERRIDDEN
 └─ tau_core / tau_loop (reported at run time) .... ALREADY OVERRIDDEN

PartialFuelPump.d_nominal = 2242 ................... LEGACY ONLY (standalone default)
```

**The finding that shaped the fix:** the four pump quantities in `Data/Geometry.mo` are read by
nothing. `FuelPump_Dynamics` computes its own `tau_hyd_nominal` and `J` from the `d_nominal` it
is handed, and `PrimarySystem` hands it `density_ref`, evaluated from `Medium_fuel`. So:

> System-level pump density is already evaluated from Medium_fuel,
> so Geometry.d_fuel_ref is not the active pump density during PrimarySystem simulation.

The coupling was real inside the record and had **zero** effect on any simulation.

### What changed

| | before | after |
|---|---|---|
| `d_fuel_ref` | `2249.3` hard-coded | `MSRE.Media.FuelSalt.Utilities.d_T(T_zeroPower)` = **2196.5143** |
| `d_pump_ref` | did not exist | `MSRE.Media.FuelSalt.Utilities.d_T(T_zeroPower)` = **2196.5143** |
| `d_fuel_ref_legacy_Compere` | did not exist | `2249.3`, LEGACY, connected to nothing |
| `PartialFuelPump.d_nominal` default | 2242 (Compere @ 922 K) | 2188.646 (Cantor @ 922 K) — standalone default only |

`d_fuel_ref` and `d_pump_ref` evaluate to the same number today. **The separation is structural,
not numerical**: a later change to one cannot move the other. Saying otherwise would overstate
what this commit bought.

### Derived changes — inventory and transit time

| Quantity | Before | After Cantor | Δ |
|---|---:|---:|---:|
| `d_fuel_ref` | 2249.3 | **2196.5143** | −2.347 % |
| `m_fuel_core_model` | 1212.25 kg | **1183.80 kg** | −2.35 % |
| `m_fuel_loop_model` | 2351.07 kg | **2295.89 kg** | −2.35 % |
| `m_fuel_total_model` | 3563.32 kg | **3479.69 kg** | −2.35 % |
| `tau_core_nominal` | 7.2158 s | **7.0464 s** | −2.35 % |
| `tau_loop_nominal` | 13.9944 s | **13.6660 s** | −2.35 % |
| `tau_system_nominal` | 21.2102 s | **20.7125 s** | −2.35 % |
| `V_flow_ref` | 0.074690 m³/s | **0.076485 m³/s** | +2.40 % |
| `A_190_01_JeongEq` | 1.036322 m² | **1.061227 m²** | +2.40 % |
| `V_190_01_JeongEq` | 0.065806 m³ | **0.067388 m³** | +2.40 % |
| `V_core_JeongEq` | 0.714035 m³ | **0.731195 m³** | +2.40 % |
| `V_120_03_JeongEq` | 0.115393 m³ | **0.130971 m³** | **+13.50 %** |

`V_120_03_JeongEq` moves furthest because it is a difference of two larger numbers. It is now
**169 %** of the whole assumed lower plenum (was 148 %), and `V_190_01_JeongEq` is **22.1×** the
legacy boundary-node volume (was 21.5×) and 87 % of the assumed upper plenum. Classification
unchanged: REFERENCE / BENCHMARK-EQUIVALENT / NOT PHYSICAL / NOT ACTIVE. Nothing was connected
to `V_*Plenum_core`.

Error metrics against Jeong widen, as they must when the density falls and the volumes do not:

| | paper | active | before | after |
|---|---:|---:|---:|---:|
| `err_m_core` | — | 1184 vs 1606 kg | −24.5 % | **−26.3 %** |
| `err_m_loop` | — | 2296 vs 2712 kg | −13.3 % | **−15.3 %** |
| circulating | 4318 kg | 3480 kg | −17.5 % | **−19.4 %** |
| τ_core / τ_loop / τ_total | 9.56 / 16.14 / 25.63 s | 7.05 / 13.67 / 20.71 s | — | −26.3 / −15.3 / −19.2 % |

Measured system transit time 25.2 s. Comparison only — no geometry was adjusted.

One consistency gain worth noting: the drift-reactivity figures reported in Phases 4–6 were
already computed at the Cantor density, while the record's own `tau_*_nominal` were still at
2249.3. Those two now agree.

### Pump diagnostics — `DERIVED_CHANGE_FROM_DENSITY_ONLY`

| Quantity | Before | After | Effect on the simulation |
|---|---:|---:|---|
| `V_flow_pump_nominal` | 0.074690 m³/s | 0.076485 m³/s | **none** — diagnostic |
| `P_pump_hydraulic` | 22.407 kW | 22.945 kW | **none** — diagnostic |
| `tau_pump_hyd_nominal` | 230.572 N·m | 236.113 N·m | **none** — diagnostic |
| `J_pump` | 7.5924 kg·m² | 7.7749 kg·m² | **none** — diagnostic |

All four move by exactly +2.403 %, the inverse of the density change, and by nothing else. No
pump parameter was retuned to compensate. `tau_pump_shaft = 4.0 s` — the single fitted pump
quantity, and the one that actually sets the transients — is untouched, so every pump speed
history is unchanged.

### Verification asserts

`EXPECTED_MISMATCH_DURING_PARTIAL_GEOMETRY_BASELINE`, **no tolerance modified**:

| Model | Assert | Before | After |
|---|---|---:|---:|
| `Steady_LoopBalance` | τ_system vs 25.63 ± 0.15 s | 21.21 s | **20.71 s** |
| `Properties_TransitTime` | implied vs Compere density, ±5 % | +34.0 % | unchanged (calls `d_Compere` directly) |
| `Analytic_DriftReactivity` | 0.9 ± 0.2 / 6.7 ± 0.5 pcm | 1.49 / 10.12 | unchanged (calls `d_Compere` directly) |
| `Transient_DriftReactivity` | 228.4 pcm, tol 8 | 269.9 pcm | unchanged (already at Cantor) |

### Open items

- **O-13 closed.** Roles separated, active reference on the property model, legacy preserved.
- **O-18 (new).** `Verification/Analytic_DriftReactivity.mo:29` and `Properties_TransitTime.mo`
  still call `MSRE_Properties.d_Compere` directly, so two verification models now run on a
  density the library does not use. Deliberately not touched here — §14 forbade modifying the
  verification models in this commit — but the double standard should be closed next.
- **O-12** (120-03 / 190-01 physical volumes), **O-14** (failing asserts), **O-15**
  (`dz_channels`), **O-16** (HX geometry + calibration), **O-17** (unsourced loop dimensions)
  unchanged.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain, no MSL/TRANSFORM installation. Every number above
was computed by hand outside Modelica from the expressions now in the record. These are hand
calculations, not compile or simulation results. Edited files were checked for Modelica string
and comment balance.

---

## Phase 8 — O-18: verification density baseline unification

```
O-18 RESOLUTION:
Verification density references were aligned with the active Cantor
fuel-salt property model.
Properties_TransitTime now treats Cantor as ACTIVE and Compere/legacy
as reference comparisons.
Analytic_DriftReactivity uses Cantor for the active transit-time and
drift-reactivity calculation.
No geometry, pump, kinetics, experiment input, or assertion tolerance
was modified.
Any remaining benchmark mismatch is therefore no longer attributable
to a Compere-vs-Cantor verification inconsistency.
```

### Which function, and why

Two Cantor implementations exist: `Media.FuelSalt.Utilities.d_T` (the medium's own) and
`Media.MSRE_Properties.d_Cantor` (a restatement for provenance documentation). Both verification
models now call **`FuelSalt.Utilities.d_T`** — same source of truth as the active medium, and as
`Data.Geometry.d_fuel_ref` since O-13. `MSRE_Properties.d_Cantor` duplicates the formula, so
using it would have created a second path that could silently diverge.

### Density dependency, checked against the code rather than assumed

Both models compute `tau = rho*V/m_flow`. The benchmark states a **mass** flow rate (168 kg/s;
1.46 and 4.45 kg/s for natural circulation), so a density is genuinely required and switching
the baseline moves every transit time. Two quantities are density-*free* and did not move:
`d_implied_repo = m_core/V_channels` (reported mass over hardware volume), and the forced-
circulation drift reactivity and `Beta_circulating`, which use the paper's reported transit
times directly.

### Transit-time comparison (active geometry, 908 K)

| Density | rho | tau_core | tau_loop | tau_total | drift |
|---|---:|---:|---:|---:|---:|
| **Cantor (ACTIVE)** | **2196.514** | **7.046 s** | **13.666 s** | **20.713 s** | **269.9 pcm** |
| Compere (reference) | 2249.322 | 7.216 s | 13.995 s | 21.210 s | 267.2 pcm |
| legacy (reference) | 2063.097 | 6.618 s | 12.836 s | 19.454 s | 277.0 pcm |
| *Jeong (MARS)* | *not published* | *9.56 s* | *16.14 s* | *25.63 s* | *228.4 pcm* |

### Drift comparison

| Case | Cantor (ACTIVE) | Compere (reference) | Jeong target |
|---|---:|---:|---:|
| forced circulation (paper τ, density-free) | 228.35 pcm | 228.35 pcm | 228.4 pcm |
| natural circulation, 1.46 kg/s | **1.562 pcm** | 1.492 pcm | 0.9 ± 0.2 pcm |
| natural circulation, 4.45 kg/s | **10.493 pcm** | 10.123 pcm | 6.7 ± 0.5 pcm |

### The point of the exercise

**The benchmark mismatch was never a Compere-versus-Cantor question.** The two correlations
differ by 2.4 %; the core transit time is out by 26 % and the natural-circulation drift by 74 %
and 57 %. Both natural-circulation cases fail at *either* density. Unifying the baseline did not
cause the failures and does not cure them — it removes an explanation that was never doing any
work, so the residual is now unambiguously the `PARTIAL_GEOMETRY_BASELINE`.

### Assertion status — no tolerance touched

| Model | Assert | Before (Compere) | After (Cantor) |
|---|---|---:|---:|
| `Properties_TransitTime` | implied density, ±5 % | +34.0 % FAIL | **+37.2 % FAIL** |
| `Properties_TransitTime` | active closer than legacy | 34.0 < 46.1 PASS | **37.2 < 46.1 PASS** |
| `Analytic_DriftReactivity` | forced drift, 228.4 ± 0.5 pcm | 228.35 PASS | 228.35 PASS (density-free) |
| `Analytic_DriftReactivity` | `Beta_circulating` 0.0045 ± 1e-4 | 0.004497 PASS | 0.004497 PASS (density-free) |
| `Analytic_DriftReactivity` | nat. circ. 0.9 ± 0.2 / 6.7 ± 0.5 | 1.49 / 10.12 FAIL | **1.56 / 10.49 FAIL** |

`EXPECTED_MISMATCH_DURING_PARTIAL_GEOMETRY_BASELINE`. No tolerance was widened, no assertion
deleted or downgraded to a warning. O-14 remains the place where that is decided.

### Repository-wide audit

| Location | Match | Class | Action |
|---|---|---|---|
| `Verification/Properties_TransitTime.mo` | `d_Compere`, `d_legacy` | VERIFICATION | **fixed** — Cantor active, both retained as reference |
| `Verification/Analytic_DriftReactivity.mo` | `d_Compere(922)` | VERIFICATION | **fixed** — Cantor active, Compere kept as diagnostic |
| `Data/Geometry.mo:46` | `d_fuel_ref_legacy_Compere = 2249.3` | LEGACY REFERENCE | correct as is |
| `Media/MSRE_Properties.mo` | `d_Compere`, `d_legacy` functions, `2575 − 0.513` | LEGACY REFERENCE | correct as is — this is the provenance package |
| `Media/FuelSalt/Utilities/d_T.mo` | `2575 − 0.513`, `2242` in prose | DOCUMENTATION | out of scope, not modified |
| `Data/Geometry.mo` prose | `2249.3` in four doc passages | DOCUMENTATION | historical narrative, correct as is |
| `docs/PHASE_LOG.md` | many | DOCUMENTATION | historical record, appended only |
| `Data/PrecursorGroups/U235_6group.mo:18` | `0.5134` | OTHER | false positive — a half-life |

**No ACTIVE MODEL path outside the two verification files still reads a Compere or legacy
density.** No out-of-scope file was modified.

### Open items

- **O-18 closed.**
- **O-14** is now the sharpest one: three assertions fail and their tolerances are untouched by
  policy. They need to be restated as reported diagnostics or given hardware-consistent targets.
- **O-12** (120-03 / 190-01 physical volumes) is the root cause of all three failures.
- **O-15**, **O-16**, **O-17** unchanged.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain, no MSL/TRANSFORM installation. `checkModel` and both
verification models were **not** run. Every number above is a hand calculation performed outside
Modelica from the expressions now in the files; they are not compile or simulation results. Both
edited `.mo` files were checked for Modelica string and comment balance.

---

## Phase 9 — O-12B: physical reconstruction of the core-boundary plenum nodes

```
O-12B — PHYSICAL RECONSTRUCTION OF CORE-BOUNDARY PLENUM NODES
Jeong defines Volumes 120-03 and 190-01 as the lower and upper
boundaries of the reactor core.
The previous 0.003055 m3 values are legacy inventory-derived values
and are not accepted as physical provenance.
ORNL/INL source geometry was reviewed to identify physical regions
corresponding to those MARS control volumes.
No benchmark transit-time fitting was used.
Any active replacement is based only on independently sourced geometry.
```

**Decision: KEEP OPEN. No active geometry value changed. Documentation only.**

### A. Source findings

**Access limitation, stated first because it governs everything below.** Every primary and
secondary PDF host is unreachable from this environment — `info.ornl.gov`,
`publications.anl.gov`, `www.osti.gov`, `mooseframework.inl.gov` and `moltensalt.org` all return
`EGRESS_BLOCKED` to WebFetch and a proxy 403 to curl. ORNL-TM-728, ORNL-TM-730 and ORNL-TM-3229
could **not** be opened. Everything below is as rendered by a search index from the ANL SAM MSRE
model report and the ORNL MSRE TRANSFORM status report: **secondary, unverified, and with no
table, figure or page number attached.**

| Quantity | Reported value | Attributed to | Definition class | Usable as active? |
|---|---|---|---|---|
| core height | 1.6637 m (65.5 in) | ANL SAM MSRE model | code-model 1-D | no |
| lower plenum height | 0.12954 m (5.1 in) | ANL SAM MSRE model | code-model 1-D | no |
| upper plenum height | 0.21336 m (8.4 in) | ANL SAM MSRE model | code-model 1-D | no |
| lower plenum flow area / Dh | 1.71 m² / 1.47 m | ANL SAM MSRE model | code-model, **porosity 1.0** | no |
| upper plenum fluid volume | 11.34 ft³ = 0.32111 m³ | ORNL MSRE TRANSFORM report | unclear | no |
| core radius / porosity | 0.70485 m / 0.225 | ANL SAM MSRE model | R-Z porous equivalent | no — excluded by policy |
| lower plenum internals | 48 anti-swirl vanes, main support grid, horizontal graphite lattice bars; central region has no bars | INL VTB lower-plenum CFD | qualitative | — |
| lattice/stringer detail | 2.642 cm holes housing 2.54 cm dowels at the stringer lower end | INL VTB | hardware | — |

### B. Physical mapping

**120-03** — the top slice of the lower plenum, immediately below the channel entrance. The
physical region is the lower vessel head plus 48 anti-swirl vanes, the main support grid, and
the horizontal graphite lattice bars the stringers dowel into; the salt reaches the channels
through the gaps between those bars, which carry most of the core pressure drop, and the central
lattice has no bars at all. **No axial height, open flow area or fluid volume was found in any
accessible source.** The only area figure available (SAM's 1.71 m², the full vessel bore at
porosity 1.0) explicitly ignores those structures, so it is an upper bound on an open area, not
a fluid volume. **OPEN.**

**190-01** — the bottom slice of the upper plenum, immediately above the channel exit. Its
length is solid (Jeong, 0.0635 m = 2.5 in); the missing piece is an independent flow area.

### C. Derived geometry — candidates evaluated, none adopted

| Candidate area for 190-01 | A | V = A × 0.0635 | Verdict |
|---|---:|---:|---|
| reactor vessel bore (58 in) | 1.70456 m² | 0.108240 m³ | ignores the core container wall |
| core container bore (55.5 in) | 1.56079 m² | 0.099110 m³ | ignores displaced structure |
| SAM upper plenum mean (0.32111/0.21336) | 1.50503 m² | 0.095569 m³ | unverified; plenum is domed, not prismatic |
| *A_190_01_JeongEq* | *1.06123 m²* | *0.067388 m³* | **excluded — derived from a MARS result** |

The three physical candidates span 0.0956–0.1082 m³ and disagree with the Jeong-equivalent
figure by 42–61 %. Picking whichever landed nearest 1.06123 m² would be benchmark fitting with
extra steps. Neither `V_lowerPlenum/3` nor `V_upperPlenum/3` was used: nothing establishes that
the three nodes are equal-volume, and Jeong's own 2.5 in is not one third of the 8.4 in upper
plenum (that would be 2.8 in).

### D. Active-model decision — **KEEP OPEN**

Against the four conditions in the task:

| Condition | 120-03 | 190-01 |
|---|---|---|
| 1. independent source exists | **no** | length yes, area **no** |
| 2. geometry definition unambiguous | **no** | **no** |
| 3. MARS-node ↔ physical-region mapping explicable | qualitative only | partial |
| 4. not a transit-time back-calculation | yes | yes |

Conditions 1–3 fail. `V_lowerPlenum_core` and `V_upperPlenum_core` stay at 0.003055 m³ with
their `LEGACY/OPEN` tag, and their description strings now record that O-12B looked and did not
find. Nothing was connected to `V_190_01_JeongEq`.

### E. Impact — none

No active value changed, so `V_core` 0.538946 m³, `V_loop` 1.045243 m³, core mass 1184 kg, loop
mass 2296 kg, τ_core 7.046 s, τ_loop 13.666 s, τ_system 20.713 s, forced drift 269.9 pcm and
natural-circulation drift 1.562 / 10.493 pcm are all unchanged. No assertion tolerance was
touched and no assertion changed state.

### F. Remaining uncertainty, and the one genuinely new result

The useful output of O-12B is not about the boundary nodes at all. **This record assumes
0.0777 m³ for each plenum total; the reviewed figures put the lower plenum near 0.2215 m³ and
the upper plenum near 0.3211 m³ — 2.9× and 4.1× larger.** Even discounted for the porosity-1.0
treatment, that is independent support for the first of the two readings offered under O-12:
the MARS plena are much larger than assumed here, and the missing circulating inventory is
more likely hiding in `V_lowerPlenum` / `V_upperPlenum` than in the channel geometry. Those are
O-17 scope and were deliberately not touched.

Two definition mismatches recorded alongside: the SAM core height 1.6637 m is 2.34 % longer
than the 1.6256 m used here, and the SAM core salt flow area 0.3512 m² is 7 % larger than the
0.32778 m² that 1140 channels of documented cross-section give. Neither adopted — both are R-Z
porous-medium equivalents, excluded by policy.

**What would close O-12B:** ORNL-TM-728 (reactor vessel, core support structure, flow
distributor), ORNL-TM-730 (core boundary) and ORNL-TM-3229 (core entrance hydraulics) read
directly, or the Jeong MARS input deck. If the PDFs are supplied locally, or egress is opened
to those hosts, the review can be redone against primary text with table and page numbers.

### Open items

- **O-12B** open. **O-12** unchanged and still the root cause of the failing assertions.
- **O-14**, **O-15**, **O-16**, **O-17** unchanged. O-17 gains a concrete lead: the plenum
  totals look far too small.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain. No computation in the library changed, so no
re-evaluation was needed; the candidate arithmetic above was done by hand outside Modelica.
`Data/Geometry.mo` was checked for Modelica string and comment balance.

---

## Phase 10 — O-17: whole-plenum fuel-salt volumes

```
O-17 — WHOLE PLENUM FLUID VOLUMES

Previous active values:
  lower = 0.0777 m3
  upper = 0.0777 m3
  status = unsupported assumptions

Reference:
  ORNL/TM-2019/1359
  Status Report on the MSRE TRANSFORM Model for Thermal-Hydraulic Benchmarking

Reported values:
  lower-plenum fluid volume = 12.24 ft3 = 0.346598 m3
  upper-plenum fluid volume = 11.34 ft3 = 0.321113 m3

The report attributes the MSRE volume information to ORNL-4865.

Decision:
  Promote whole-plenum total volumes to REFERENCE.

Do NOT infer individual Jeong MARS node volumes from these totals.
Volumes 120-03 and 190-01 remain O-12B OPEN.
Whole-plenum axial heights remain assumptions/open.
```

**Decision: CLOSED / REFERENCE for the two volumes. The two plenum heights stay OPEN.**

### A. What changed

| Parameter | Before | After | Class before | Class after |
|---|---:|---:|---|---|
| `V_lowerPlenum` | 0.0777 m³ | **0.346598 m³** (4.46×) | ASSUMPTION | **REFERENCE** |
| `V_upperPlenum` | 0.0777 m³ | **0.321113 m³** (4.13×) | ASSUMPTION | **REFERENCE** |
| `L_lowerPlenum` | 0.30 m | 0.30 m | ASSUMPTION | ASSUMPTION / OPEN |
| `L_upperPlenum` | 0.30 m | 0.30 m | ASSUMPTION | ASSUMPTION / OPEN |

Conversion with the exact factor 1 ft³ = 0.028316846592 m³:
12.24 × 0.028316846592 = 0.34659820 → **0.346598 m³**;
11.34 × 0.028316846592 = 0.32111304 → **0.321113 m³**.

No other active parameter was touched. `L_downcomer`, the three pipe lengths, `V_pumpBowl`,
`V_hxShell`, `V_lowerPlenum_core`, `V_upperPlenum_core`, the density and the mass flow rate are
all unchanged — none of them was allowed to move to absorb the change.

### B. What O-17 explicitly does **not** do

- **O-12B stays OPEN.** `V_lowerPlenum_core` (MARS 120-03) and `V_upperPlenum_core`
  (MARS 190-01) keep 0.003055 m³ with their `LEGACY/OPEN` tag. A whole-plenum total fluid
  volume and a single MARS control volume inside that plenum are not the same quantity, and
  the report gives no nodalization. Nothing was divided by three, and nothing was connected to
  `V_190_01_JeongEq`.
- **O-14 untouched.** No assertion deleted, no tolerance widened, no benchmark target moved.
  The three failing asserts are left exactly as they were, and the effect of O-17 on them is
  reported below rather than engineered away.
- **The plenum heights stay OPEN.** The source gives fluid volumes, not axial extents. The
  `L_*Plenum_core` expressions therefore remain a legacy uniform-bore diagnostic, explicitly
  *not* an independently reconstructed physical MARS-node length; their descriptions now say so.
- The earlier **~0.2215 m³** lower-plenum figure quoted under O-12B was a secondary SAM
  porous-medium estimate (1.71 m² at porosity 1.0 over 0.12954 m). It is neither active nor a
  reference value; O-17 supersedes it with 12.24 ft³ = 0.346598 m³. The O-12B section in
  `Data/Geometry.mo` now says this in place, so the figure cannot be read as an active value.

### C. Derived quantities — recomputed, not fitted

| Quantity | Before | After |
|---|---:|---:|
| `V_core` | 0.538946 m³ | 0.538946 m³ (unchanged) |
| `V_loop` | 1.045243 m³ | **1.557554 m³** (+49.0 %) |
| `V_total` | 1.584189 m³ | **2.096500 m³** (+32.3 %) |
| `tau_core_nominal` | 7.046 s | 7.046 s (unchanged) |
| `tau_loop_nominal` | 13.666 s | **20.364 s** |
| `tau_system_nominal` | 20.713 s | **27.411 s** (paper 25.63 s) |
| `m_fuel_core_model` | 1184 kg | 1184 kg (unchanged) |
| `m_fuel_loop_model` | 2296 kg | **3421 kg** |
| `err_m_core` | −26.29 % | −26.29 % (unchanged) |
| `err_m_loop` | −15.33 % | **+26.17 %** |
| circulating inventory vs 4318 kg | 3480 kg, −19.41 % | **4605 kg, +6.66 %** |
| `L_lowerPlenum_core` (diagnostic) | 0.011795 m | 0.002644 m |
| `L_upperPlenum_core` (diagnostic) | 0.011795 m | 0.002854 m |
| `V_120_03_JeongEq` as a share of the whole lower plenum | 169 % | 37.8 % |
| `V_190_01_JeongEq` as a share of the whole upper plenum | 87 % | 21.0 % |

Delayed-neutron transport quantities, computed from the same expressions the library uses
(paper Eq. 8, `Functions.driftReactivity`):

| Case | Before | After | Paper |
|---|---:|---:|---:|
| natural circulation, 1.46 kg/s | 1.5619 pcm | **1.5619 pcm** | 0.9 pcm |
| natural circulation, 4.45 kg/s | 10.4928 pcm | **10.5004 pcm** | 6.7 pcm |
| forced circulation at this record's own τ | 269.9 pcm | **287.7 pcm** | 228.4 pcm |
| forced circulation at the paper's τ (density- and volume-free) | 228.35 pcm | 228.35 pcm | 228.4 pcm |

The natural-circulation figures barely move because at 1.46 and 4.45 kg/s both transit times
are already long compared with every precursor half-life, so Eq. 8 has saturated.

### D. Assertion status — `EXPECTED_MISMATCH_DURING_PARTIAL_GEOMETRY_BASELINE`

| Model | Assert | Before | After |
|---|---|---:|---:|
| `Steady_LoopBalance` | τ_system vs 25.63 ± 0.15 s | 20.713 s FAIL (−4.92 s) | **27.411 s FAIL (+1.78 s)** |
| `Analytic_DriftReactivity` | nat. circ. 0.9 ± 0.2 / 6.7 ± 0.5 pcm | 1.5619 / 10.4928 FAIL | **1.5619 / 10.5004 FAIL** |
| `Properties_TransitTime` | implied density ±5 % | +37.2 % FAIL | +37.2 % FAIL (unchanged — depends on `V_channels` only) |
| `Properties_TransitTime` | active closer than legacy | PASS | PASS (unchanged) |
| `Analytic_DriftReactivity` | forced drift 228.4 ± 0.5 pcm | PASS | PASS (uses the paper's τ) |
| `Analytic_DriftReactivity` | `Beta_circulating` 0.0045 ± 1e-4 | PASS | PASS |

No tolerance was modified and no assertion was deleted or downgraded. The τ_system assert is
closer to its target than before, but that is a by-product of adopting a sourced volume and not
the reason for adopting it; O-14 remains the place where the three failures are decided.

### E. The substantive result

The old picture was a core 26.3 % short and a loop 15.3 % short, adding to a 19.4 % shortfall.
The new one is a core **26.3 % short** and a loop **26.2 % long** — nearly equal and opposite —
with the total 6.7 % long. That is what a control-volume boundary drawn in a different place
looks like: salt that MARS counts inside its core-boundary nodes and this record counts as
plenum. It is the second of the two readings recorded under O-12, and O-17 is the evidence that
the first one (plena too small) was real and is now spent.

Nothing was moved to make the two sides meet. Settling the remainder needs the MARS node
volumes — O-12B, still OPEN.

### F. Scope

Modified: `Data/Geometry.mo`, `docs/PHASE_LOG.md`.

Not modified: fuel-salt property correlations, pump model, heat exchanger model, kinetics,
experiment inputs, channel geometry, downcomer geometry, pipe lengths, and the O-14 assertion
policy. `Components/ReactorCore.mo` carries `V_lowerPlenum = V_upperPlenum = 0.0777` as
*component defaults*; `Systems/PrimarySystem.mo` overrides both from `Data.Geometry`, so no
active model path reads them. They are out of scope for this commit and are recorded here as a
follow-up.

Two verification documentation tables still quote the pre-O-17 loop figures
(`Properties_TransitTime.mo` line 183: 13.666 s / 20.713 s / 269.9 pcm;
`Analytic_DriftReactivity.mo` line 120: 1.56 / 10.49 pcm). Prose only — no assertion, no active
value — and out of scope here because §8 puts the verification models off limits. Follow-up.

### Open items

- **O-17 closed** for the two whole-plenum volumes; the two plenum **heights** remain OPEN.
- **O-12B** open, unchanged, and now the only route to the remaining ±26 % split.
- **O-14** untouched and still the sharpest item.
- **O-15**, **O-16** unchanged.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain, no MSL/TRANSFORM installation. `checkModel` was not
run and no verification model was simulated. Every number above is a hand calculation performed
outside Modelica from the expressions now in the record. `Data/Geometry.mo` was checked for
Modelica string, comment and HTML-tag balance, and the diff was checked to confirm that the two
plenum volumes are the only active parameters that changed.

---

## Phase 10 — Non-pump baseline: equal-volume plenum nodes and a single Gnielinski closure

**Scope:** fuel-salt property (unchanged), core geometry (unchanged), plenum nodalization, core
and heat-exchanger heat transfer, and the verification/documentation that follows. The pump,
the kinetics, the precursor data, the external-loop pipe lengths and every assertion tolerance
are untouched.

### Decisions taken

| # | Decision | Rationale |
|---|---|---|
| 28 | `V_lowerPlenum_core = V_lowerPlenum/nLP`, `V_upperPlenum_core = V_upperPlenum/nUP` | Replaces the 0.003055 m³ inventory-balance residue with a subdivision of a *referenced* volume. Tagged **ASSUMPTION / DERIVED FROM REFERENCE**, never PHYSICAL: nothing published says the three nodes are equal, and Jeong's 0.0635 m for 190-01 is not one third of any plenum height here. |
| 29 | 0.003055 m³ retired to `V_plenumCore_legacy`, diagnostic only | Its derivation (reported 1606 kg ÷ old density − old channel volume) is benchmark fitting. |
| 30 | `ClosureRelations.Nus_MoltenSalt` becomes **Gnielinski**, used by the core channels and both HX sides | One correlation, no calibration coefficient. `Nu_floor` and `f_enhance` inputs deleted. |
| 31 | `f_shellHT` and `Nu_floor_shell` kept in `Data.Geometry` as **LEGACY/DEPRECATED**, connected to nothing | Deleting them would break nothing but loses the record of what was calibrated. |
| 32 | The shell-side `L_char = D_tube_outer` modifier is removed | Gnielinski is a duct correlation; referring Nu to a different length than Re is formed with was part of the retired cross-flow hybrid. Both HX sides now use Dh consistently. |
| 33 | `Dh_shell = 0.05606 m` tagged **OPEN / TO BE REVIEWED**, not changed | INL gives 0.0209 m. Changing it in the same pass as the closure would confound two effects. O-16. |
| 34 | No sub-transitional correction added | Explicitly out of scope; see the blocker below. |

### B. Parameter changes

```
V_lowerPlenum_core   0.003055        -> 0.1155327 m3   (= 0.346598/3)
V_upperPlenum_core   0.003055        -> 0.1070377 m3   (= 0.321113/3)
L_lowerPlenum_core   0.002644        -> 0.1000000 m
L_upperPlenum_core   0.002854        -> 0.1000000 m
V_plenumCore_legacy  (new)           -> 0.003055 m3, diagnostic only
ReactorCore.V_lowerPlenum default  0.0777 -> 0.346598 m3
ReactorCore.V_upperPlenum default  0.0777 -> 0.321113 m3
Nus_MoltenSalt       Nu_floor + f*0.023*Re^0.8*Pr^0.4  -> Gnielinski
f_shellHT = 3.0, Nu_floor_shell = 10.0   -> LEGACY/DEPRECATED, unused
```

Unchanged as required: `nChannels_total` 1140, `H_channels` 1.6256 m, `w/h/r_channel`,
`A_channel` 2.875244e-4 m², `Dh_channel` 0.015851 m, `V_channels` 0.532836 m², the fuel-salt
correlations, every pump parameter, `f_area_hx` 1.0, and all assertion tolerances.

### C. Derived quantities

| Quantity | Before | After |
|---|---:|---:|
| `V_channels` | 0.532836 m³ | 0.532836 m³ |
| `V_core` | 0.538946 m³ | **0.755406 m³** |
| `V_loop` | 1.557554 m³ | **1.341094 m³** |
| `m_fuel_core_model` | 1184 kg | **1659.3 kg** |
| `m_fuel_loop_model` | 3421 kg | **2945.7 kg** |
| circulating | 4605 kg | 4605 kg (unchanged — salt moved between core and loop) |
| `tau_core_nominal` | 7.046 s | **9.877 s** |
| `tau_loop_nominal` | 20.364 s | **17.534 s** |
| `tau_system_nominal` | 27.411 s | 27.411 s |

### D. Jeong comparison

| | model | Jeong | Δ |
|---|---:|---:|---:|
| τ_core | 9.877 s | 9.56 s | **+3.31 %** |
| τ_loop | 17.534 s | 16.14 s | **+8.64 %** |
| τ_total | 27.411 s | 25.63 s | **+6.95 %** |
| core mass | 1659 kg | 1606 kg | +3.31 % |
| loop mass | 2946 kg | 2712 kg | +8.64 % |
| forced drift | **227.06 pcm** | 228.35 pcm | −1.29 pcm |

**This closeness is not a validation.** It is the consequence of an equal-volume subdivision
assumption meeting a referenced plenum volume; nothing was fitted, and equally nothing was
confirmed. τ_core landing 3 % from 9.56 s must not be reported as agreement.

### E. Heat-transfer implementation

```
Core uses Gnielinski:      YES
HX shell uses Gnielinski:  YES
HX tube uses Gnielinski:   YES
old Nu_floor active:       NO  (input deleted from the model)
old f_shellHT active:      NO  (parameter retained as LEGACY, connected to nothing)
```

### **BLOCKER — the core channels are laminar at rated flow**

At 168 kg/s the MSRE fuel channels run at **Re = 812** (0.233 m/s through a 15.85 mm hydraulic
diameter). Gnielinski is valid for Re ≳ 3000 and its `(Re − 1000)` factor turns negative below
1000, so it returns:

| Location | Re at rated flow | Pr | Gnielinski Nu | retired closure Nu |
|---|---:|---:|---:|---:|
| core fuel channel | **812** | 20.1 | **−3.99** | 20.6 |
| HX shell side | 8637 | 20.1 | 101.6 | 333.0 |
| HX tube side | 10510 | 15.8 | 112.2 | 118.7 |

**A negative Nusselt number is a negative heat transfer coefficient.** This is not confined to
natural circulation — it is the nominal, full-flow condition. As instructed, no low-Re
correction was added, so the core side of the closure is presently unusable for any thermal
result and the §20 steady-state checks (core ΔT, Q_core, Q_HX, energy balance) cannot be
produced from it. Recorded as **O-19**, and it needs a user decision.

The HX is unaffected on the correlation's own terms, but note the shell-side coefficient falls
by a factor of ~12 (22450 → 1812 W/m²K) once `f_enhance = 3` and `L_char = D_tube_outer` are
removed. That is the calibration being withdrawn, not an error.

### F. Remaining OPEN items

- **O-19 (new)** sub-transitional core-channel heat transfer — blocks all thermal results
- **O-12B** physical volume of MARS 120-03 and 190-01
- **O-16** HX shell-side hydraulic geometry (`Dh_shell` 0.05606 vs INL 0.0209 m)
- **O-17** external-loop pipe lengths, `L_downcomer`, `V_pumpBowl`, plenum axial heights
- **O-14** the failing assertions
- **O-15** `dz_channels` 1.626 m vs `H_channels` 1.6256 m
- pump validation (out of scope by instruction)

### G. Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain, no MSL/TRANSFORM installation. `checkModel`,
`translate` and the steady-state run were **not** performed. Every number above is a hand
calculation outside Modelica. Assertion states, with **no tolerance modified**:

| Assert | Value | Limit | State |
|---|---:|---:|---|
| `Steady_LoopBalance` τ_system | 27.411 s | 25.63 ± 0.15 | FAIL |
| `Properties_TransitTime` implied density | +37.2 % | ±5 % | FAIL |
| `Properties_TransitTime` active vs legacy | 37.2 < 46.1 | — | PASS |
| `Analytic_DriftReactivity` forced drift | 228.35 pcm | 228.4 ± 0.5 | PASS |
| `Analytic_DriftReactivity` Beta_circulating | 0.004497 | 0.0045 ± 1e-4 | PASS |
| `Analytic_DriftReactivity` nat. circ. low | 0.818 pcm | 0.9 ± 0.2 | **PASS** (was FAIL) |
| `Analytic_DriftReactivity` nat. circ. high | 6.199 pcm | 6.7 ± 0.5 | FAIL by 0.0009 pcm |

---

## Phase 11 — O-19: core laminar heat-transfer closure

### 1. Re re-verified from the code's own definitions

Nothing was adjusted to move the Reynolds number. Every input below is read from
`Data/Geometry.mo` and `Media/FuelSalt`.

```
A_channel   = w*h - (4-pi)*r^2            = 2.875244e-4 m2
perimeter   = 2(w+h) - 4r(2-pi/2)         = 0.072559 m
Dh_channel  = 4*A/P                       = 0.015851 m
A_flow_tot  = 1140 * A_channel            = 0.327778 m2
rho(908 K)  = 2553.3 - 0.562*(T-273.15)   = 2196.5143 kg/m3
mu(908 K)   = 8.4e-5*exp(4340/T)          = 1.000212e-2 Pa.s
v  = m_flow/(rho*A_flow_tot)              = 0.233343 m/s
Re = rho*v*Dh/mu = m_flow*Dh/(A_tot*mu)   = 812.24
Pr = cp*mu/k                              = 20.101
```

**VERIFIED.** `Dh = 0.015851 m` and `v = 0.2333 m/s` both follow from the geometry as defined;
the density cancels out of `Re` entirely. Reaching Re = 2300 would need 476 kg/s (2.83× rated)
or a viscosity 2.83× lower.

Incidental finding: the corner radius is exactly half the channel depth (0.00508 = 0.01016/2),
so the channel is an **obround/stadium**, not a rounded rectangle — the two short ends are
semicircles. The area and perimeter formulas already in the record are exact for that shape.

### 2. Power deposition path — traced

```
Nuclear/PointKinetics_DNPtransport -> kinetics.Qs
  -> PrimarySystem.mo:131   core.Qs_core = kinetics.Qs
    -> ReactorCore.mo:204   Qs_channels[r,k] = Qs_core[...]*(1 - f_graphiteHeating)
      -> ReactorCore.mo:165 channels[r].Q_gens = Qs_channels[r,:]
        -> CoreChannel.mo:108 pipe.InternalHeatGen = GenericHeatGeneration(Q_gens=Q_gens)
           == VOLUMETRIC HEAT SOURCE in each fuel-salt control volume
    -> ReactorCore.mo:205   Qs_channels_graphite = Qs_core[...]*f_graphiteHeating
      -> CoreChannel.mo:127 graphite.InternalHeatModel = GenericHeatGeneration
  plenum core nodes: ReactorCore.mo:216/221 Qs_LP, Qs_UP -> also volumetric
```

`f_graphiteHeating = 0` by default (`PrimarySystem.mo:42`, `ReactorCore.mo:68`), so **100 % of
the fission power enters the fuel salt as a volumetric source and none of it passes through the
convective closure.** Axial and radial shaping already exists via `SF_core` from
`Functions.corePowerShape`, with `sum(SF_core) = 1` — the structure section 7 of the request
asks for is already present and was not changed.

### 3. Blocker re-adjudicated — **Case A**

`Q_core`, core outlet temperature, core ΔT and the primary energy balance are
`Q = m_flow*cp*ΔT` and do **not** depend on the core Nusselt number. The earlier claim that
O-19 blocked all thermal results was **wrong** and is retracted. O-19 is re-scoped to:

> Core wall/graphite-to-fuel heat-transfer closure undetermined.

It sets the fuel-to-graphite temperature difference and hence the graphite temperature, which
matters for graphite thermal feedback and for the paper's `f_graphiteHeating` sensitivity — not
for bulk temperatures. A negative `h` was still not acceptable: with `q = h(T_w - T_f)` and
`h < 0` the graphite coupling becomes anti-restoring and the graphite temperature diverges.

### 4-6. Closure split

| Component | Closure | Model |
|---|---|---|
| core fuel channels | laminar / blend / Gnielinski | **`ClosureRelations.Nus_Core`** (new) |
| HX shell | Gnielinski | `ClosureRelations.Nus_MoltenSalt` |
| HX tube | Gnielinski | `ClosureRelations.Nus_MoltenSalt` |

```
Re < 2300          Nu = Nu_laminar (4.36)
2300 <= Re < 3000  Nu = (1-w)*Nu_laminar + w*Nu_Gnielinski,  w = x^2(3-2x), x = (Re-2300)/700
Re >= 3000         Nu = Nu_Gnielinski
```

The smoothstep weight and its first derivative vanish at both ends, so Nu is C¹ across the
window. **No multiplier, enhancement factor or Nusselt floor was added anywhere.**

`Nu_laminar = 4.36` (constant heat flux) rather than 3.66 (constant wall temperature), on the
evidence of the model's own boundary condition: the graphite annulus in `CoreChannel` is
adiabatic on its outer radius and both ends, and its only source is the `f_graphiteHeating`
share of fission power, so whatever it generates must leave through the salt interface — the
wall imposes a flux, not a temperature. Tagged:

```
ASSUMPTION / GENERIC LAMINAR CLOSURE
Used only as an interim closure for the 1-D TRANSFORM benchmark model.
Not an experimentally validated MSRE-specific heat-transfer correlation.
```

Deferred, and named as such in the model: obround-duct laminar correlation, MSRE-specific
treatment, Poppendiek effect and graphite–fuel coupling.

### 9. Comparison

| Parameter | Before | After | Reason |
|---|---:|---:|---|
| Core Re | 812 | 812 | unchanged — nothing was adjusted |
| Core Nu | **−3.99** | **4.36** | laminar branch replaces out-of-range Gnielinski |
| Core h [W/m²K] | **−251.8** | **275.1** | `Nu*k/Dh`, k = 1.0, Dh = 0.015851 |
| HX shell Re | 8637 | 8637 | unchanged |
| HX shell Nu | 101.57 | 101.57 | unchanged |
| HX shell h | 1811.7 | 1811.7 | unchanged |
| HX tube Re | 10510 | 10510 | unchanged |
| HX tube Nu | 112.23 | 112.23 | unchanged |
| HX tube h | 11684.3 | 11684.3 | unchanged |

Steady-state bulk energy balance — **hand calculation, not simulation**, and independent of
every Nusselt number above:

```
dT_core = Q_core/(m_flow*cp),  m_flow = 168 kg/s,  cp = 2009.66 J/(kg.K)
  Q = 10 MWth  -> dT = 29.62 K
  Q =  8 MWth  -> dT = 23.70 K
  reported dT = 28 K -> Q = 9.45 MWth
```

`Q_HX`, `Q_core − Q_HX` and the residual fraction need a solved secondary side and are
`BLOCKED_NOT_RUN`.

### O-19 STATUS

```
O-19 STATUS:
Core Re calculation:
  VERIFIED
Core flow regime:
  LAMINAR  (Re = 812 at rated flow; laminar under every simulated condition)
Core power deposition method:
  VOLUMETRIC HEAT SOURCE
  (CoreChannel.pipe.InternalHeatGen; f_graphiteHeating = 0 sends 100 % to the salt)
Is Gnielinski required for core bulk dT?:
  NO
Core thermal closure:
  Nus_Core - generic laminar Nu = 4.36 below Re 2300,
  smoothstep blend to Gnielinski over 2300-3000, Gnielinski above 3000
HX thermal closure:
  Gnielinski (Nus_MoltenSalt), shell and tube
O-19 classification:
  PARTIALLY CLOSED
Remaining limitation:
  The laminar constant is a generic circular-duct value, not an MSRE obround-channel
  correlation, and no entrance-length, Poppendiek or graphite-coupling effect is
  represented. It sets the graphite temperature, not the bulk fuel temperature, so
  it is not on the path to Q_core or core dT.
```

### Not modified

168 kg/s nominal flow, fuel-salt viscosity and density, channel count, channel area, hydraulic
diameter, core power, HX hydraulic diameter (`Dh_shell`, still O-16), `f_area_hx`, every pump
parameter, the kinetics and precursor data, and every assertion tolerance. No transit-time or
inventory value changed, so the assertion states of Phase 10 stand unchanged.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain, no MSL/TRANSFORM. `checkModel`, `translate` and the
steady-state run were **not** performed. Every number in this entry is a hand calculation
outside Modelica; none is a simulation result. Edited files were checked for Modelica string
and comment balance.

---

## Phase 12 — O-15 closed, and a derived consequence of the plenum subdivision (O-20)

### O-15 — closed

`dz_channels` was a standalone 1.626 m while `H_channels` is 1.6256 m, a 0.4 mm inconsistency
left over from the pre-hardware geometry. It is now `final parameter dz_channels = H_channels`,
which is what `Components/ReactorCore.mo` already did by default. The elevation set still closes
exactly, because `dz_downcomer` is defined as minus the sum of the others; it absorbs the 0.4 mm.

### O-20 (new) — the plenum core nodes now carry 14.8 % of the fission source

`Functions/corePowerShape` applies one cosine over the whole core height and weights each cell
by its **volume**. That was harmless while the two plenum core nodes held 3.055 litres each. At
one third of the referenced plenum totals they hold 0.1155 and 0.1070 m³ — **65 times a channel
cell** — and the source shape moves with them:

| | nodes at 3.055 L | nodes at one third of a plenum |
|---|---:|---:|
| `SF` lower plenum node | 0.00201 | **0.07668** |
| `SF` upper plenum node | 0.00201 | **0.07104** |
| both together | **0.40 %** of core fission | **14.77 %** |
| `phi` at the plenum nodes | 0.355 | 0.501 |
| channel axial peak/average | 1.348 | 1.265 |
| plenum cell / channel cell volume | 1.7× | 65.0× |
| `L_core` seen by the cosine | 1.6311 m | 1.8256 m |

`sum(SF) = 1` and `sum(phi·V)/sum(V) = 1` still hold, so the normalisation is intact; what
changed is where the source sits.

**Nearly a seventh of the fission source is now placed in salt with no graphite around it.**
The plena are unmoderated, so the thermal flux there should be *lower* than in the channels
rather than comparable, and Jeong describes 120-03 and 190-01 as thin slices at the core
boundary — 0.0635 m for 190-01, against the 0.1 m the equal-volume assumption gives.

This is a **consequence of the equal-volume subdivision, surfaced rather than fixed.**
`corePowerShape` was not changed: correcting it means choosing a physical treatment — exclude
the plena from the moderated shape, weight them by a moderator-presence factor, or take the
shape from a transport calculation — and that is a modelling decision, not a cleanup. It also
feeds the kinetics through `phis_core`, so it moves the precursor weighting and the drift
results, not only the thermal field.

O-20 and O-12B are the same question from two sides: what those two nodes physically are.

### Open items

- **O-20 (new)** fission-source treatment of the unmoderated plenum core nodes — needs a decision
- **O-12B** physical volume of MARS 120-03 / 190-01 (blocked on source access)
- **O-19** residual: obround-duct laminar Nusselt number, entrance length, Poppendiek, graphite coupling
- **O-16** HX shell-side hydraulic geometry — the calibration coupling that blocked it is now
  gone, since `f_shellHT` and `Nu_floor_shell` are disconnected, so this is unblocked whenever
  a verified shell geometry is available
- **O-14** the failing assertions
- **O-17** unsourced loop dimensions
- **O-15 closed**

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain. The shape figures above were computed outside
Modelica by re-implementing `corePowerShape` exactly as written, with the record's own
`f_radial`, `A_channel`, `H_channels` and `f_axialExtrapolation = 1.2`. No assertion tolerance
was touched and no assertion changed state: `dz_channels` moves only `dz_downcomer`, and the
shape change affects the kinetics rather than any asserted transit time.
