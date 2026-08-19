within MSRE.Components.BaseClasses;
partial model PartialFuelPump
  "Common hydraulics of the MSRE fuel salt pump; the shaft speed is left to the extending model"

  import TRANSFORM;

  replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Fuel salt medium"
    annotation (choicesAllMatching=true);

  parameter SI.PressureDifference dp_nominal=3.0e5
    "Pressure rise at rated speed and rated flow";
  parameter SI.MassFlowRate m_flow_nominal=168 "Rated mass flow rate";
  parameter SI.Density d_nominal=2188.646
    "Fuel salt density used to convert head to pressure (Cantor ORNL-TM-2316 at 922 K); a standalone default only - PrimarySystem overrides it from Medium_fuel";
  parameter Real N_nominal(unit="1/min") = 1160 "Rated shaft speed";
  parameter Real headRatio_shutoff=1.25
    "Ratio of the shut-off head to the rated head, sets the slope of the characteristic";
  parameter SI.Efficiency eta_is=0.8 "Isentropic efficiency, used only for the pumping heat";

  parameter Boolean use_speedInput=true "=true to drive the pump from the speed connector";
  parameter Real N_input(unit="1/min") = N_nominal
    "Commanded shaft speed when use_speedInput=false" annotation (Dialog(enable=not use_speedInput));

  parameter Real N_start(unit="1/min") = 0 "Shaft speed at the start of the simulation"
    annotation (Dialog(tab="Initialization"));
  parameter SI.MassFlowRate m_flow_start=0
    "Mass flow rate at the start of the simulation. Only a start value, but the head curve is nonlinear in the flow, so it is the initial guess of an iteration"
    annotation (Dialog(tab="Initialization"));

  Modelica.Blocks.Interfaces.RealInput N_in(unit="1/min") if use_speedInput
    "Commanded shaft speed [rpm]" annotation (Placement(transformation(
        extent={{-20,-20},{20,20}},
        rotation=-90,
        origin={0,80}), iconTransformation(
        extent={{-10,-10},{10,10}},
        rotation=-90,
        origin={0,70})));

  TRANSFORM.Fluid.Interfaces.FluidPort_Flow port_a(redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
  TRANSFORM.Fluid.Interfaces.FluidPort_Flow port_b(redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{90,-10},{110,10}})));

  final parameter SI.VolumeFlowRate V_flow_nominal=m_flow_nominal/d_nominal
    "Rated volumetric flow rate";
  final parameter SI.AngularVelocity omega_nominal=2*pi*N_nominal/60
    "Rated shaft angular velocity";
  final parameter SI.Height head_nominal=dp_nominal/(d_nominal*Modelica.Constants.g_n)
    "Rated head";
  final parameter SI.Height head_shutoff=headRatio_shutoff*head_nominal
    "Head at rated speed and zero flow";
  final parameter Real R_pump(unit="s2/m5") = (headRatio_shutoff - 1)*head_nominal/
    V_flow_nominal^2 "Internal hydraulic resistance of the pump";

  /* Start values of the shaft and hydraulic variables. The head curve is quadratic in the flow,
     so V_flow is an iteration variable of the initialization problem; without these Dymola
     reports it as having no start value and begins from zero, which is the wrong end of the
     range for any test that starts at rated flow. */
  final parameter SI.AngularVelocity omega_start=2*pi*N_start/60
    "Shaft angular velocity at the start of the simulation";
  final parameter SI.VolumeFlowRate V_flow_start=m_flow_start/d_nominal
    "Start value of the volumetric flow rate";
  final parameter SI.Height head_start=head_shutoff*(N_start/N_nominal)^2 - R_pump*V_flow_start
      *abs(V_flow_start) "Start value of the head";
  final parameter SI.PressureDifference dp_start=d_nominal*Modelica.Constants.g_n*head_start
    "Start value of the pressure rise";

  Real N(unit="1/min", start=N_start) "Actual shaft speed";
  Real N_cmd(unit="1/min", start=N_start) "Commanded shaft speed";
  SI.MassFlowRate m_flow(start=m_flow_start) "Mass flow rate from port_a to port_b";
  SI.VolumeFlowRate V_flow(start=V_flow_start) "Volumetric flow rate";
  SI.PressureDifference dp(start=dp_start) "Pressure rise";
  SI.Height head(start=head_start) "Head";
  SI.Density d "Fuel salt density at the suction";
  SI.SpecificEnthalpy dh "Specific enthalpy rise across the pump";
  SI.Power W "Pumping power";

protected
  Modelica.Blocks.Interfaces.RealInput N_int(unit="1/min") "Internal speed connector";
  Medium.ThermodynamicState state_a=Medium.setState_phX(
      port_a.p,
      inStream(port_a.h_outflow),
      inStream(port_a.Xi_outflow)) "Suction state";

equation
  connect(N_in, N_int);
  if not use_speedInput then
    N_int = N_input;
  end if;
  N_cmd = N_int;

  /* N itself is deliberately NOT bound here. MSRE.Components.FuelPump sets N = N_cmd,
     MSRE.Components.FuelPump_Dynamics obtains it from the rotor angular momentum equation. */

  d = Medium.density(state_a);
  m_flow = port_a.m_flow;
  V_flow = m_flow/d;

  /* Quadratic pump characteristic. At N = 0 it degenerates into a pure hydraulic resistance,
     which is what the idle MSRE fuel pump is during the natural circulation test. */
  head = head_shutoff*(N/N_nominal)^2 - R_pump*V_flow*abs(V_flow);
  dp = d*Modelica.Constants.g_n*head;

  /* Balance equations */
  port_a.m_flow + port_b.m_flow = 0;
  dp = port_b.p - port_a.p;

  dh = dp/(d*eta_is);
  W = m_flow*dh;
  port_b.h_outflow = inStream(port_a.h_outflow) + dh;
  port_a.h_outflow = inStream(port_b.h_outflow) - dh;
  port_b.Xi_outflow = inStream(port_a.Xi_outflow);
  port_a.Xi_outflow = inStream(port_b.Xi_outflow);
  port_b.C_outflow = inStream(port_a.C_outflow);
  port_a.C_outflow = inStream(port_b.C_outflow);

  annotation (
    defaultComponentName="pump",
    Icon(coordinateSystem(preserveAspectRatio=false), graphics={
        Rectangle(
          extent={{-80,20},{-40,-20}},
          lineColor={0,0,0},
          fillColor={0,127,255},
          fillPattern=FillPattern.HorizontalCylinder),
        Rectangle(
          extent={{0,60},{80,20}},
          lineColor={0,0,0},
          fillColor={0,127,255},
          fillPattern=FillPattern.HorizontalCylinder),
        Ellipse(
          extent={{-60,60},{60,-60}},
          lineColor={0,0,0},
          fillColor={0,128,255},
          fillPattern=FillPattern.Sphere),
        Polygon(
          points={{-20,20},{-20,-22},{30,0},{-20,20}},
          lineColor={0,0,0},
          pattern=LinePattern.None,
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={255,255,255}),
        Text(
          extent={{-149,-70},{151,-110}},
          lineColor={0,0,255},
          textString="%name")}),
    Diagram(coordinateSystem(preserveAspectRatio=false)),
    Documentation(info="<html>
<h4>Why a speed driven pump, and not a prescribed flow rate</h4>
<p>The MSRE pump startup and coastdown tests are, from the point of view of the kinetics,
experiments about the fuel-salt <i>transit time</i>. The flow rate must therefore come out of
the loop momentum balance, not be imposed on it, otherwise the coupling that the benchmark is
meant to test is short-circuited. This partial model fixes the <b>hydraulics</b> and leaves the
<b>shaft speed</b> to the extending model.</p>

<h4>Characteristic</h4>
<p><code>head = head_shutoff*(N/N_nominal)^2 - R_pump*V_flow*|V_flow|</code></p>
<p>with <code>head_shutoff = headRatio_shutoff*head_nominal</code> and <code>R_pump</code>
fixed so that the rated point <code>(N_nominal, V_flow_nominal)</code> lies on the curve. Two
properties matter here:</p>
<ul>
<li>it obeys the affinity law in the operating region, so a speed transient produces the
right flow transient, and</li>
<li>at <code>N = 0</code> it reduces to <code>head = -R_pump*V_flow*|V_flow|</code>, a pure
form loss. The idle pump then simply resists the flow, which is required for the natural
circulation test where the fuel pump is stopped but the salt still circulates.</li>
</ul>

<h4>Two implementations</h4>
<table border=\"1\">
<tr><th>Model</th><th>Shaft speed</th><th>Meaning of <code>N_in</code></th></tr>
<tr><td><a href=\"modelica://MSRE.Components.FuelPump\">FuelPump</a></td>
    <td><code>N = N_cmd</code>, algebraic</td><td>the shaft speed itself</td></tr>
<tr><td><a href=\"modelica://MSRE.Components.FuelPump_Dynamics\">FuelPump_Dynamics</a></td>
    <td>state of <code>J*der(omega) = tau_motor - tau_hyd - tau_fric</code></td>
    <td>motor torque demand, expressed as a speed</td></tr>
</table>

<p>The pump has no fluid volume: the salt inventory of the pump bowl is modelled separately
as a <a href=\"modelica://MSRE.Components.SaltPipe\">SaltPipe</a>, so that the precursors
carried through the bowl decay there.</p>
</html>"));
end PartialFuelPump;
