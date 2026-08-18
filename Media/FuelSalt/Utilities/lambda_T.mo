within MSRE.Media.FuelSalt.Utilities;
function lambda_T "Thermal conductivity of the MSRE fuel salt"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.ThermalConductivity lambda "Thermal conductivity";
algorithm
  lambda := 1.0;
  annotation (Inline=true, Documentation(info="<html>
<p>1.0 W/(m.K), constant, from S. Cantor, ORNL-TM-2316 (1968), as tabulated by INL for the MSRE
fuel salt.</p>

<p>This replaced 1.44 W/(m.K), which had no traceable source and was the outlier of every value
available: Cantor gives 1.0, TRANSFORM's MSRE fuel salt medium codes 1.0, and modern fluoride-salt
reviews sit near 1.0 as well. 1.44 was 44 % above all of them.</p>

<p>The conductivity acts only through the salt-side heat transfer coefficient. It does not reach
the zero-power pump tests, where the ring-to-ring temperature spread is under a microkelvin, but
it does reach the full-power steady state and the natural-circulation case, and the shell-side
heat exchanger calibration (<code>f_shellHT</code>, <code>Nu_floor_shell</code>) was tuned with
the old value and will need rechecking there.</p>
</html>"));
end lambda_T;
