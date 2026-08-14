within MSRE;
package Experiments "The three MSRE transients used to benchmark the MARS code"
  extends Modelica.Icons.ExamplesPackage;
  annotation (Documentation(info="<html>
<p>Each model is a ready to simulate reproduction of one of the transients of Section 4 of</p>
<blockquote>
J.J. Jeong, Y.J. Cho, H.C. Lee, B. Yun, <i>Benchmarking the MARS code for molten salt reactor
applications using MSRE transient experiments</i>, Nuclear Engineering and Technology 58 (2026)
104438.
</blockquote>
<p>All three share the same plant model,
<a href=\"modelica://MSRE.Systems.PrimarySystem\">MSRE.Systems.PrimarySystem</a>, and differ
only in the fuel (U-235 or U-233), the initial power, the pump speed law and the secondary
side boundary condition.</p>
<p>Each run begins with a null transient of length <code>t_null</code> during which the neutron
balance is frozen and the flow field and precursor distribution converge; the transient of
interest starts at that instant. Plot against <code>msre.t_rel</code> rather than
<code>time</code> so that the transient starts at zero.</p>

<h4>Two ways of driving the pump</h4>
<p>The two pump tests come in pairs. In
<a href=\"modelica://MSRE.Experiments.PumpStartup\">PumpStartup</a> and
<a href=\"modelica://MSRE.Experiments.PumpCoastdown\">PumpCoastdown</a> the shaft speed is
prescribed as a fitted function of time. In
<a href=\"modelica://MSRE.Experiments.PumpStartup_RotorDynamics\">PumpStartup_RotorDynamics</a>
and
<a href=\"modelica://MSRE.Experiments.PumpCoastdown_RotorDynamics\">PumpCoastdown_RotorDynamics</a>
the input is a motor step and the speed is a state of the rotor angular momentum equation, as
in the MARS model.</p>

<p>The pair matters because the prescribed-speed models need two unrelated numbers for one
rotor - 3.4 s for the startup, 4.0 s for the coastdown - while the rotor models take a single
<code>tau_shaft</code> for both. Running the two versions of each test against each other
separates what the pump model contributes from what the precursor transport contributes, which
is the distinction the benchmark is about.</p>
</html>"));
end Experiments;
