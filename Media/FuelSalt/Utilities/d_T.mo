within MSRE.Media.FuelSalt.Utilities;
function d_T "Density of the MSRE fuel salt (Compere et al., ORNL-TM-4865)"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.Density d "Density";
algorithm
  d := 2575.0 - 0.513*(T - 273.15);
  annotation (Inline=true, Documentation(info="<html>
<p>LiF-BeF2-ZrF4-UF4 (65-29.1-5-0.9 mol%), from Compere et al., <i>Fission Product Behavior in
the Molten Salt Reactor Experiment</i>, ORNL-TM-4865 (1975):</p>

<p><code>rho [kg/m3] = 2575 - 0.513*T [degC]</code></p>

<p>2249 kg/m3 at 908 K, 2242 kg/m3 at 922 K. The same correlation appears as Eq. (10) of
Mao et al., Energies (2026), and it is the correlation behind the LiF-BeF2-ZrF4-UF4 properties
that TRANSFORM ships, which is what Fischer et al. (2024) used.</p>

<h4>This replaced a correlation that was about 9 % low</h4>
<p>The library previously used <code>rho = 2575.3 - 0.5641*T [K]</code>, which gives
2063 kg/m3 at 908 K against the 2249 kg/m3 above. The constant is the same 2575 but the
argument is in kelvin rather than degrees Celsius, which is the signature of the degC
correlation having been read with a kelvin argument and the slope then re-fitted to land near
the right value at one temperature.</p>

<p>The change matters because the density is what converts the fuel salt volumes into the
transit times, and the transit times are the only thing paper Eq. 8 depends on. See
<a href=\"modelica://MSRE.Verification.Properties_TransitTime\">Properties_TransitTime</a>,
which works out what the reported transit times imply about the density independently of any
volume, and <a href=\"modelica://MSRE.Media.MSRE_Properties\">MSRE_Properties</a> for the
provenance of each correlation.</p>
</html>"));
end d_T;
