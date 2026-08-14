within MSRE.Verification;
model Steady_LoopBalance
  "Check that the closed loop and the 15 parallel rings are hydraulically consistent at rated flow"
  extends Modelica.Icons.Example;

  parameter SI.Time t_settle=300 "Time allowed for the loop hydraulics to reach steady state";
  parameter SI.Power Q_start=100 "Reactor power (near zero power, as in the pump tests)";
  parameter SI.Temperature T_start=908 "Isothermal fuel salt temperature";
  parameter Real N_rated(unit="1/min") = 1160 "Rated fuel pump speed";
  parameter SI.MassFlowRate m_flow_rated=168 "Rated fuel salt mass flow rate";

  /* ---------------- Tolerances ---------------- */
  parameter SI.MassFlowRate tol_massBalance=1e-3
    "Allowed difference between the pump flow and the core flow at steady state, about 6e-6 of rated";
  parameter SIadd.NonDim tol_flowSplit=1e-4
    "Allowed relative departure from an even split between hydraulically identical rings";
  parameter SI.Length tol_closure=1e-9 "Allowed elevation mismatch around the loop";
  parameter SI.Time tol_tau=0.15 "Allowed deviation of the system transit time [s]";
  parameter SIadd.NonDim tol_flow=0.10
    "Allowed relative deviation of the rated flow rate delivered by the pump characteristic";
  parameter SIadd.NonDim Re_laminar=2300
    "Upper Reynolds number of the laminar correlation used for the fuel channels";

  MSRE.Systems.PrimarySystem msre(
    redeclare package Medium_fuel = MSRE.Media.FuelSalt_U235,
    redeclare record Data_PG = MSRE.Data.PrecursorGroups.U235_6group,
    redeclare record Data_K = MSRE.Data.Kinetics_U235,
    Q_fission_start=Q_start,
    T_start=T_start,
    t_null=t_settle,
    use_servoControl=true,
    m_flow_start=m_flow_rated,
    N_pump_start=N_rated,
    T_coolant_start=T_start) "MSRE primary system, held at rated pump speed throughout"
    annotation (Placement(transformation(extent={{-20,-20},{20,20}})));

  Modelica.Blocks.Sources.RealExpression pumpSpeed(y=N_rated)
    "Fuel pump held at its rated speed for the whole run"
    annotation (Placement(transformation(extent={{80,-10},{56,10}})));
  Modelica.Blocks.Sources.RealExpression coolantTemperature(y=T_start)
    "Coolant salt inlet temperature, isothermal"
    annotation (Placement(transformation(extent={{80,30},{56,50}})));

  /* ---------------- Reported quantities ---------------- */
  SIadd.NonDim Re_max=max(msre.Re_rings) "Largest channel Reynolds number over the 15 rings";
  SI.MassFlowRate m_flow_min=min(msre.m_flows_rings)
    "Smallest ring flow rate; negative means a ring has reversed";

equation
  /* ---- 1. Elevation closure. A closed loop cannot have a net elevation rise, and if it does
        the buoyancy term becomes a spurious pump that the natural circulation test would then
        be fitted against. This is a parameter-time check. ---- */
  assert(abs(msre.geometry.dz_closure) < tol_closure, "The elevation rises around the primary
loop sum to " + String(msre.geometry.dz_closure) + " m instead of zero. A closed loop with a
net elevation rise has a spurious buoyancy source in it. Check MSRE.Data.Geometry: dz_downcomer
is meant to be the final parameter that closes the loop.", AssertionLevel.error);

  /* ---- 2. Transit times, which are the quantities the geometry was calibrated to and the
        only thing paper Eq. 8 depends on. ---- */
  assert(abs(msre.geometry.tau_system_nominal - 25.63) < tol_tau, "The system transit time of
the geometry is " + String(msre.geometry.tau_system_nominal) + " s against the 25.63 s the
paper reports. The core volume comes from published channel hardware and the density from
ORNL-TM-4865, so neither is free; only V_downcomer is, and it is what absorbs the balance of
the loop inventory. A deviation means one of those three has been changed without the others
being re-derived. See MSRE.Verification.Properties_TransitTime.", AssertionLevel.error);

  when terminal() then
    /* ---- 3. Loop mass balance. The pump and the core are in series, so at steady state they
          must pass the same flow. This is the check that the loop is actually closed and that
          no boundary condition is quietly feeding or draining it. ---- */
    assert(abs(msre.err_loopMassBalance) < tol_massBalance, "At steady state the fuel pump
passes " + String(msre.m_flow_pump) + " kg/s but the core passes " + String(msre.m_flow_fuel) +
      " kg/s. These are in series and must agree; the difference means the expansion tank is
exchanging mass with the loop, which it should only do to take up thermal expansion.",
      AssertionLevel.error);

    /* ---- 4. Flow split between the parallel rings. With every ring given identical geometry,
          zero form losses and an isothermal core, the split must be even to solver tolerance.
          This is the real test of the parallel connection: if the plena did not expose their
          state, or if the rings did, this is where it would show. ---- */
    assert(msre.err_flowSplit < tol_flowSplit, "The 15 fuel channel rings are hydraulically
identical here, but the flow split departs from 1/15 by " + String(100*msre.err_flowSplit) +
      " %. Either MSRE.Data.Geometry.K_channelInlet/K_channelExit have been given non-zero
values, or the core is not isothermal, or the parallel connection in
MSRE.Components.ReactorCore is not well posed.", AssertionLevel.error);

    /* ---- 5. No ring may reverse. A reversed ring is physically possible in a parallel array
          but not at rated forced flow, and it would silently corrupt the precursor transport
          because the reversed ring would carry precursors backwards into the lower plenum. ---- */
    assert(m_flow_min > 0, "Ring flow rates at steady state include " + String(m_flow_min) +
      " kg/s, i.e. at least one of the 15 rings has reversed at rated forced circulation. The
precursor transport solution is not trustworthy in that state.", AssertionLevel.error);

    /* ---- 6. Delivered flow. Unlike the checks above this one is not structural: it tests
          whether the form losses in MSRE.Data.Geometry are calibrated so that the pump
          characteristic actually delivers the rated flow at the rated speed. ---- */
    assert(abs(msre.m_flow_fuel - msre.geometry.m_flow_nominal)/msre.geometry.m_flow_nominal
       < tol_flow, "At the rated pump speed the loop settles at " + String(msre.m_flow_fuel) +
      " kg/s instead of " + String(msre.geometry.m_flow_nominal) + " kg/s. The pump
characteristic and the loop form losses (K_pumpInlet, K_pumpExit, K_loop) are calibrated
against each other; adjust K_loop until the rated point is recovered.", AssertionLevel.warning);

    /* ---- 7. Flow regime. The fuel channels are laminar at rated flow and the whole argument
          that the ring flow split responds linearly to the viscosity depends on that. ---- */
    assert(Re_max < Re_laminar, "The largest channel Reynolds number is " + String(Re_max) +
      ", above the laminar limit of " + String(Re_laminar) + ". The fuel channels are expected
to be laminar at every flow rate in these tests (about 855 at rated flow); above the transition
the friction correlation changes form and the ring flow split no longer responds linearly to
the salt viscosity.", AssertionLevel.warning);
  end when;

  annotation (
    experiment(
      StopTime=300,
      __Dymola_NumberOfIntervals=3000,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>What is being checked</h4>
<p>Adding 15 parallel branches to a closed loop introduces failure modes that do not announce
themselves: a branch can reverse, the split can drift, the loop can fail to close, and the
model will still integrate and produce plausible looking reactivity curves. This model runs the
primary system at rated pump speed and asserts the things that must hold if the hydraulics are
solved correctly.</p>

<table border=\"1\">
<tr><th>#</th><th>Check</th><th>Why it can fail</th><th>Level</th></tr>
<tr><td>1</td><td>elevation rises sum to zero</td>
    <td>an edited <code>dz_</code> leaves a net rise, which acts as a buoyancy source</td>
    <td>error</td></tr>
<tr><td>2</td><td>system transit time is 25.63 s</td>
    <td>a volume or the reference density was changed without re-deriving the other</td>
    <td>error</td></tr>
<tr><td>3</td><td>pump flow equals core flow</td>
    <td>the expansion tank is exchanging mass with the loop</td><td>error</td></tr>
<tr><td>4</td><td>the 15 rings split the flow evenly</td>
    <td>the parallel connection is not well posed, or a form loss was set</td><td>error</td></tr>
<tr><td>5</td><td>no ring has reversed</td>
    <td>a reversed ring carries precursors backwards into the lower plenum</td><td>error</td></tr>
<tr><td>6</td><td>the loop settles at 168 kg/s</td>
    <td>the loop form losses are no longer calibrated against the pump curve</td>
    <td>warning</td></tr>
<tr><td>7</td><td>the channels are laminar</td>
    <td>above Re = 2300 the friction correlation changes form</td><td>warning</td></tr>
</table>

<h4>Which of these are verification and which are calibration</h4>
<p>Checks 1 and 3 to 5 are verification in the strict sense: they compare the solution against
something that must be true of any correct solution, and no input can be chosen to make a
failure go away. Check 2 tests a calibration against the number it was calibrated to, which is
weaker but still catches the common failure of editing one volume in isolation. Check 6 is a
calibration check and is therefore only a warning: the form losses are estimates, and the value
they were tuned to is the rated point itself.</p>

<h4>Status</h4>
<p>Not yet run. No Modelica compiler was available in the environment where this model was
written, so the tolerances above are stated acceptance criteria, not observed results.</p>

<p><code>tol_flowSplit</code> and <code>tol_massBalance</code> are set two orders of magnitude
above the solver tolerance of 1e-6 rather than at it, because the rings are not quite exactly
symmetric even here: the radial peaking factors give each ring a slightly different power, so
at 100 W the rings differ in temperature by something like 0.4 microkelvin, which through the
viscosity biases the split by about 1e-9. That is far below either tolerance, so what these two
numbers actually have to sit above is solver noise, not physics.</p>

<p>Check 6 is the one that may genuinely fail on first run: it compares the delivered flow
against the rated point, and the loop form losses have never been exercised against the pump
characteristic in a solver. It is a warning for that reason.</p>
</html>"));
end Steady_LoopBalance;
