within MSRE.Experiments;
model NaturalCirculation "MSRE natural circulation test (paper Section 4.3)"
  extends TRANSFORM.Icons.Example;

  parameter SI.Time t_null=5000
    "Null transient that establishes the initial natural circulation steady state (5000 s in the paper)";
  parameter SI.Power Q_start=8000 "Initial reactor power (8.0 kW; case C3 of the paper uses 4 kW)";
  parameter SI.Temperature T_start=922 "Initial fuel salt temperature";
  parameter SI.Temperature T_coolant_start=894
    "Coolant salt temperature at the heat exchanger inlet at the start of the transient";

  parameter Boolean useMeasuredBoundaryCondition=false
    "Set true only when coolantInletTable holds digitized measured data. Guards against reporting a tuned result as agreement"
    annotation (Dialog(group="Secondary side boundary condition"));

  parameter Real coolantInletTable[:,2]=[0,0]
    "Change of the coolant salt inlet temperature [s, K] relative to T_coolant_start. Default is a null forcing function: nothing happens until measured data is supplied"
    annotation (Dialog(group="Secondary side boundary condition"));

  MSRE.Systems.PrimarySystem msre(
    redeclare package Medium_fuel = MSRE.Media.FuelSalt_U233,
    redeclare record Data_PG = MSRE.Data.PrecursorGroups.U233_6group,
    redeclare record Data_K = MSRE.Data.Kinetics_U233,
    Q_fission_start=Q_start,
    T_start=T_start,
    t_null=t_null,
    use_servoControl=false,
    m_flow_start=1.5,
    T_coolant_start=T_coolant_start) "MSRE primary system"
    annotation (Placement(transformation(extent={{-20,-20},{20,20}})));

  Modelica.Blocks.Sources.RealExpression pumpSpeed(y=0)
    "The fuel pump is stopped throughout this test"
    annotation (Placement(transformation(extent={{80,-10},{56,10}})));

  Modelica.Blocks.Tables.CombiTable1Dv coolantStep(
    table=coolantInletTable,
    smoothness=Modelica.Blocks.Types.Smoothness.LinearSegments,
    extrapolation=Modelica.Blocks.Types.Extrapolation.HoldLastPoint)
    "Stepwise increase of the heat removal, expressed as the coolant inlet temperature change"
    annotation (Placement(transformation(extent={{40,60},{24,76}})));
  Modelica.Blocks.Sources.RealExpression transientTime(y=max(0, time - t_null))
    "Time since the start of the transient"
    annotation (Placement(transformation(extent={{80,58},{56,78}})));
  Modelica.Blocks.Sources.RealExpression coolantTemperature(y=T_coolant_start + coolantStep.y[1])
    "Coolant salt inlet temperature"
    annotation (Placement(transformation(extent={{80,30},{56,50}})));

equation
  assert(useMeasuredBoundaryCondition, "
MSRE.Experiments.NaturalCirculation has no measured boundary condition and will
not run until one is supplied.

The coolant salt inlet temperature is the forcing function of this transient.
Everything the benchmark reports - the power rising from 8 kW to about 354 kW,
the flow going from 1.46 to 4.45 kg/s, the roughly 4 K fall of the average fuel
temperature - is the response to that one curve. Inventing the curve and tuning
it until the response looks right, then presenting the response as agreement, is
circular. This assertion exists so that cannot happen by accident.

To run the case:
  1. Digitize the measured coolant salt temperature at the heat exchanger inlet
     from ORNL-4396 (Ref. [33] of the paper), or take it from a benchmark
     specification that already tabulates it.
  2. Convert degF to K:  T[K] = (T[degF] - 32)/1.8 + 273.15
  3. Set T_coolant_start to the measured value at the start of the transient.
  4. Fill coolantInletTable with [time since transient start, T - T_coolant_start],
     covering 0 to at least 21000 s.
  5. Set useMeasuredBoundaryCondition = true.

Be aware that the hydraulics carry their own unconstrained inputs: the roughly
2 m thermal-centre elevation difference, the pump form losses, and the shell-side
heat transfer coefficient at very low flow. The geometry in MSRE.Data.Geometry is
calibrated to the reported transit times, which constrains precursor drift but
not buoyancy or friction. Agreement of the flow history is therefore weaker
evidence than agreement of the reactivity in the pump tests.

MSRE.Verification runs without any measured data and is the right place to look
for checks this model can actually pass on its own.
", AssertionLevel.error);

  connect(pumpSpeed.y, msre.N_pump) annotation (Line(points={{54.8,0},{40,0},{40,4},{22,4}},
        color={0,0,127}));
  connect(transientTime.y, coolantStep.u[1])
    annotation (Line(points={{54.8,68},{41.6,68}}, color={0,0,127}));
  connect(coolantTemperature.y, msre.T_coolant_in)
    annotation (Line(points={{54.8,40},{46,40},{46,14},{22,14}}, color={0,0,127}));

  annotation (
    experiment(
      StopTime=26000,
      __Dymola_NumberOfIntervals=5200,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>Test description (paper Section 4.3)</h4>
<p>The most demanding of the three tests, because neutronics and thermal hydraulics are fully
coupled. The reactor runs on U-233 with the fuel pump stopped, at an initial power of 8.0 kW
and a natural-circulation flow that the paper's MARS model predicts to be about 1.46 kg/s, that
is 1 to 2 mm/s in the core channels. The control rods stay fixed. The coolant flow is held at
its rated value while the heat removal through the radiator is increased in steps at 0, 1200,
4500, 8400 and 11700 s. The fuel salt cools, natural circulation strengthens, the negative
temperature coefficients insert positive reactivity, and the power rises to about 354 kW at
21000 s.</p>

<h4>How the model reproduces it</h4>
<ul>
<li><code>use_servoControl = false</code>, so the neutron balance of paper Eq. 1 is solved with
the temperature feedback of paper Eq. 5 acting through the flux-weighted fuel and graphite
temperatures.</li>
<li>The pump speed is zero throughout, so
<a href=\"modelica://MSRE.Components.FuelPump\">FuelPump</a> degenerates into a form loss and
the flow is driven entirely by buoyancy over the roughly 2 m between the thermal centres of
the core and of the heat exchanger.</li>
<li>The null transient of 5000 s reproduces the procedure of the paper: the flow and the
precursor distribution converge at the initial secondary-side boundary condition, then
<code>Beta_eff</code> and the feedback reference temperatures are frozen. This is what makes
the reactivity depend only on the temperature <i>change</i>, so that the well-known offset in
the absolute initial temperatures does not distort the transient, exactly as the paper argues
for its own results.</li>
</ul>

<h4>This model is not validated, and will not run until you make it so</h4>
<p>The paper imposes the <b>measured</b> coolant-salt temperature at the secondary side of the
heat exchanger, taken from ORNL-4396 (its Ref. [33]). That curve is not reproduced here, and
no substitute for it is shipped.</p>

<p>An earlier version of this model carried an invented table whose step magnitudes had been
chosen so that the predicted power came out near the reported value. That is circular: the
coolant inlet temperature is the <i>forcing function</i> of this transient, so tuning it until
the response matches and then quoting the response as agreement proves nothing. The table now
defaults to <code>[0,0]</code>, a null forcing function under which nothing happens, and
<code>useMeasuredBoundaryCondition</code> must be set explicitly before the model will
translate. The assertion carries the instructions.</p>

<p>Two further inputs are unconstrained even with the right boundary condition: the
thermal-centre elevation difference of roughly 2 m and the pump form losses, which set the
natural-circulation flow, and the shell-side heat transfer coefficient at very low flow, which
the paper itself identifies as the decisive uncertainty. The geometry is calibrated to the
reported transit times; that pins the precursor drift and nothing else. Read any agreement in
the flow history with that in mind.</p>

<p>For checks that need no measured data at all, see
<a href=\"modelica://MSRE.Verification\">MSRE.Verification</a>.</p>

<h4>Acceptance targets once measured data is in place</h4>
<table border=\"1\">
<tr><th>Variable</th><th>Paper figure</th><th>Paper result</th></tr>
<tr><td><code>msre.T_coreOutlet</code>, <code>msre.T_coreInlet</code></td><td>Fig. 9</td>
<td>trend well reproduced; the absolute values differ from the measurement because the
experimental initial condition was not in thermal equilibrium</td></tr>
<tr><td><code>msre.m_flow_fuel</code></td><td>Fig. 10</td>
<td>1.46 kg/s at 0 s, 4.45 kg/s at 21000 s</td></tr>
<tr><td><code>msre.Q_core</code></td><td>Fig. 11</td>
<td>304.5 kW predicted at 21000 s against about 354 kW measured</td></tr>
</table>

<p>The paper's own analysis of the balance of effects is a good check on this model: over the
transient the flow change alone accounts for only about 5.8 pcm of extra drift loss
(<code>MSRE.Functions.driftReactivity</code> evaluated at the two flow rates gives 0.9 pcm and
6.7 pcm), whereas the roughly 4 K fall of the average fuel temperature is worth about 60 pcm.
The transient is therefore driven by the temperature feedback, with the precursor drift playing
a secondary role.</p>

<h4>Sensitivity cases of the paper</h4>
<ul>
<li>C1, 10% larger heat exchanger area: <code>msre.geometry.f_area_hx = 1.10</code>.</li>
<li>C2, reduced pump form losses: <code>msre.geometry.K_pumpInlet = 0.5</code> and
<code>msre.geometry.K_pumpExit = 0.5</code>.</li>
<li>C3, initial power 4 kW: <code>Q_start = 4000</code>.</li>
<li>C4, no graphite feedback: <code>msre.data_K.alpha_graphite = 0</code>.</li>
</ul>
<p>The paper concludes that heat removal on the secondary side dominates this test and that the
shell-side heat transfer coefficient at low flow is the decisive uncertainty. In this model that
uncertainty was concentrated in <code>msre.geometry.Nu_floor_shell</code> and
<code>msre.geometry.f_shellHT</code>. <b>Both are now LEGACY/DEPRECATED and connected to
nothing:</b> the heat exchanger uses plain Gnielinski
(<a href=\"modelica://MSRE.ClosureRelations.Nus_MoltenSalt\">Nus_MoltenSalt</a>) and the core
channels, which are laminar even at rated flow, use
<a href=\"modelica://MSRE.ClosureRelations.Nus_Core\">Nus_Core</a> - a generic laminar
constant below Re 2300 blending into Gnielinski above 3000. Neither carries a multiplier or a
Nusselt floor, so the shell-side coefficient at rated flow is about 1812 W/(m2.K) against the
22450 the calibrated closure gave, and this experiment should be expected to behave
differently until the shell-side geometry (O-16) and the duct-shape laminar correction
(O-19 residual) are settled</p>
</html>"));
end NaturalCirculation;
