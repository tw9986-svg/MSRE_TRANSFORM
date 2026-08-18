within MSRE.Media.FuelSalt.Utilities;
function lambda_T "Thermal conductivity of the MSRE fuel salt (Cantor, ORNL-TM-2316)"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.ThermalConductivity lambda "Thermal conductivity";
algorithm
  lambda := 1.0;
  annotation (Inline=true, Documentation(info="<html>
<p><code>k = 1.0 W/(m.K)</code>, constant, for LiF-BeF2-ZrF4-UF4 (65.0-29.17-5.0-0.83 mol%),
from S. Cantor, ORNL-TM-2316 (1968), as used by the INL MSRE VTB/SAM fuel-salt equation of
state. The temperature argument is unused and kept only so that the signature matches the
other correlations.</p>
<p>The previous value, 1.44 W/(m.K) (0.83 Btu/(hr.ft.degF)), is retained for reference as
<a href=\"modelica://MSRE.Media.MSRE_Properties.lambda_legacy\">MSRE_Properties.lambda_legacy</a>.</p>
</html>"));
end lambda_T;
