within MSRE.Experiments;
model PumpCoastdown "MSRE pump coastdown test (paper Section 4.2)"
  extends TRANSFORM.Icons.Example;

  parameter SI.Time t_null=600
    "Null transient at rated flow, which establishes the circulating precursor distribution";
  parameter SI.Time tau_coast=4.0
    "Pump coastdown time constant, J*omega_nominal/tau_hydraulic_nominal";
  parameter SI.Power Q_start=100 "Reactor power during the test (near zero power)";
  parameter SI.Temperature T_start=908 "Isothermal fuel salt temperature of the test";
  parameter SI.MassFlowRate m_flow_rated=168 "Rated fuel salt flow rate before the trip";
  parameter Real N_rated(unit="1/min") = 1160 "Rated fuel pump speed";

  MSRE.Systems.PrimarySystem msre(
    redeclare package Medium_fuel = MSRE.Media.FuelSalt_U235,
    redeclare record Data_PG = MSRE.Data.PrecursorGroups.U235_6group,
    redeclare record Data_K = MSRE.Data.Kinetics_U235,
    Q_fission_start=Q_start,
    T_start=T_start,
    t_null=t_null,
    use_servoControl=true,
    m_flow_start=m_flow_rated,
    N_pump_start=N_rated,
    T_coolant_start=T_start) "MSRE primary system"
    annotation (Placement(transformation(extent={{-20,-20},{20,20}})));

  Modelica.Blocks.Sources.RealExpression pumpSpeed(y=if time < t_null then N_rated else
        N_rated/(1 + (time - t_null)/tau_coast))
    "Fuel pump speed law: inertial coastdown against a quadratic hydraulic torque"
    annotation (Placement(transformation(extent={{80,-10},{56,10}})));
  Modelica.Blocks.Sources.RealExpression coolantTemperature(y=T_start)
    "Coolant salt inlet temperature, isothermal during this test"
    annotation (Placement(transformation(extent={{80,30},{56,50}})));

equation
  connect(pumpSpeed.y, msre.N_pump) annotation (Line(points={{54.8,0},{40,0},{40,4},{22,4}},
        color={0,0,127}));
  connect(coolantTemperature.y, msre.T_coolant_in)
    annotation (Line(points={{54.8,40},{40,40},{40,14},{22,14}}, color={0,0,127}));

  annotation (
    experiment(
      StopTime=800,
      __Dymola_NumberOfIntervals=8000,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>Test description (paper Section 4.2)</h4>
<p>The inverse of the startup test. The reactor is again at about 100 W and 908 K, the fuel
pump is running at the rated 168 kg/s, and at <code>t_null</code> it is tripped. As the flow
decays the precursors spend longer inside the core, the effective delayed neutron fraction
recovers towards the static value and positive reactivity is inserted, which the control rods
must cancel.</p>

<h4>How the model reproduces it</h4>
<ul>
<li>The null transient runs at rated flow, so the frozen <code>Beta_eff</code> is the
<i>circulating</i> value. With the transit times of this model that is about 0.00452, roughly
two thirds of the static 0.006781, and the difference is the 227 pcm of drift reactivity.</li>
<li>The prescribed speed law <code>N = N_0/(1 + t/tau_coast)</code> is the exact solution of
the pump angular momentum equation <code>J*dw/dt = -tau_hyd*(w/w_n)^2</code>, so
<code>tau_coast</code> is the model's counterpart of the pump moment of inertia that the paper
tunes: <code>tau_coast = J*omega_nominal/tau_hydraulic_nominal</code>. Halving the moment of
inertia means halving <code>tau_coast</code>.</li>
<li>The flow itself is not prescribed; it follows from the loop momentum balance with the idle
pump acting as a form loss.</li>
</ul>

<h4>What to plot, and what the paper reports</h4>
<table border=\"1\">
<tr><th>Variable</th><th>Paper figure</th><th>Paper result</th></tr>
<tr><td><code>msre.m_flow_fuel_norm</code> vs <code>msre.t_rel</code></td><td>Fig. 7</td>
<td>estimated data available to 20 s, standard deviation 1.4%</td></tr>
<tr><td><code>msre.rho_CR_pcm</code> vs <code>msre.t_rel</code></td><td>Fig. 8</td>
<td>good agreement up to 70 s; the equilibrium value is not reached within the measurement
window because the long-lived groups are slow</td></tr>
</table>

<p>The sign convention here is that <code>rho_CR_pcm</code> is the reactivity the rods add. It
starts at zero and becomes negative as the returning precursors insert positive reactivity, and
its magnitude approaches the same drift reactivity that the startup test builds up. Running
both tests and checking that the two asymptotes are equal and opposite is a useful consistency
check on the precursor transport solution.</p>

<p>The paper notes that halving the moment of inertia improved the startup test but degraded
the coastdown, and concludes that the hydraulic and friction torques would have to be adjusted
as well. The same limitation applies to the single time constant used here.</p>
</html>"));
end PumpCoastdown;
