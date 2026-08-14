within MSRE.Media;
package MSRE_Properties
  "Provenance of the MSRE fuel salt property correlations, and the alternatives they were chosen over"
  extends Modelica.Icons.Package;

  function d_Compere "Fuel salt density, Compere et al., ORNL-TM-4865 (1975)"
    extends Modelica.Icons.Function;
    input SI.Temperature T "Temperature";
    output SI.Density d "Density";
  algorithm
    d := 2575.0 - 0.513*(T - 273.15);
    annotation (Inline=true, Documentation(info="<html>
<p><code>rho [kg/m3] = 2575 - 0.513*T [degC]</code>, for LiF-BeF2-ZrF4-UF4 65-29.1-5-0.9 mol%.
This is the correlation the library uses; <a href=\"modelica://MSRE.Media.FuelSalt.Utilities.d_T\">
FuelSalt.Utilities.d_T</a> is the same expression.</p>
<p>It also appears as Eq. (10) of Mao et al., Energies (2026), and it is the correlation behind
the LiF-BeF2-ZrF4-UF4 medium that TRANSFORM ships, which Fischer et al. (2024) used. Three
independent MSRE modelling efforts therefore agree on it.</p>
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

  annotation (Documentation(info="<html>
<h4>What is traced and what is not</h4>
<table border=\"1\">
<tr><th>Property</th><th>Correlation</th><th>Source</th><th>Traced?</th></tr>
<tr><td>density</td><td><code>2575 - 0.513*T[degC]</code></td>
    <td>Compere et al., ORNL-TM-4865 (1975)</td><td><b>yes</b></td></tr>
<tr><td>specific heat</td><td><code>1967</code> constant</td>
    <td>the value common to the published MSRE models</td><td>no</td></tr>
<tr><td>dynamic viscosity</td><td><code>8.94e-5*exp(4092/T[K])</code></td>
    <td>as above</td><td>no</td></tr>
<tr><td>thermal conductivity</td><td><code>1.44</code> constant</td>
    <td>as above</td><td>no</td></tr>
</table>

<p>Only the density has been traced to a primary source, and that is a deliberate ordering
rather than an unfinished job: the density is the property the benchmark is sensitive to. It
converts the fuel salt volumes into the transit times, and the transit times are the only thing
paper Eq. 8 depends on. The other three do not reach the zero-power pump tests: the specific
heat does not enter them at all, and the viscosity and conductivity act through friction and
heat transfer, neither of which matters at 100 W. They should still be traced before any
full-power result is reported.</p>

<h4>Jeong et al. (2026) do not publish theirs</h4>
<p>The reference paper states only that <q>molten salt thermophysical property models were
implemented in the MARS code first</q> and refers to two earlier papers for them. No
correlation and no property value appears in the paper itself, so the MARS properties cannot be
compared against these directly. What the paper does report is the transit times, and those
constrain the density without any correlation being quoted, because a transit time multiplied
by a mass flow rate is a mass. That indirect route is worked out in
<a href=\"modelica://MSRE.Verification.Properties_TransitTime\">Properties_TransitTime</a> and
it turns out to be sharp enough to be useful.</p>
</html>"));
end MSRE_Properties;
