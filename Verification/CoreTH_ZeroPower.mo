within MSRE.Verification;
model CoreTH_ZeroPower
  "Stage 2-1 isothermal hydraulic baseline: the same equivalent 1-D core at zero power"
  extends MSRE.Verification.CoreTH_Baseline(
    Q_core=0,
    tol_energy=1e-6);

  parameter SI.TemperatureDifference tol_isothermal=1e-3
    "Allowed departure from isothermal behaviour at zero power";

equation
  when terminal() then
    assert(abs(dT_core) < tol_isothermal, "The core is not isothermal at zero power: T_out - T_in = "
       + String(dT_core) + " K. With Q_core = 0 and no wall heat transfer the only sources left
are numerical, so a departure beyond round-off means an unintended energy path. Do not adjust
any property or geometry to remove it.", AssertionLevel.error);
  end when;

  annotation (
    experiment(
      StopTime=300,
      __Dymola_NumberOfIntervals=1500,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>Purpose</h4>
<p>The hydraulic half of the Stage 2 verification, run before the heated case so that the
momentum balance can be read without any density gradient in it. Same geometry, same fuel salt,
same boundary conditions and the same equivalent one-group, twenty-cell core as
<a href=\"modelica://MSRE.Verification.CoreTH_Baseline\">CoreTH_Baseline</a>; only
<code>Q_core</code> changes, to zero.</p>

<table border=\"1\">
<tr><th>Condition</th><th>Value</th></tr>
<tr><td>radial groups</td><td>1 equivalent group of 1140 channels</td></tr>
<tr><td>axial cells</td><td>20</td></tr>
<tr><td>mass flow</td><td>168 kg/s, imposed</td></tr>
<tr><td>inlet temperature</td><td>908 K, imposed</td></tr>
<tr><td>core power</td><td><b>0 W</b></td></tr>
<tr><td>wall heat transfer</td><td>off</td></tr>
</table>

<h4>What it verifies</h4>
<ol>
<li><b>Mass conservation</b> - inherited from the base model, same tolerance.</li>
<li><b>Isothermal behaviour</b> - with no source and no wall coupling the salt must leave at
the temperature it entered. Anything beyond round-off is an unintended energy path, most
likely the pressure work or the flow-model dissipation term, and is to be traced rather than
tuned away.</li>
<li><b>Momentum balance with a uniform density</b> - at constant temperature
<code>dp_gravity_local</code> and <code>dp_gravity_bulk</code> must agree to round-off, which
makes this case the calibration of the static-head diagnostic itself before it is trusted in
the heated case.</li>
<li><b>Acceleration term</b> - it should be negligible here because the density is uniform, but
it is <b>computed rather than assumed</b>, so that its magnitude in the heated case can be
judged against a measured baseline instead of an expectation.</li>
</ol>

<h4>Energy tolerance</h4>
<p><code>tol_energy</code> is tightened to 1e-6 because the residual is now normalized by
<code>Q_energyNorm</code> rather than by the test power: at zero power there is no physical
energy input to hide a numerical residual behind. This is a stricter condition than the base
model's, not a relaxed one.</p>

<h4>What this is not</h4>
<p>It is not a Jeong comparison and not an MSRE measurement. No pressure drop here is asserted
against experimental data, because no independent MSRE core pressure-loss reference has been
established in this library yet.</p>
</html>"));
end CoreTH_ZeroPower;
