# MSRE TRANSFORM Benchmark Branch Architecture

## 1. Purpose

The repository is organized so that 1-D and 2-D benchmark studies use the same common MSRE property, geometry, pump, heat-exchanger, precursor, and kinetics data. The spatial representation of the core and the transient experiment definition are the intended differences between benchmark branches.

The branch split is therefore by two independent axes:

1. Core representation: 1-D axial vs. 2-D R-Z-equivalent (15 radial rings x 20 axial cells)
2. Experiment class: zero-power forced-circulation transients vs. coupled natural-circulation transient

This prevents geometry/property retuning from being mixed with dimensional-model effects.

---

## 2. Branch structure

```text
main
|
|-- benchmark/1d-zero-power
|-- benchmark/2d-zero-power
|-- benchmark/1d-natural-circulation
`-- benchmark/2d-natural-circulation
```

All four branches start from the same `main` baseline.

---

## 3. Role of `main`

`main` is the common physical/model-data baseline. It should contain only functionality intended to be shared by all benchmark branches.

Common items include:

- `Media/FuelSalt*`
- `Media/CoolantSalt*`
- `Data/Geometry.mo`
- precursor-group data
- kinetics constants and feedback coefficients
- common pump models and pump reference data
- common heat-exchanger geometry and secondary-salt model
- common piping/downcomer/plenum geometry
- common closure relations
- common DNP transport infrastructure
- common benchmark/reference data
- generic verification utilities

### Rule

Do not change a physical property, geometry value, precursor constant, pump parameter, or common HX parameter in only one benchmark branch merely to improve agreement with Jeong/MARS or the MSRE experiment.

If a common value is corrected from a better source, correct it in `main`, document its provenance, and propagate the same change to every benchmark branch.

---

# 4. `benchmark/1d-zero-power`

## Objective

Establish the minimum 1-D MSRE system model for zero-power pump startup/coastdown verification.

The core is represented as one equivalent hydraulic channel group with 20 axial cells:

```text
1 radial group x 20 axial cells
```

The 1140 physical channels are collapsed hydraulically while retaining the physical single-channel hydraulic diameter and total flow area/inventory consistently.

## Development sequence

### Stage 1 - Core thermal-hydraulic verification

Existing starting model:

`Verification/CoreTH_Baseline.mo`

Verify:

- mass conservation
- momentum solution / core pressure drop
- energy conservation
- axial fuel-salt temperature distribution
- consistency of `Q_core = m_flow*(h_out-h_in)` at steady state

The present fixed-power core test is a verification test, not a Jeong zero-power transient benchmark.

### Stage 2 - 1-D zero-power primary system

Create a 1-D system model reusing the common:

- pump
- pump bowl
- piping
- downcomer
- plena
- heat exchanger primary volume
- secondary-side boundary condition

At zero power, the HX remains in the loop because it contributes hydraulic resistance, salt inventory, DNP residence time, and DNP decay. Heat-transfer effects are secondary in this branch.

### Stage 3 - DNP transport and modified point kinetics

Use the common 6-group precursor data and the existing distributed precursor-transport approach.

The 1-D core precursor field is:

`C_i(z,t)`

The fluid system solves precursor advection and decay throughout the entire primary loop. The kinetics model receives the core precursor inventory and computes the effective delayed-neutron source.

For zero-power pump tests, use the ideal flux-servo mode so neutron population/power is held constant and the required compensating control-rod reactivity is reported.

### Stage 4 - Pump transient benchmark

Cases:

- pump startup
- pump coastdown

Primary comparison quantities:

- pump speed `N_pump(t)`
- primary mass flow `m_flow(t)`
- core transit time
- external-loop transit time
- total circulation time
- precursor-group response
- servo/circulation reactivity `rho_servo(t)`

Comparison hierarchy:

```text
TRANSFORM 1-D
    vs.
Jeong/MARS
    vs.
MSRE experimental data
```

## Branch completion condition

The branch is considered complete only when the 1-D hydraulic/DNP model can reproduce and quantitatively compare both startup and coastdown responses without benchmark-specific retuning of the shared geometry/property baseline.

---

# 5. `benchmark/2d-zero-power`

## Objective

Evaluate the effect of radial spatial resolution on the zero-power DNP circulation-reactivity prediction.

Core representation:

```text
15 radial rings x 20 axial cells
```

Current starting component:

`Components/ReactorCore.mo`

## Stage 1 - 2-D/R-Z-equivalent hydraulic audit

Before kinetics comparison, verify:

- sum of ring flows equals total core flow
- per-ring pressure drop
- per-ring Reynolds number
- radial flow split
- consistency of channel count weighting

The current existence of 15 parallel rings does not by itself establish a physical radial flow distribution. If all rings have identical geometry and form-loss coefficients, the model may remain hydraulically equivalent to repeated 1-D channels.

Therefore distinguish explicitly between:

1. Jeong nodalization reproduction
2. physically justified radial hydraulic redistribution

Do not introduce radial loss coefficients merely to create a desired radial profile.

## Stage 2 - Power/source-domain audit

Verify:

- `sum(SF_core) = 1`
- `sum(Qs_core) = Q_fission`
- channel source distribution follows the intended radial/axial benchmark definition

Keep separate concepts for:

- cells included in DNP/kinetics inventory
- cells that physically generate fission power

Plenum cells may participate in precursor inventory/transport without automatically receiving fission power.

## Stage 3 - 2-D DNP transport

The spatial precursor field becomes:

`C_i(r,z,t)`

Use the same precursor constants, loop volumes, pump transient, and servo-kinetics logic as the 1-D branch.

## Stage 4 - Pump startup/coastdown benchmark

Run the same transient definitions as `benchmark/1d-zero-power`.

Primary research comparison:

```text
rho_1D(t) vs. rho_2D(t)
```

and identify whether any difference is caused by:

- radial source distribution
- radial precursor distribution
- radial flow redistribution
- weighting/importance assumptions

## Branch completion condition

The 2-D branch is complete when the spatial-model effect can be isolated from changes in common input data and compared against Jeong/MARS and MSRE experiment using the same transient definitions as the 1-D branch.

---

# 6. Natural circulation branches

Natural circulation is intentionally separated from the zero-power pump-transient branches because the driving physics is different.

Forced-circulation zero-power test:

```text
pump speed -> pump head -> mass flow -> DNP transport -> circulation reactivity
```

Natural circulation test:

```text
power/heat removal -> temperature -> density distribution
-> buoyancy head -> mass flow
-> DNP transport + temperature feedback
-> neutron power
```

Thus natural circulation is a coupled thermal-hydraulic/neutronic validation problem rather than only a DNP-flow benchmark.

---

# 7. `benchmark/1d-natural-circulation`

## Starting point

Start only after the zero-power 1-D branch has established a stable common primary-loop hydraulic/DNP model.

## Required activated physics

- dynamic energy equation
- volumetric fission heat generation
- primary-to-secondary HX heat transfer
- secondary cooling boundary/input
- temperature-dependent salt density
- gravity/elevation head
- friction/form losses
- dynamic point kinetics
- DNP transport
- fuel temperature reactivity feedback
- graphite feedback if/when supported by the selected benchmark model

Pump head is removed or brought to the experimental natural-circulation condition.

## Primary outputs

- `P(t)`
- primary-loop `m_flow(t)`
- core inlet/outlet temperature
- HX primary inlet/outlet temperature
- relevant secondary-side temperature
- total/individual reactivity contributions
- DNP response

## Purpose

Determine whether the 1-D system predicts the measured coupled power-temperature-flow natural-circulation response.

---

# 8. `benchmark/2d-natural-circulation`

## Objective

Use the validated 2-D core representation in the coupled natural-circulation test and determine whether radial resolution materially changes the predicted system response.

Use the same natural-circulation experiment inputs and common data as the 1-D natural-circulation branch.

Additional outputs:

- radial/axial fuel-salt temperature distribution
- radial DNP distribution
- radial flow distribution
- local density distribution relevant to buoyancy

Primary comparison:

```text
1-D natural circulation
       vs.
2-D natural circulation
       vs.
Jeong/MARS / MSRE experiment
```

This branch is the final test of whether added core spatial resolution produces a meaningful improvement in a fully coupled transient rather than only adding computational cost.

---

# 9. Mandatory comparison-control rules

For every 1-D vs. 2-D comparison, keep the following identical unless the research question explicitly studies the parameter itself:

- fuel-salt property correlations
- coolant-salt properties
- physical core dimensions
- total channel count
- primary-loop inventory definition
- pump model and pump transient input
- HX geometry
- pipe/downcomer/plenum geometry
- precursor `beta_i` and `lambda_i`
- prompt generation time
- initial operating condition
- experiment input histories
- numerical acceptance metrics

The intended independent variable is the spatial core representation.

---

# 10. V&V hierarchy

Use three separate levels of evidence.

## Verification

Does the implementation solve the intended equations correctly?

Examples:

- mass balance
- energy balance
- source normalization
- precursor conservation
- flow-split sum
- analytical residence-time checks

## Benchmark comparison

Does TRANSFORM reproduce the corresponding Jeong/MARS model response when given comparable inputs?

## Validation

Does the model reproduce the MSRE experimental response within documented uncertainty/limitations?

Do not describe agreement with Jeong/MARS alone as experimental validation.

---

# 11. Recommended research sequence

```text
COMMON BASELINE
Properties + Geometry + common components
          |
          v
1-D Core TH Verification
          |
          v
1-D Zero-Power Primary Loop
          |
          v
1-D DNP + Point Kinetics
          |
          v
1-D Pump Startup / Coastdown V&V
          |
          v
2-D Hydraulic + Source Audit
          |
          v
2-D DNP Startup / Coastdown V&V
          |
          v
1-D vs. 2-D Zero-Power Assessment
          |
          v
1-D Coupled Natural Circulation
          |
          v
2-D Coupled Natural Circulation
          |
          v
Final 1-D vs. 2-D Coupled Assessment
```

Natural circulation is therefore not removed from the project. It is deliberately placed after the forced-circulation DNP benchmarks because it requires the additional power-temperature-density-buoyancy feedback loop to be validated.
