within MSRE.Media.FuelSalt.Utilities;
function d_T "Density of the MSRE fuel salt (Compere et al., 1975)"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.Density d "Density";
algorithm
  d := 2575.0 - 0.513*(T - 273.15);
  annotation (Inline=true, Documentation(info="<html>
<p>LiF-BeF2-ZrF4-UF4 (65-29.1-5-0.9 mol%), attributed to Compere et al., <i>Fission Product
Behavior in the Molten Salt Reactor Experiment</i> (1975):</p>

<p><code>rho [kg/m3] = 2575 - 0.513*T [degC]</code></p>

<p>2249 kg/m3 at 908 K, 2242 kg/m3 at 922 K. The <code>- 273.15</code> is not a units slip: the
original correlation is stated on a Celsius argument, and reading it with a kelvin argument
would give 2102 kg/m3 at 922 K, 6.2 % low.</p>

<p>The same correlation appears as Eq. (10) of Mao et al., Energies (2026), and it is
<b>character for character</b> the density of the MSRE fuel salt medium TRANSFORM ships
(<code>TRANSFORM.Media.Fluids.FLiBe.LinearFLiBe_64LiF_30BeF2_5ZrF4_1UF4_CrFeNi</code>, whose
<code>d_T</code> reads <code>(2.575 - 5.13e-4*(T-273.15))*1000</code>). Three independent MSRE
modelling efforts therefore carry the identical expression.</p>

<h4>The report number is unresolved</h4>
<p>This correlation was previously cited here as ORNL-<b>TM</b>-4865, which is also what
TRANSFORM's own source comment says. Reachable bibliographic catalogues place that title,
those authors and that year under <b>ORNL-4865</b>, a different series. Neither document could
be opened from the environment this note was written in, so the number has been left out of the
function comment rather than replaced with a second unverified one, and <b>no page, table or
equation reference can be given</b>. See open item O-10 in <code>docs/PHASE_LOG.md</code> and
<a href=\"modelica://MSRE.Media.MSRE_Properties\">MSRE_Properties</a>.</p>

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
