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
<p>Both pump tests carry a <code>use_rotorDynamics</code> switch. With it set (the default) the
input is a motor step and the shaft speed is a state of the rotor angular momentum equation, as
in the MARS model. With it cleared the shaft speed is imposed as a fitted function of time,
which is what the model did before the rotor was added.</p>

<p>The switch is there to be flipped, not to be chosen once. The imposed-speed form needs two
unrelated numbers for one rotor - 3.4 s for the startup, 4.0 s for the coastdown - while the
rotor form takes a single <code>tau_shaft</code> for both, so running the same experiment both
ways separates what the pump model contributes from what the precursor transport contributes.
That is the distinction the benchmark is about. Results should come from the rotor form.</p>
</html>"));
end Experiments;
