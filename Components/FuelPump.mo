within MSRE.Components;
model FuelPump
  "MSRE fuel salt circulation pump: quadratic head characteristic driven by a prescribed speed"

  extends MSRE.Components.BaseClasses.PartialFuelPump;

equation
  /* The shaft speed is whatever is commanded: the rotor has no inertia in this model, so the
     speed law has to be supplied from outside. MSRE.Components.FuelPump_Dynamics replaces
     this single equation by the angular momentum balance of the rotor. */
  N = N_cmd;

  annotation (
    defaultComponentName="pump",
    Documentation(info="<html>
<p>The kinematic fuel pump: the shaft speed is prescribed and the hydraulics of
<a href=\"modelica://MSRE.Components.BaseClasses.PartialFuelPump\">PartialFuelPump</a>
determine the flow. Kept as the default so that the results obtained before the rotor dynamics
were added remain reproducible.</p>

<h4>Speed transients</h4>
<p>The paper solves an angular momentum equation for the pump and notes that the moment of
inertia had to be tuned to match the measured flow, halving it for the startup test. Here the
speed law is supplied from outside, which maps onto the same single free parameter:</p>
<ul>
<li>startup: <code>N = N_nominal*(1 - exp(-t/tau))</code>, with <code>tau</code> about 3.4 s
to reach the rated flow in roughly 10 s;</li>
<li>coastdown: <code>N = N_0/(1 + t/tau)</code>, which is the exact solution of
<code>J*dw/dt = -tau_hyd*(w/w_n)^2</code> with <code>tau = J*w_n/tau_hyd_nominal</code>.</li>
</ul>
<p>Both are provided by <a href=\"modelica://MSRE.Experiments\">the experiment models</a>.</p>

<h4>Limitation this model has and FuelPump_Dynamics does not</h4>
<p>The two speed laws above are <i>fitted</i> to a verbal description of the tests, and they are
fitted independently of each other: <code>tau = 3.4 s</code> for the startup and
<code>tau = 4.0 s</code> for the coastdown, even though a single rotor with a single moment of
inertia produced both. <a href=\"modelica://MSRE.Components.FuelPump_Dynamics\">FuelPump_Dynamics</a>
removes that inconsistency by integrating the rotor equation, which yields both laws from one
value of <code>J</code>.</p>
</html>"));
end FuelPump;
