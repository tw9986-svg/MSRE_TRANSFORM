within MSRE.Experiments;
model PumpStartup_RotorDynamics
  "MSRE pump startup test with the pump shaft speed solved rather than prescribed"
  extends MSRE.Experiments.PumpStartup(
    msre(redeclare MSRE.Components.FuelPump_Dynamics pump(tau_shaft=tau_shaft)),
    pumpSpeed(y=if time < t_null then 0 else N_rated));

  parameter SI.Time tau_shaft=4.0
    "Pump shaft time constant, J*omega_nominal/tau_hyd_nominal; 2.0 is the paper's halved-inertia case";

  annotation (
    experiment(
      StopTime=750,
      __Dymola_NumberOfIntervals=7500,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>Difference from <a href=\"modelica://MSRE.Experiments.PumpStartup\">PumpStartup</a></h4>
<p>Two changes, and nothing else:</p>
<ol>
<li>the pump is <a href=\"modelica://MSRE.Components.FuelPump_Dynamics\">FuelPump_Dynamics</a>,
which integrates <code>J*der(omega) = tau_motor - tau_hyd - tau_fric</code>;</li>
<li><code>pumpSpeed</code> is a <b>step</b> at <code>t_null</code> rather than an exponential
rise. The connector no longer carries the speed the shaft is to have; it carries the motor
torque demand, and the speed is a state.</li>
</ol>

<p>The speed history is therefore a result. With zero friction and a hydraulic torque
proportional to the square of the speed the rotor equation integrates to</p>
<p><code>omega(t) = omega_nominal*tanh(t/tau_shaft)</code></p>
<p>which reaches 98.7 % of rated at 10 s for <code>tau_shaft = 4.0 s</code>, so the flow rise
the paper describes is reproduced without a fitted speed law.</p>

<h4>The comparison worth running</h4>
<p>Run this model and <code>PumpStartup</code> together and plot
<code>msre.m_flow_fuel_norm</code> from both. The fitted exponential
(<code>tau_startup = 3.4 s</code>) reaches 94.7 % of rated at 10 s and the solved
<code>tanh</code> reaches 98.7 %, so the two flow histories differ mainly in the first few
seconds. What matters for the benchmark is whether that difference is visible in
<code>msre.rho_CR_pcm</code>: the drift reactivity is an integral over the whole precursor
transit history, so a difference confined to the first seconds of a 25 s transit should be
small. Quantifying it is the point of having both models.</p>

<h4>Why this is not just a cosmetic change</h4>
<p><code>PumpStartup</code> needs <code>tau_startup = 3.4 s</code> and
<code>PumpCoastdown</code> needs <code>tau_coast = 4.0 s</code>, two different numbers for one
rotor that physically has one moment of inertia. Here
<a href=\"modelica://MSRE.Experiments.PumpCoastdown_RotorDynamics\">the coastdown</a> uses the
same <code>tau_shaft</code> as this model, so the pair of tests is now constrained by a single
parameter instead of two independent ones. That is a stronger test of the model, not a weaker
one, and it is what makes the paper's remark about having to adjust the hydraulic and friction
torques as well a statement this library can actually be checked against.</p>

<h4>Status</h4>
<p>Not yet run; no Modelica compiler was available where this model was written.</p>
</html>"));
end PumpStartup_RotorDynamics;
