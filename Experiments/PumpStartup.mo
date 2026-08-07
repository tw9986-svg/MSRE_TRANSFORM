within MSRE.Experiments;
model PumpStartup "MSRE pump startup test (paper Section 4.1)"
  extends TRANSFORM.Icons.Example;

  parameter SI.Time t_null=600
    "Null transient that builds the stagnant precursor distribution before the pump starts";
  parameter SI.Time tau_startup=3.4
    "Time constant of the pump speed rise; 3.4 s brings the flow to the rated value in about 10 s";
  parameter SI.Power Q_start=100 "Reactor power during the test (near zero power)";
  parameter SI.Temperature T_start=908 "Isothermal fuel salt temperature of the test";
  parameter Real N_rated(unit="1/min") = 1160 "Rated fuel pump speed";

  MSRE.Systems.PrimarySystem msre(
    redeclare package Medium_fuel = MSRE.Media.FuelSalt_U235,
    redeclare record Data_PG = MSRE.Data.PrecursorGroups.U235_6group,
    redeclare record Data_K = MSRE.Data.Kinetics_U235,
    Q_fission_start=Q_start,
    T_start=T_start,
    t_null=t_null,
    use_servoControl=true,
    m_flow_start=0,
    T_coolant_start=T_start) "MSRE primary system"
    annotation (Placement(transformation(extent={{-20,-20},{20,20}})));

  Modelica.Blocks.Sources.RealExpression pumpSpeed(y=if time < t_null then 0 else N_rated*(1
         - exp(-(time - t_null)/tau_startup))) "Fuel pump speed law"
    annotation (Placement(transformation(extent={{80,-10},{56,10}})));
  Modelica.Blocks.Sources.RealExpression coolantTemperature(y=T_start)
    "Coolant salt inlet temperature, isothermal during this test"
    annotation (Placement(transformation(extent={{80,30},{56,50}})));

  /* ---------------- Comparison with the analytic result of paper Eq. 8 ---------------- */
  final parameter SIadd.NonDim drho_analytic=MSRE.Functions.driftReactivity(
      msre.data_PG.alphas*msre.data_PG.Beta,
      msre.data_PG.lambdas,
      9.56,
      16.14) "Analytic asymptotic drift reactivity at the transit times reported in the paper";
  final parameter Real drho_analytic_pcm=1e5*drho_analytic
    "Analytic asymptotic drift reactivity [pcm], 228.4 pcm in the paper";

equation
  connect(pumpSpeed.y, msre.N_pump) annotation (Line(points={{54.8,0},{40,0},{40,4},{22,4}},
        color={0,0,127}));
  connect(coolantTemperature.y, msre.T_coolant_in)
    annotation (Line(points={{54.8,40},{40,40},{40,14},{22,14}}, color={0,0,127}));

  annotation (
    experiment(
      StopTime=750,
      __Dymola_NumberOfIntervals=7500,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>Test description (paper Section 4.1)</h4>
<p>The reactor is held at about 100 W and 908 K, so thermal feedback is negligible, and both
the fuel and the coolant pump are initially at rest. The fuel pump is started at
<code>t_null</code> and brings the flow to its rated value in about 10 s. Throughout the
transient the flux servo controller moves the control rods to keep the reactor critical, so
the measured rod reactivity is exactly the reactivity change caused by the fuel flow.</p>

<h4>How the model reproduces it</h4>
<ul>
<li><code>use_servoControl = true</code> holds the neutron population constant and reports the
required rod reactivity through paper Eq. 7, available as
<code>msre.rho_CR_pcm</code>.</li>
<li>A null transient of <code>t_null</code> seconds with the pump stopped builds the stagnant
precursor distribution: precursors accumulate in the core and there are none in the loop, which
is the initial condition the paper describes. 600 s is about eleven half-lives of the
longest-lived group, so the distribution is fully converged. <code>Beta_eff</code> is then
frozen at the stagnant value, which must come out as the total delayed fraction 0.006781.</li>
<li>The pump <b>speed</b> is prescribed, not the flow; the flow follows from the loop momentum
balance, so the transit time that drives the whole effect is a model result.</li>
</ul>

<h4>What to plot, and what the paper reports</h4>
<table border=\"1\">
<tr><th>Variable</th><th>Paper figure</th><th>Paper result</th></tr>
<tr><td><code>msre.m_flow_fuel_norm</code> vs <code>msre.t_rel</code></td><td>Fig. 4</td>
<td>rated flow reached in about 10 s</td></tr>
<tr><td><code>msre.rho_CR_pcm</code> vs <code>msre.t_rel</code></td><td>Figs. 5 and 6</td>
<td>227.3 pcm measured / 222.4 pcm MARS, averaged over 25 to 45 s;
oscillation period about 25.5 s; asymptote 226.5 pcm</td></tr>
<tr><td><code>msre.Beta_eff</code></td><td>Eq. 6</td><td>0.006781 at stagnant conditions</td></tr>
<tr><td><code>msre.tau_core</code>, <code>msre.tau_loop</code></td><td>Section 4.1.2</td>
<td>9.56 s and 16.14 s at rated flow</td></tr>
</table>

<p>The oscillations in the rod reactivity are the physical signature the paper emphasises: the
long-lived precursors created in the core before the pump started re-enter the core once per
system transit time, so the reactivity oscillates with a period equal to that transit time and
the oscillation decays away. Because the control rod motion is not modelled explicitly, the
reactivity overshoot seen in the experiment around 15 s does not appear here either, exactly
as the paper notes for MARS.</p>

<p><code>drho_analytic_pcm</code> evaluates paper Eq. 8 at the transit times reported in the
paper and should agree with the asymptotic value of <code>msre.rho_CR_pcm</code> to within a
few pcm.</p>

<h4>Sensitivity cases of the paper</h4>
<ul>
<li>Faster pump (moment of inertia halved): set <code>tau_startup = 1.7</code>.</li>
<li>Extended core volume: increase <code>msre.geometry.V_upperPlenum</code> and reduce
<code>msre.geometry.V_downcomer</code> by the same amount, which lengthens the core transit
time and shortens the loop transit time and, as the paper shows, reduces the reactivity
loss.</li>
</ul>
</html>"));
end PumpStartup;
