within MSRE.Experiments;
model PumpCoastdown_RotorDynamics
  "MSRE pump coastdown test with the pump shaft speed solved rather than prescribed"
  extends MSRE.Experiments.PumpCoastdown(
    msre(redeclare MSRE.Components.FuelPump_Dynamics pump(tau_shaft=tau_shaft)),
    pumpSpeed(y=if time < t_null then N_rated else 0));

  parameter SI.Time tau_shaft=4.0
    "Pump shaft time constant, J*omega_nominal/tau_hyd_nominal; 2.0 is the paper's halved-inertia case";

  annotation (
    experiment(
      StopTime=800,
      __Dymola_NumberOfIntervals=8000,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>Difference from <a href=\"modelica://MSRE.Experiments.PumpCoastdown\">PumpCoastdown</a></h4>
<p>The pump is <a href=\"modelica://MSRE.Components.FuelPump_Dynamics\">FuelPump_Dynamics</a>
and <code>pumpSpeed</code> is a step to zero at <code>t_null</code>, which is the motor trip.
The shaft then decelerates under its own hydraulic torque with no motor torque, and</p>
<p><code>omega(t) = omega_0/(1 + t/tau_shaft)</code></p>
<p>which is exactly the law <code>PumpCoastdown</code> prescribes. This model should therefore
reproduce the prescribed-speed coastdown to solver tolerance, and that agreement is the
regression check on the rotor model: it is the case where the analytic solution is known, so
any deviation is a defect in the ODE or in its initialization rather than a modelling choice.</p>

<h4>What to check first</h4>
<table border=\"1\">
<tr><th>Variable</th><th>Expected</th></tr>
<tr><td><code>msre.pump.N</code> at <code>t_null</code></td><td>1160 rpm, from <code>msre.N_pump_start</code></td></tr>
<tr><td><code>msre.pump.N</code> at <code>t_null + tau_shaft</code></td><td>580 rpm, i.e. exactly half</td></tr>
<tr><td><code>msre.pump.N</code> at <code>t_null + 20 s</code></td><td>193 rpm, one sixth</td></tr>
<tr><td><code>msre.rho_CR_pcm</code></td><td>the same curve as <code>PumpCoastdown</code></td></tr>
</table>

<p>If the speed matches but the reactivity does not, the difference is in the loop hydraulics
rather than the rotor, and <a href=\"modelica://MSRE.Verification.Steady_LoopBalance\">Steady_LoopBalance</a>
is the model to run next.</p>

<h4>Status</h4>
<p>Not yet run; no Modelica compiler was available where this model was written.</p>
</html>"));
end PumpCoastdown_RotorDynamics;
