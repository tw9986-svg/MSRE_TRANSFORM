within MSRE.Verification;
model Properties_FuelSalt
  "Arithmetic and unit-conversion checks on the four fuel salt property correlations"
  extends Modelica.Icons.Example;

  /* ================================================================
     Unit conversion constants, written out so that they are checkable
     ================================================================ */
  constant Real BTU_LB_F=4186.8 "1 Btu/(lb.degF) in J/(kg.K)";
  constant Real BTU_HR_FT_F=1.730735 "1 Btu/(hr.ft.degF) in W/(m.K)";
  constant Real CAL_G_K=4186.8 "1 cal/(g.K) in J/(kg.K), IT calorie";

  parameter SI.Temperature T_ref=922.0
    "Medium reference temperature, 1200 degF";
  parameter SI.Temperature T_zeroPower=908.0
    "Fuel salt temperature of the zero-power pump tests";

  /* ================================================================
     The four correlations at the two temperatures that matter
     ================================================================ */
  final parameter SI.Density d_922=MSRE.Media.FuelSalt.Utilities.d_T(T_ref);
  final parameter SI.Density d_908=MSRE.Media.FuelSalt.Utilities.d_T(T_zeroPower);
  final parameter SI.DynamicViscosity eta_922=MSRE.Media.FuelSalt.Utilities.eta_T(T_ref);
  final parameter SI.SpecificHeatCapacity cp_922=MSRE.Media.FuelSalt.Utilities.cp_T(T_ref);
  final parameter SI.ThermalConductivity k_922=MSRE.Media.FuelSalt.Utilities.lambda_T(T_ref);

  /* The Prandtl number is the only group cp, mu and k reach the model through. */
  final parameter SIadd.NonDim Pr_922=cp_922*eta_922/k_922
    "Prandtl number at the reference temperature";

  /* ================================================================
     What the docstrings claim, converted independently
     ================================================================ */
  final parameter SI.SpecificHeatCapacity cp_fromImperial=0.47*BTU_LB_F
    "cp_T.mo documents 0.47 Btu/(lb.degF)";
  final parameter Real k_asImperial=k_922/BTU_HR_FT_F
    "The coded thermal conductivity expressed in Btu/(hr.ft.degF)";
  final parameter SI.Temperature T_1200F=(1200.0 - 32.0)*5.0/9.0 + 273.15
    "1200 degF in kelvin; the docstrings' reference point";

  /* ================================================================
     Internal consistency of the medium declaration
     ================================================================ */
  final parameter Real beta_derived(unit="1/K") = 0.513/d_922
    "-1/rho drho/dT at the reference temperature, which is what beta_const must equal";

  /* ================================================================
     A kelvin argument, which is the error the Phase 2 density replaced
     ================================================================ */
  final parameter SI.Density d_922_kelvinArgument=2575.0 - 0.513*T_ref
    "What the same correlation gives if its degC argument is fed kelvin";

  /* ================================================================
     TRANSFORM's own MSRE fuel salt, for comparison only
     ================================================================ */
  final parameter SI.SpecificHeatCapacity cp_TRANSFORM=
      MSRE.Media.MSRE_Properties.cp_TRANSFORM(T_ref);
  final parameter SI.DynamicViscosity eta_TRANSFORM=
      MSRE.Media.MSRE_Properties.eta_TRANSFORM(T_ref);
  final parameter SIadd.NonDim err_cp_TRANSFORM=cp_922/cp_TRANSFORM - 1
    "Relative gap in specific heat against the medium TRANSFORM ships (-17.6 %)";
  final parameter SIadd.NonDim err_eta_TRANSFORM=eta_922/eta_TRANSFORM - 1
    "Relative gap in viscosity against the medium TRANSFORM ships (+11.1 %)";

equation
  /* ---------------- 1. Unit conversions ---------------- */
  assert(abs(cp_fromImperial/cp_922 - 1) < 1e-3, "The specific heat docstring and the coded
constant disagree: 0.47 Btu/(lb.degF) is " + String(cp_fromImperial) + " J/(kg.K) but cp_T
returns " + String(cp_922) + " J/(kg.K).", AssertionLevel.error);

  assert(abs(k_asImperial/0.832 - 1) < 1e-3, "The coded thermal conductivity is " + String(k_922)
     + " W/(m.K), which is " + String(k_asImperial) + " Btu/(hr.ft.degF). It was 0.832 when this
check was written. Note that the value 0.83 often quoted for the MSRE fuel salt converts to
1.4365 W/(m.K), which is NOT the coded constant; the two are 0.24 % apart.",
    AssertionLevel.error);

  assert(abs(T_1200F - T_ref) < 0.05, "1200 degF is " + String(T_1200F) + " K, which should be
the medium reference temperature of " + String(T_ref) + " K. The property docstrings quote
values at 1200 degF, so the two must be the same point.", AssertionLevel.error);

  /* ---------------- 2. The degC argument of the density ---------------- */
  assert(abs(d_922 - 2242.14) < 0.05, "d_T(922 K) is " + String(d_922) + " kg/m3 and should be
2242.14. The correlation is stated on a Celsius argument; feeding it kelvin would give "
     + String(d_922_kelvinArgument) + " kg/m3 instead, which is the mistake the Phase 2 density
change corrected.", AssertionLevel.error);

  assert(abs(d_908 - 2249.3) < 0.05, "d_T(908 K) is " + String(d_908) + " kg/m3 and should be
2249.3, which is the literal carried by Data.Geometry.d_fuel_ref. If this fires, the geometry
record and the medium have drifted apart and every transit time is affected.",
    AssertionLevel.error);

  /* ---------------- 3. beta_const against the density slope ---------------- */
  assert(abs(beta_derived/2.2880e-4 - 1) < 1e-3, "MSRE.Media.FuelSalt declares beta_const =
2.2880e-4 1/K, but -1/rho drho/dT at the reference temperature is " + String(beta_derived) +
    " 1/K. beta_const must follow the density correlation; if d_T is changed, beta_const has to
be changed with it.", AssertionLevel.error);

  /* ---------------- 4. Physical sanity ---------------- */
  assert(d_908 > d_922, "Density must fall with temperature.", AssertionLevel.error);
  assert(MSRE.Media.FuelSalt.Utilities.eta_T(800.0) > MSRE.Media.FuelSalt.Utilities.eta_T(1000.0),
    "Viscosity must fall with temperature.", AssertionLevel.error);
  assert(d_922 > 0 and eta_922 > 0 and cp_922 > 0 and k_922 > 0,
    "All four properties must be positive at the reference temperature.", AssertionLevel.error);

  /* ---------------- 5. The gaps against TRANSFORM, as warnings ----------------
     These are deliberately warnings, not errors. They are not defects to be fixed by editing a
     tolerance; they are the record of a disagreement that is currently unresolved because no
     primary source could be consulted. */
  assert(abs(err_cp_TRANSFORM) < 0.01, "The specific heat differs from the MSRE fuel salt medium
TRANSFORM ships by " + String(100*err_cp_TRANSFORM) + " %. This is expected and is not a defect:
TRANSFORM's MSRE fuel salt uses the pure-FLiBe/coolant value, 0.57 Btu/(lb.degF), for a salt
that is ~15 % denser than the coolant salt, so its specific heat per unit mass should be the
lower of the two rather than equal to it. Recorded so that the disagreement stays visible.
Neither value has been traced to a primary source.", AssertionLevel.warning);

  assert(abs(err_eta_TRANSFORM) < 0.01, "The dynamic viscosity differs from the MSRE fuel salt
medium TRANSFORM ships by " + String(100*err_eta_TRANSFORM) + " %. TRANSFORM's is the generic
FLiBe correlation 0.116e-3*exp(3755/T); the one here, 8.94e-5*exp(4092/T), could not be matched
to any source. This is the least supported of the four correlations and it is the one the
laminar ring-to-ring flow split depends on.", AssertionLevel.warning);

  annotation (
    experiment(StopTime=1),
    Documentation(info="<html>
<h4>What this model checks, and what it cannot</h4>
<p>Every assertion here is <b>parameter-time</b> and needs no solver: the model has no states and
no equations beyond the asserts. What it verifies is that the four correlations in
<a href=\"modelica://MSRE.Media.FuelSalt.Utilities\">FuelSalt.Utilities</a> are arithmetically
what their docstrings say, that the medium's <code>beta_const</code> follows its own density
correlation, and that <code>Data.Geometry.d_fuel_ref</code> has not drifted away from
<code>d_T(908 K)</code>.</p>

<p>It <b>cannot</b> check whether any of the four is the right property for the MSRE fuel salt.
None of them has been traced to a primary source, none has an established valid temperature
range, and Jeong et al. publish none of theirs, so there is nothing here to compare against.
This is verification of arithmetic, not validation of physics, and the distinction is the whole
reason this model sits in <a href=\"modelica://MSRE.Verification\">Verification</a>.</p>

<h4>The two warnings are not failures</h4>
<p>Checks 5a and 5b fire by design. They record the gap against the MSRE fuel salt medium
TRANSFORM ships &mdash; 17.6 % in specific heat and 11.1 % in viscosity &mdash; which is real,
unresolved, and must not be made to disappear by widening a tolerance. The density agrees
exactly, so no assertion is needed for it; that agreement is itself the finding, because it
means this library and TRANSFORM carry the identical density expression.</p>

<h4>Companion script</h4>
<p><code>docs/verification/property_check.py</code> runs the same checks outside Modelica, over
an 800&ndash;1000 K grid rather than at two points, and writes the grid, the comparison against
TRANSFORM and the plots. It was written because no Modelica compiler was available, and it
passes. <b>This model has never been translated or simulated</b> &mdash; see
<code>docs/verification/toolchain_probe.log</code>. Its assertions are stated acceptance
criteria, not observed results.</p>
</html>"));
end Properties_FuelSalt;
