within MSRE.Media.FuelSalt.Utilities;
function d_T "Density of the MSRE fuel salt (Cantor, ORNL-TM-2316)"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.Density d "Density";
algorithm
  d := 2553.3 - 0.562*(T - 273.15);
  annotation (Inline=true, Documentation(info="<html>
<p>LiF-BeF2-ZrF4-UF4 (65.0-29.17-5.0-0.83 mol%), from S. Cantor, <i>Physical Properties of
Molten-Salt Reactor Fuel, Coolant, and Flush Salts</i>, ORNL-TM-2316 (1968), which is the
source the INL MSRE VTB/SAM model cites for its fuel-salt equation of state:</p>

<p><code>rho [kg/m3] = 2553.3 - 0.562*T [degC]</code></p>

<h4>The argument is degrees Celsius, not kelvin</h4>
<p>The correlation as published takes <b>degC</b>. Modelica temperatures are in kelvin, so the
implementation must convert, which is the <code>(T - 273.15)</code> above. Written as
<code>2553.3 - 0.562*T[K]</code> it would give 2035 kg/m3 at 922 K instead of 2189 kg/m3, a
7 % error of exactly the kind this library has already been bitten by once. The conversion is
checked against the INL SAM implementation, which evaluates the same fit at 476.85 degC
(750 K) and reports 2285.31 kg/m3.</p>

<h4>Values over the MSRE operating range</h4>
<table border=\"1\">
<tr><th>T</th><th>rho [kg/m3]</th></tr>
<tr><td>908 K (core inlet)</td><td>2196.51</td></tr>
<tr><td>922 K (core average, reference)</td><td>2188.65</td></tr>
<tr><td>936 K (core outlet)</td><td>2180.78</td></tr>
</table>

<p>This replaced the Compere et al. ORNL-TM-4865 (1975) correlation
<code>2575 - 0.513*T[degC]</code> (2242 kg/m3 at 922 K), which is retained for reference as
<a href=\"modelica://MSRE.Media.MSRE_Properties.d_Compere\">MSRE_Properties.d_Compere</a>. The
density is what converts the fuel salt volumes into the transit times, and the transit times
are the only thing paper Eq. 8 depends on, so the change is not cosmetic - see
<a href=\"modelica://MSRE.Verification.Properties_TransitTime\">Properties_TransitTime</a> and
<a href=\"modelica://MSRE.Media.MSRE_Properties\">MSRE_Properties</a>.</p>
</html>"));
end d_T;
