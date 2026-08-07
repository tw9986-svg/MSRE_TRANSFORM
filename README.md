# MSRE

A one-dimensional, coupled neutronic / thermal-hydraulic Modelica model of the
**Molten-Salt Reactor Experiment (MSRE)**, built on the
[TRANSFORM](https://github.com/ORNL-Modelica/TRANSFORM-Library) library and developed for Dymola.

The model is a Modelica re-implementation of the MARS input model documented in:

> J.J. Jeong, Y.J. Cho, H.C. Lee, B. Yun,
> *Benchmarking the MARS code for molten salt reactor applications using MSRE transient
> experiments*, Nuclear Engineering and Technology **58** (2026) 104438.

Package version: `0.2.2`

## Requirements

| Dependency | Version |
|---|---|
| Modelica Standard Library | 4.1.0 |
| TRANSFORM | 1.1 |
| Tool | Dymola (the models use `__Dymola_` experiment annotations) |

## Getting started

1. Load the Modelica Standard Library 4.1.0 and TRANSFORM 1.1.
2. Open `package.mo` at the root of this repository.
3. Simulate one of the models under `MSRE.Experiments` or `MSRE.Verification`.

`MSRE.Verification.Analytic_DriftReactivity` is the cheapest thing to run first: it is a
parameter-only model that checks the drift-reactivity function against every value the paper
quotes, and it fails loudly if the underlying data has drifted.

## What the model reproduces

The central modelling choice is the **modified point-kinetics** treatment of a circulating-fuel
reactor. The conventional precursor balance is replaced by a delayed-neutron-precursor (DNP)
**transport** equation solved over the whole primary system (paper Eq. 3). In Modelica this is
done by declaring the six DNP groups as *trace substances* of the fuel-salt medium, so the
TRANSFORM fluid components transport them automatically; source and decay terms are supplied
through an `InternalTraceGen` closure model.

On top of that:

- The effective core precursor number `C_i(t)` of paper Eq. 4, including importance and flux
  weighting.
- The effective delayed-neutron fraction `Beta_eff` obtained from the steady state (paper Eq. 6)
  after a null transient, then held constant through the transient.
- The reactivity model of paper Eq. 5 — fuel and graphite temperature feedback plus external
  reactivity.
- The ideal control-rod (flux servo) reactivity of paper Eq. 7, used for the zero-power pump tests.
- The analytic steady-state drift reactivity of paper Eq. 8, exposed as
  `MSRE.Functions.driftReactivity` so the simulated asymptotic reactivity loss can be checked
  against it. The paper reports 226.5 pcm simulated against 228.4 pcm analytic.

## Package structure

| Package | Contents |
|---|---|
| `Media` | MSRE fuel salt (LiF-BeF2-ZrF4-UF4) and secondary coolant salt property models. `FuelSalt_U235` / `FuelSalt_U233` add the six DNP groups as trace substances. |
| `Data` | Precursor group data (paper Tables 1-2), kinetics data for U-235 and U-233, and the `Geometry` nodalization record. |
| `Functions` | `driftReactivity` (paper Eq. 8), `coreCellVolumes`, `corePowerShape`. |
| `ClosureRelations` | `Nus_MoltenSalt` — Nusselt correlation for the molten-salt channels. |
| `Nuclear` | `PointKinetics_DNPtransport` — the modified point-kinetics model. |
| `Components` | `SaltPipe`, `CoreChannel`, `ReactorCore`, `FuelPump`. |
| `Systems` | `PrimarySystem` — the complete primary loop, with the secondary side of the heat exchanger imposed as a boundary condition. |
| `Experiments` | The three benchmark transients. |
| `Verification` | Self-checking models that assert against analytic results. |

### Nodalization

`MSRE.Data.Geometry` groups the 1140 fuel channels into 15 concentric radial rings with 20 axial
nodes each, plus lower plenum (3), upper plenum (3), downcomer (10), heat exchanger (10 per side),
and the connecting piping. Following the paper, the last lower-plenum node and the first
upper-plenum node count as part of the reactor core, giving `nV_core = 15*20 + 2 = 302` cells seen
by the kinetics.

## Experiments

| Model | Paper section | Description |
|---|---|---|
| `PumpStartup` | 4.1 | ~100 W, 908 K isothermal, fuel pump started from rest and brought to rated flow in about 10 s. The flux servo holds the reactor critical, so rod reactivity *is* the flow-induced reactivity change. |
| `PumpCoastdown` | 4.2 | The inverse test. Starts at rated 168 kg/s and trips the pump; precursors dwell longer in the core, `Beta_eff` recovers toward the static value, and positive reactivity is inserted. |
| `NaturalCirculation` | 4.3 | U-233 fuel, pump stopped, driven by a change in heat removal on the secondary side. See the caveat below. |

## Verification

Two models check the physics without needing any measurement:

- **`Analytic_DriftReactivity`** — asserts `driftReactivity` against the paper's Eq. 8 values:
  228.4 pcm at the reported transit times, the resulting circulating `Beta_eff` of about 0.0045
  against the static 0.00678, and the natural-circulation values at 1.46 and 4.45 kg/s.
- **`Transient_DriftReactivity`** — extends `PumpStartup` and asserts two things. First, that the
  transient settles onto the Eq. 8 asymptote (Eq. 8 is the steady-state limit of the same
  precursor transport the transient integrates, so they must agree; tolerance 8 pcm, and the
  paper's own MARS transient lands 1.9 pcm below its analytic value). Second, that the reactivity
  oscillation period matches the system transit time, since the oscillation is caused by
  precursors re-entering the core one transit time after they left.

## Caveats on input data

Publicly reported MSRE data do not include a complete node-by-node volume breakdown. The
component volumes in `MSRE.Data.Geometry` were chosen to reproduce the quantities that actually
govern the benchmarked physics — the reported fuel-salt transit times (core 9.56 s, external loop
16.14 s, system 25.63 s at 168 kg/s) — together with documented MSRE hardware dimensions where
those exist (1140 fuel channels, 1.626 m active height, 16 in heat-exchanger shell, 163 tubes,
24.1 m² heat-transfer area). Every one of these is an exposed parameter, and items that are
explicit estimates are marked as such in the record.

Two specific gaps are worth knowing about before using results from this model:

- **Radial power shape.** The paper takes it from a Serpent calculation that is not public. This
  model substitutes a J0 shape with a 25 % reflector saving (radial peak-to-average 1.61). Replace
  `Geometry.f_radial` if the Serpent values become available.
- **`NaturalCirculation` will not run out of the box, by design.** The coolant-salt inlet
  temperature is the forcing function of that transient — everything the benchmark reports is the
  response to that one curve. Inventing the curve and tuning it until the response looks right,
  then presenting the response as agreement, would be circular. The model therefore carries an
  assertion that blocks simulation until `useMeasuredBoundaryCondition` is set and digitized
  measured data is supplied in `coolantInletTable`.

## Key outputs

`MSRE.Systems.PrimarySystem` exposes, among others:

- `rho_CR_pcm` — control rod reactivity in pcm, the measured quantity of the two pump tests.
- `Beta_eff` — effective delayed neutron fraction from paper Eq. 6.
- `tau_core`, `tau_loop` — fuel salt transit times, for comparison against the reported values.

## License

BSD 3-Clause — see [LICENSE](LICENSE).

The Modelica Standard Library and TRANSFORM are separate works under their own
licenses; this repository contains neither and only depends on them.
