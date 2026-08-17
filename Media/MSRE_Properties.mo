within MSRE.Media;
package MSRE_Properties
  "Provenance of the MSRE fuel salt property correlations, and the alternatives they were chosen over"
  extends Modelica.Icons.Package;

  function d_Compere "Fuel salt density, Compere et al. (1975)"
    extends Modelica.Icons.Function;
    input SI.Temperature T "Temperature";
    output SI.Density d "Density";
  algorithm
    d := 2575.0 - 0.513*(T - 273.15);
    annotation (Inline=true, Documentation(info="<html>
<p><code>rho [kg/m3] = 2575 - 0.513*T [degC]</code>, for LiF-BeF2-ZrF4-UF4 65-29.1-5-0.9 mol%.
This is the correlation the library uses; <a href=\"modelica://MSRE.Media.FuelSalt.Utilities.d_T\">
FuelSalt.Utilities.d_T</a> is the same expression.</p>
<p>It also appears as Eq. (10) of Mao et al., Energies (2026), and it is <b>character for
character</b> the correlation behind the MSRE fuel salt medium TRANSFORM ships. See the package
documentation for that comparison and for the report-number problem attached to this citation.</p>
</html>"));
  end d_Compere;

  function d_legacy "Fuel salt density used by this library before Phase 2"
    extends Modelica.Icons.Function;
    input SI.Temperature T "Temperature";
    output SI.Density d "Density";
  algorithm
    d := 2575.3 - 0.5641*T;
    annotation (Inline=true, Documentation(info="<html>
<p><code>rho [kg/m3] = 2575.3 - 0.5641*T [K]</code>. Retained only so that
<a href=\"modelica://MSRE.Verification.Properties_TransitTime\">Properties_TransitTime</a> can
quantify what replacing it changed. Do not use it for results.</p>
<p>The constant is the same 2575 as the Compere correlation but the argument is in kelvin
rather than degrees Celsius, which is the signature of the degC correlation having been read
with a kelvin argument and the slope then re-fitted to land near the right value at one
temperature. It runs about 9 % low at MSRE conditions.</p>
</html>"));
  end d_legacy;

  function cp_TRANSFORM "Fuel salt specific heat of the TRANSFORM MSRE medium"
    extends Modelica.Icons.Function;
    input SI.Temperature T "Temperature";
    output SI.SpecificHeatCapacity cp "Specific heat capacity";
  algorithm
    cp := 0.57*4186.8;
    annotation (Inline=true, Documentation(info="<html>
<p>2386.5 J/(kg.K), from <code>from_cal_gK(0.57)</code> in
<code>TRANSFORM.Media.Fluids.FLiBe.Utilities_64LiF_30BeF2_5ZrF4_1UF4_CrFeNi.cp_T</code>.
Provided for comparison only; this library does not use it, and the package documentation sets
out why.</p>
</html>"));
  end cp_TRANSFORM;

  function eta_TRANSFORM "Fuel salt viscosity of the TRANSFORM MSRE medium"
    extends Modelica.Icons.Function;
    input SI.Temperature T "Temperature";
    output SI.DynamicViscosity eta "Dynamic viscosity";
  algorithm
    eta := 0.116e-3*exp(3755/T);
    annotation (Inline=true, Documentation(info="<html>
<p>From <code>TRANSFORM.Media.Fluids.FLiBe.Utilities_64LiF_30BeF2_5ZrF4_1UF4_CrFeNi.eta_T</code>.
It is the generic FLiBe viscosity of <code>Utilities_FLiBe</code> verbatim (ORNL/TM-2006/12
Fig. 10 by that file's own comment), not a fuel-salt-specific fit. 6.81e-3 Pa.s at 922 K against
7.57e-3 Pa.s for the correlation this library uses.</p>
</html>"));
  end eta_TRANSFORM;

  annotation (Documentation(info="<html>
<h4>Status of each correlation</h4>
<table border=\"1\">
<tr><th>Property</th><th>Correlation</th><th>Source level</th><th>Composition</th><th>Valid range</th></tr>
<tr><td>density</td><td><code>2575 - 0.513*T[degC]</code></td>
    <td><b>corroborated</b> &mdash; identical in TRANSFORM's own MSRE medium and in Mao Eq. (10);
        the report number itself is <b>source-unverified</b>, see below</td>
    <td>LiF-BeF2-ZrF4-UF4 65-29.1-5-0.9 mol% as declared here; TRANSFORM declares
        64.1-30.0-5.0-0.809 for the same expression</td>
    <td><b>not established</b> &mdash; no document stating it has been opened</td></tr>
<tr><td>specific heat</td><td><code>1967</code> constant</td>
    <td><b>source-unverified</b>. 0.47 Btu/(lb.degF) is the value common to the published MSRE
        models, but no primary document has been checked</td>
    <td>assumed the same salt</td><td><b>not established</b></td></tr>
<tr><td>dynamic viscosity</td><td><code>8.94e-5*exp(4092/T[K])</code></td>
    <td><b>source-unverified</b>. Not TRANSFORM's, not obviously ORNL's; origin unidentified</td>
    <td>assumed the same salt</td><td><b>not established</b></td></tr>
<tr><td>thermal conductivity</td><td><code>1.44</code> constant</td>
    <td><b>source-unverified</b>. Consistent with the MSRE-era value; modern fluoride-salt
        reviews and TRANSFORM both sit near 1.0</td>
    <td>assumed the same salt</td><td><b>not established</b></td></tr>
</table>

<p>Every one of the four temperature ranges is unestablished. The library evaluates them over
800&ndash;1000 K in <code>docs/verification/property_check.py</code> because that brackets the
MSRE operating range, <b>not</b> because any source has been shown to license that range.</p>

<h4>The density is now corroborated against code, not only against prose</h4>
<p>TRANSFORM ships
<code>TRANSFORM.Media.Fluids.FLiBe.LinearFLiBe_64LiF_30BeF2_5ZrF4_1UF4_CrFeNi</code>, an MSRE
fuel salt. Its <code>d_T</code> is <code>(2.575 - 5.13e-4*(T-273.15))*1000</code>, which is this
library's <code>2575 - 0.513*(T-273.15)</code> rearranged. The agreement is exact, and it also
holds for the way <code>beta_const</code> is derived: TRANSFORM's 2.22586e-4 is
<code>0.513/rho(800 K)</code> and this library's 2.2880e-4 is <code>0.513/rho(922 K)</code>,
each at its own reference temperature. This closes <b>O-5</b>.</p>

<h4>But TRANSFORM's medium must not be adopted wholesale</h4>
<p>O-5 asked whether the built-in could replace <code>MSRE.Media.FuelSalt</code>. It cannot,
and the reason is visible in TRANSFORM's own tree: its MSRE fuel salt takes cp, mu and k from
the pure-FLiBe and coolant-salt utilities and substitutes <b>only</b> the density.</p>
<table border=\"1\">
<tr><th>at 922 K</th><th>this library</th><th>TRANSFORM MSRE fuel salt</th><th>TRANSFORM coolant (FLiBe)</th></tr>
<tr><td>density [kg/m3]</td><td>2242.1</td><td>2242.1 &nbsp;(identical)</td><td>1942</td></tr>
<tr><td>specific heat [J/(kg.K)]</td><td>1967</td><td>2386.5</td><td>2386.5 &nbsp;(same)</td></tr>
<tr><td>viscosity [Pa.s]</td><td>7.57e-3</td><td>6.81e-3</td><td>6.81e-3 &nbsp;(same)</td></tr>
<tr><td>thermal conductivity [W/(m.K)]</td><td>1.44</td><td>1.0</td><td>1.0038 &nbsp;(same)</td></tr>
</table>
<p>The specific heat is the clearest case. TRANSFORM's fuel salt uses
<code>from_cal_gK(0.57)</code> and its coolant salt uses <code>from_btu_lbF(0.57)</code>; those
two unit functions differ but 1 cal/(g.K) and 1 Btu/(lb.degF) are the same magnitude, so both
land on 2386.5 J/(kg.K). The fuel salt carries ZrF4 and UF4 and is about 15 % denser than the
coolant salt, so its specific heat <i>per unit mass</i> must be <b>lower</b> than pure FLiBe's.
0.47 &lt; 0.57 has the right sense; 0.57 for both does not. This library's value is the more
defensible of the two, and that is an argument from physical reasoning, not from a source.</p>

<h4>The report number does not check out, and has not been resolved</h4>
<p>This library cited the density to &quot;ORNL-TM-4865&quot;, and TRANSFORM's own source
comment reads <code>// ORNL-TM-4865 Table 2.1 and 2.2</code>, so the two agree. Every
bibliographic catalogue reachable from the environment this was written in, however, returns
the title <i>Fission Product Behavior in the Molten Salt Reactor Experiment</i> (Compere,
Bohlmann, Kirslis, Blankenship and Grimes, October 1975) under <b>ORNL-4865</b>, without the
&quot;TM&quot;. Those are different report series.</p>
<p><b>Neither document could be opened</b> &mdash; every document host was refused by the
network egress proxy &mdash; so this is recorded as a discrepancy rather than corrected. The
citations in the library have deliberately <b>not</b> been rewritten to ORNL-4865: substituting
one unverified number for another would not be an improvement. What is certain is that the
title and the number currently printed together in this library are not a pair that any
reachable catalogue recognises, and that no page, table or equation reference can be given for
any of the four correlations. See open item O-10 in <code>docs/PHASE_LOG.md</code>.</p>

<h4>Jeong et al. (2026) do not publish theirs</h4>
<p>The reference paper states only that <q>molten salt thermophysical property models were
implemented in the MARS code first</q> and refers to two earlier papers for them. No correlation
and no property value appears in the paper itself, so <b>none of the four correlations here may
be described as Jeong exact</b>; all four are a surrogate set. What the paper does report is the
transit times, and those constrain the density without any correlation being quoted, because a
transit time multiplied by a mass flow rate is a mass. That indirect route is worked out in
<a href=\"modelica://MSRE.Verification.Properties_TransitTime\">Properties_TransitTime</a> and
it turns out to be sharp enough to be useful. It constrains the density only; cp, mu and k are
untouched by it.</p>

<h4>What each property can and cannot affect</h4>
<p>The ordering below is why the density was traced first, and it also bounds how much the three
open properties matter for the zero-power pump benchmark:</p>
<ul>
<li><b>density</b> converts volumes into transit times, and paper Eq. 8 depends on the transit
times and nothing else. It carries the benchmark.</li>
<li><b>viscosity</b> reaches the result through the channel Reynolds number, which is about 855
&mdash; laminar, so the channel pressure drop is proportional to velocity rather than its
square, and the viscosity is the only unfitted mechanism that can redistribute flow between
rings. An 11 % viscosity difference against TRANSFORM is therefore not negligible for the
ring-level flow split, even though it is negligible for the loop total (the core friction is
0.08 % of the loop pressure drop).</li>
<li><b>specific heat</b> does not enter the zero-power tests at all. The 17.6 % gap against
TRANSFORM is inert at 100 W and becomes first-order at 8 MW.</li>
<li><b>thermal conductivity</b> acts only through heat transfer, which is negligible at 100 W.
The 44 % gap is inert for the pump tests and matters for the full-power and natural-circulation
cases.</li>
</ul>
<p>None of that is a reason to leave three properties untraced before a full-power result is
reported.</p>
</html>"));
end MSRE_Properties;
