within MSRE.Components;
model FuelPump_Dynamics
  "MSRE fuel salt circulation pump whose shaft speed is a state of the rotor angular momentum equation"

  extends MSRE.Components.BaseClasses.PartialFuelPump;

  /* ------------------------------------------------------------------
     Rotor
     ------------------------------------------------------------------ */
  parameter SI.Torque tau_hyd_nominal=dp_nominal*V_flow_nominal/(omega_nominal*eta_is)
    "Hydraulic (impeller reaction) torque at the rated operating point (231 N.m at the ORNL-TM-4865 density)";
  parameter SI.Time tau_shaft=4.0
    "Shaft time constant; the single fitted parameter, which sets the startup and the coastdown together";
  parameter SI.MomentOfInertia J=tau_shaft*tau_hyd_nominal/omega_nominal
    "Polar moment of inertia of the rotor, impeller and entrained salt (7.59 kg.m2). Set either this or tau_shaft, not both";
  parameter SI.Torque tau_motor_nominal=tau_hyd_nominal + tau_fric_coulomb +
      tau_fric_viscous
    "Motor torque at full demand; the default balances the rated hydraulic and friction torque, so full demand settles the shaft exactly at N_nominal";
  parameter SI.Torque tau_fric_coulomb=0
    "Speed independent bearing and seal drag (Coulomb friction)";
  parameter SI.Torque tau_fric_viscous=0
    "Windage and viscous drag torque at the rated speed";

  /* N_start, m_flow_start and the start values derived from them are inherited from
     PartialFuelPump, so that the shaft state and the hydraulic variables are initialized from
     the same operating point. */
  final parameter SI.AngularVelocity omega_reg=0.01*omega_nominal
    "Regularization width of the Coulomb friction term at zero speed";
  final parameter SI.Time tau_shaft_eff=J*omega_nominal/tau_hyd_nominal
    "Shaft time constant that actually results from J; equals tau_shaft unless J was overridden directly";

  /* ------------------------------------------------------------------
     State and torques
     ------------------------------------------------------------------ */
  SI.AngularVelocity omega(start=omega_start, fixed=true) "Shaft angular velocity";
  SIadd.NonDim u_motor "Motor torque demand, clipped to [0,1]";
  SI.Torque tau_motor "Motor torque";
  SI.Torque tau_hyd "Hydraulic torque absorbed by the impeller";
  SI.Torque tau_fric "Bearing, seal and windage friction torque";
  SI.Torque tau_net "Net accelerating torque on the shaft";
  SI.Power W_shaft "Shaft power delivered by the motor";

equation
  /* The commanded speed of the connector is read as a motor torque demand: only its ratio to
     the rated speed is used. A step from 0 to N_nominal is the pump start, a step from
     N_nominal to 0 is the trip. The actual speed is the state, never the command. */
  u_motor = min(1, max(0, N_cmd/N_nominal));
  tau_motor = tau_motor_nominal*u_motor;

  /* Hydraulic torque. omega*abs(omega) rather than omega^2 so that the sign is right if the
     shaft is ever driven backwards; the affinity law makes the impeller reaction torque scale
     with the square of the speed at a fixed point on the head curve. */
  tau_hyd = tau_hyd_nominal*omega*abs(omega)/omega_nominal^2;

  /* Friction. Both terms default to zero, which is what makes the two analytic speed laws
     below exact; they are exposed because the paper (Section 4.2) identifies precisely these
     torques as what would have to be adjusted to fit the startup and the coastdown at once. */
  tau_fric = tau_fric_coulomb*tanh(omega/omega_reg) + tau_fric_viscous*omega/omega_nominal;

  tau_net = tau_motor - tau_hyd - tau_fric;
  J*der(omega) = tau_net;

  N = 60*omega/(2*pi);
  W_shaft = tau_motor*omega;

  assert(omega > -0.01*omega_nominal,
    "The fuel pump shaft has been driven to a negative speed (" + String(60*omega/(2*pi)) +
    " rpm). The MSRE fuel pump cannot be back-driven; check the motor torque demand and the
friction parameters.", AssertionLevel.warning);

  annotation (
    defaultComponentName="pump",
    Documentation(info="<html>
<h4>What this model adds</h4>
<p>The shaft speed becomes a state instead of a boundary condition:</p>
<p><code>J*der(omega) = tau_motor - tau_hyd - tau_fric</code></p>
<p>This is the equation the paper solves for the MARS pump component, and solving it here is
what lets the pump tests be run from a <i>trip</i> and a <i>start</i> rather than from a fitted
speed history. The flow is then two integrations away from the input: motor torque drives the
shaft, the shaft drives the head, the head drives the loop momentum balance.</p>

<h4>Why one parameter is enough for both tests</h4>
<p>With the default friction (zero) and the hydraulic torque scaling as the square of the
speed, the rotor equation has closed-form solutions, and <b>both</b> pump tests come out of the
<b>same</b> <code>J</code>:</p>
<table border=\"1\">
<tr><th>Test</th><th>Motor torque</th><th>Solution</th></tr>
<tr><td>startup, from rest</td><td><code>tau_motor_nominal</code></td>
    <td><code>omega = omega_nominal*tanh(t/tau_shaft)</code></td></tr>
<tr><td>coastdown, from rated</td><td>0</td>
    <td><code>omega = omega_0/(1 + t/tau_shaft)</code></td></tr>
</table>
<p>with the single time constant</p>
<p><code>tau_shaft = J*omega_nominal/tau_hyd_nominal</code>.</p>
<p><code>tau_shaft</code> and <code>J</code> are two ways of writing the same degree of freedom,
so set one or the other. <code>J</code> defaults to the value that produces
<code>tau_shaft</code>, and <code>tau_shaft_eff</code> reports what the shaft time constant
actually came out as, which differs from <code>tau_shaft</code> only if <code>J</code> was
given directly.</p>
<p>The previous <a href=\"modelica://MSRE.Components.FuelPump\">FuelPump</a> needed two
independently fitted laws for the same rotor (an exponential with 3.4 s for the startup, a
hyperbola with 4.0 s for the coastdown). Here the coastdown hyperbola is recovered exactly and
the startup becomes a <code>tanh</code>, which reaches 98.7 % of rated <b>shaft speed</b> at
10 s with <code>tau_shaft = 4.0 s</code>, from the same single number.</p>

<p><b>That figure is a speed, not a flow.</b> <code>tanh(10/4) = 0.9866</code> is
<code>omega/omega_nominal</code>; the mass flow rate is separated from it by the loop momentum
balance and is not a property of this component at all. The two are not interchangeable, and
early in the transient they are far apart: a lumped estimate of this loop puts the flow at
about 3 % of rated when the shaft is already at 24 % (1 s after the start). They converge later
because this loop's hydraulic time constant is roughly an order of magnitude shorter than
<code>tau_shaft</code>, but that is a result about this loop, not a licence to restate one as
the other. The flow figure must come from a run of
<a href=\"modelica://MSRE.Experiments.PumpStartup_RotorDynamics\">PumpStartup_RotorDynamics</a>,
which has not been carried out. See <code>docs/verification/rotor_check.py</code>.</p>

<h4>Default numbers, and where they come from</h4>
<table border=\"1\">
<tr><th>Quantity</th><th>Value</th><th>Origin</th></tr>
<tr><td>rated hydraulic power</td><td>22.4 kW (30.0 hp)</td>
    <td><code>dp_nominal*V_flow_nominal</code>, i.e. 3.0 bar at 0.0747 m3/s</td></tr>
<tr><td><code>tau_hyd_nominal</code></td><td>231 N.m</td>
    <td>that power divided by <code>omega_nominal*eta_is</code></td></tr>
<tr><td><code>tau_shaft</code></td><td>4.0 s</td><td><b>fitted</b></td></tr>
<tr><td><code>J</code></td><td>7.59 kg.m2</td>
    <td><code>tau_shaft*tau_hyd_nominal/omega_nominal</code></td></tr>
</table>
<p>Only the shaft time constant is free; the rest follows from the rated duty. That is the same
single degree of freedom the paper describes as <q>typical generic pump parameters</q>, and the
paper's sensitivity case (moment of inertia halved) is run here by setting
<code>tau_shaft = 2.0</code>.</p>

<h4>What is still missing</h4>
<p>The hydraulic torque depends on the speed alone, not on the operating point on the head
curve. A homologous torque characteristic would make it a function of both speed and flow, and
that is what would be needed to reproduce a pump running far off its design point, such as the
reverse-flow region. It does not matter for the two zero-power tests, where the pump stays on
its rated curve, and it is the reason <code>tau_fric_coulomb</code> and
<code>tau_fric_viscous</code> are exposed rather than hard-wired to zero.</p>
</html>"));
end FuelPump_Dynamics;
