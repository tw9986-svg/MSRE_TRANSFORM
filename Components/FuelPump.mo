within MSRE.Components;
model FuelPump
  "MSRE fuel salt circulation pump: quadratic head characteristic on a shaft with inertia"

  import TRANSFORM;

  replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Fuel salt medium"
    annotation (choicesAllMatching=true);

  /* ------------------------------------------------------------------
     Rated duty
     ------------------------------------------------------------------ */
  parameter SI.PressureDifference dp_nominal=3.0e5
    "Pressure rise at rated speed and rated flow";
  parameter SI.MassFlowRate m_flow_nominal=168 "Rated mass flow rate";
  parameter SI.Density d_nominal=2055 "Fuel salt density used to convert head to pressure";
  parameter Real N_nominal(unit="1/min") = 1160 "Rated shaft speed";
  parameter Real headRatio_shutoff=1.25
    "Ratio of the shut-off head to the rated head, sets the slope of the characteristic";
  parameter SI.Efficiency eta_is=0.8 "Isentropic efficiency, used only for the pumping heat";

  /* ------------------------------------------------------------------
     Shaft
     ------------------------------------------------------------------ */
  parameter Boolean use_rotorDynamics=true
    "=true to solve the rotor angular momentum equation, =false to impose the shaft speed";

  parameter SI.Torque tau_hyd_nominal=dp_nominal*V_flow_nominal/(omega_nominal*eta_is)
    "Hydraulic (impeller reaction) torque at the rated operating point (251 N.m)"
    annotation (Dialog(enable=use_rotorDynamics));
  parameter SI.Time tau_shaft=4.0
    "Shaft time constant; the single fitted parameter, which sets the startup and the coastdown together"
    annotation (Dialog(enable=use_rotorDynamics));
  parameter SI.MomentOfInertia J=tau_shaft*tau_hyd_nominal/omega_nominal
    "Polar moment of inertia of the rotor, impeller and entrained salt (8.28 kg.m2). Set either this or tau_shaft, not both"
    annotation (Dialog(enable=use_rotorDynamics));
  parameter SI.Torque tau_motor_nominal=tau_hyd_nominal + tau_fric_coulomb + tau_fric_viscous
    "Motor torque at full demand; the default balances the rated hydraulic and friction torque, so full demand settles the shaft exactly at N_nominal"
    annotation (Dialog(enable=use_rotorDynamics));
  parameter SI.Torque tau_fric_coulomb=0
    "Speed independent bearing and seal drag (Coulomb friction)"
    annotation (Dialog(enable=use_rotorDynamics));
  parameter SI.Torque tau_fric_viscous=0 "Windage and viscous drag torque at the rated speed"
    annotation (Dialog(enable=use_rotorDynamics));

  parameter Real N_start(unit="1/min") = 0
    "Shaft speed at the start of the simulation; used only with use_rotorDynamics=true"
    annotation (Dialog(tab="Initialization", enable=use_rotorDynamics));

  /* ------------------------------------------------------------------
     Speed input
     ------------------------------------------------------------------ */
  parameter Boolean use_speedInput=true "=true to drive the pump from the speed connector";
  parameter Real N_input(unit="1/min") = N_nominal
    "Commanded shaft speed when use_speedInput=false"
    annotation (Dialog(enable=not use_speedInput));

  Modelica.Blocks.Interfaces.RealInput N_in(unit="1/min") if use_speedInput
    "Commanded shaft speed [rpm]" annotation (Placement(transformation(
        extent={{-20,-20},{20,20}},
        rotation=-90,
        origin={0,80}), iconTransformation(
        extent={{-10,-10},{10,10}},
        rotation=-90,
        origin={0,70})));

  /* ------------------------------------------------------------------
     Ports
     ------------------------------------------------------------------ */
  TRANSFORM.Fluid.Interfaces.FluidPort_Flow port_a(redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
  TRANSFORM.Fluid.Interfaces.FluidPort_Flow port_b(redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{90,-10},{110,10}})));

  /* ------------------------------------------------------------------
     Derived quantities
     ------------------------------------------------------------------ */
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
  final parameter SI.AngularVelocity omega_start=2*pi*N_start/60
    "Shaft angular velocity at the start of the simulation";
  final parameter SI.AngularVelocity omega_reg=0.01*omega_nominal
    "Regularization width of the Coulomb friction term at zero speed";
  final parameter SI.Time tau_shaft_eff=J*omega_nominal/tau_hyd_nominal
    "Shaft time constant that actually results from J; equals tau_shaft unless J was overridden directly";

  /* ------------------------------------------------------------------
     Variables
     ------------------------------------------------------------------ */
  SI.AngularVelocity omega(start=omega_start) "Shaft angular velocity";
  Real N(unit="1/min") "Actual shaft speed";
  Real N_cmd(unit="1/min") "Commanded shaft speed";
  SIadd.NonDim u_motor "Motor torque demand, clipped to [0,1]";
  SI.Torque tau_motor "Motor torque";
  SI.Torque tau_hyd "Hydraulic torque absorbed by the impeller";
  SI.Torque tau_fric "Bearing, seal and windage friction torque";
  SI.Torque tau_net "Net accelerating torque on the shaft";
  SI.Power W_shaft "Shaft power delivered by the motor";

  SI.MassFlowRate m_flow "Mass flow rate from port_a to port_b";
  SI.VolumeFlowRate V_flow "Volumetric flow rate";
  SI.PressureDifference dp "Pressure rise";
  SI.Height head "Head";
  SI.Density d "Fuel salt density at the suction";
  SI.SpecificEnthalpy dh "Specific enthalpy rise across the pump";
  SI.Power W "Pumping power";

protected
  Modelica.Blocks.Interfaces.RealInput N_int(unit="1/min") "Internal speed connector";
  Medium.ThermodynamicState state_a=Medium.setState_phX(
      port_a.p,
      inStream(port_a.h_outflow),
      inStream(port_a.Xi_outflow)) "Suction state";

initial equation
  if use_rotorDynamics then
    omega = omega_start;
  end if;

equation
  connect(N_in, N_int);
  if not use_speedInput then
    N_int = N_input;
  end if;
  N_cmd = N_int;

  /* ---------------- Shaft ----------------
     With the rotor solved, the connector carries a motor torque demand: only its ratio to the
     rated speed is used, so a step from 0 to N_nominal is the pump start and a step from
     N_nominal to 0 is the trip. With the rotor bypassed, the connector is the shaft speed
     itself and a speed law has to be supplied from outside. */
  u_motor = min(1, max(0, N_cmd/N_nominal));
  tau_motor = tau_motor_nominal*u_motor;

  /* omega*abs(omega) rather than omega^2 so that the sign is right if the shaft is ever driven
     backwards; the affinity law makes the impeller reaction torque scale with the square of the
     speed at a fixed point on the head curve. */
  tau_hyd = tau_hyd_nominal*omega*abs(omega)/omega_nominal^2;

  /* Both friction terms default to zero, which is what makes the two analytic speed laws exact.
     They are exposed because the paper (Section 4.2) identifies precisely these torques as what
     would have to be adjusted to fit the startup and the coastdown at once. */
  tau_fric = tau_fric_coulomb*tanh(omega/omega_reg) + tau_fric_viscous*omega/omega_nominal;

  tau_net = tau_motor - tau_hyd - tau_fric;

  if use_rotorDynamics then
    J*der(omega) = tau_net;
  else
    omega = 2*pi*N_cmd/60;
  end if;

  N = 60*omega/(2*pi);
  W_shaft = tau_motor*omega;

  assert(omega > -0.01*omega_nominal, "The fuel pump shaft has been driven to a negative speed ("
     + String(60*omega/(2*pi)) + " rpm). The MSRE fuel pump cannot be back-driven; check the
motor torque demand and the friction parameters.", AssertionLevel.warning);

  /* ---------------- Hydraulics ---------------- */
  d = Medium.density(state_a);
  m_flow = port_a.m_flow;
  V_flow = m_flow/d;

  /* Quadratic pump characteristic. At N = 0 it degenerates into a pure hydraulic resistance,
     which is what the idle MSRE fuel pump is during the natural circulation test. */
  head = head_shutoff*(N/N_nominal)^2 - R_pump*V_flow*abs(V_flow);
  dp = d*Modelica.Constants.g_n*head;

  /* ---------------- Balance equations ---------------- */
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
meant to test is short-circuited. The flow here is always a result; what varies is how far back
the chain of causes is taken.</p>

<h4>The rotor</h4>
<p>By default the shaft speed is a state:</p>
<p><code>J*der(omega) = tau_motor - tau_hyd - tau_fric</code></p>
<p>which is the equation the paper solves for the MARS pump component. The motor torque comes
from the speed connector, read as a demand, so the pump tests are run from a <i>start</i> and a
<i>trip</i> rather than from a fitted speed history.</p>

<h4>Why one parameter is enough for both tests</h4>
<p>With the default friction (zero) and the hydraulic torque scaling as the square of the
speed, the rotor equation has closed-form solutions, and <b>both</b> pump tests come out of the
<b>same</b> shaft time constant:</p>
<table border=\"1\">
<tr><th>Test</th><th>Motor torque</th><th>Solution</th></tr>
<tr><td>startup, from rest</td><td><code>tau_motor_nominal</code></td>
    <td><code>omega = omega_nominal*tanh(t/tau_shaft)</code></td></tr>
<tr><td>coastdown, from rated</td><td>0</td>
    <td><code>omega = omega_0/(1 + t/tau_shaft)</code></td></tr>
</table>
<p><code>tau_shaft = J*omega_nominal/tau_hyd_nominal</code>. The two are the same degree of
freedom written two ways, so set one or the other; <code>tau_shaft_eff</code> reports what the
time constant actually came out as.</p>

<h4>Default numbers, and where they come from</h4>
<table border=\"1\">
<tr><th>Quantity</th><th>Value</th><th>Origin</th></tr>
<tr><td>rated hydraulic power</td><td>24.4 kW (32.8 hp)</td>
    <td><code>dp_nominal*V_flow_nominal</code>, i.e. 3.0 bar at 0.0814 m3/s</td></tr>
<tr><td><code>tau_hyd_nominal</code></td><td>251 N.m</td>
    <td>that power divided by <code>omega_nominal*eta_is</code></td></tr>
<tr><td><code>tau_shaft</code></td><td>4.0 s</td><td><b>fitted</b></td></tr>
<tr><td><code>J</code></td><td>8.28 kg.m2</td><td>follows from the two above</td></tr>
</table>
<p>Only the shaft time constant is free. That is the same single degree of freedom the paper
describes as <q>typical generic pump parameters</q>, and its sensitivity case with the moment
of inertia halved is <code>tau_shaft = 2.0</code>. At 4.0 s the startup reaches 98.7 % of rated
flow in 10 s.</p>

<h4>Bypassing the rotor</h4>
<p><code>use_rotorDynamics = false</code> replaces the angular momentum equation by
<code>omega = 2*pi*N_cmd/60</code>, so the connector becomes the shaft speed itself and a speed
law has to be supplied. This is what the model did before the rotor was added, and it is kept
only so that the two can be compared: it needs an exponential with 3.4 s for the startup and a
hyperbola with 4.0 s for the coastdown, two unrelated numbers for one rotor that physically has
one moment of inertia. Running the same experiment both ways separates what the pump model
contributes from what the precursor transport contributes, which is the distinction the
benchmark is about. It is not a modelling alternative, and it should not be used for results.</p>

<p>Note that the connector changes meaning with the flag: torque demand when the rotor is
solved, shaft speed when it is not. <a href=\"modelica://MSRE.Experiments.PumpStartup\">The
experiment models</a> switch the source expression along with the flag, so use their
<code>use_rotorDynamics</code> parameter rather than setting this one directly.</p>

<h4>What is still missing</h4>
<p>The hydraulic torque depends on the speed alone, not on the operating point on the head
curve. A homologous torque characteristic would make it a function of both speed and flow, and
that is what would be needed for a pump running far off its design point, such as the
reverse-flow region. It does not matter for the two zero-power tests, where the pump stays on
its rated curve, and it is the reason <code>tau_fric_coulomb</code> and
<code>tau_fric_viscous</code> are exposed rather than hard-wired to zero.</p>

<p>The pump has no fluid volume: the salt inventory of the pump bowl is modelled separately as a
<a href=\"modelica://MSRE.Components.SaltPipe\">SaltPipe</a>, so that the precursors carried
through the bowl decay there.</p>
</html>"));
end FuelPump;
