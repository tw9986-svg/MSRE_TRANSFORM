within MSRE.Media.FuelSalt.Utilities;
function eta_T "Dynamic viscosity of the MSRE fuel salt (Cantor, ORNL-TM-2316)"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.DynamicViscosity eta "Dynamic viscosity";
algorithm
  eta := 8.4e-5*exp(4340/T);
  annotation (Inline=true, Documentation(info="<html>
<p><code>mu [Pa.s] = 8.4e-5*exp(4340/T [K])</code> for LiF-BeF2-ZrF4-UF4
(65.0-29.17-5.0-0.83 mol%), from S. Cantor, ORNL-TM-2316 (1968), as used by the INL MSRE
VTB/SAM fuel-salt equation of state. Unlike the density fit, the argument of this one is
<b>kelvin</b>, so no conversion is applied.</p>
<table border=\"1\">
<tr><th>T</th><th>mu [Pa.s]</th></tr>
<tr><td>908 K</td><td>1.0000e-2</td></tr>
<tr><td>922 K</td><td>9.3025e-3</td></tr>
<tr><td>936 K</td><td>8.6702e-3</td></tr>
</table>
<p>The previous correlation, <code>8.94e-5*exp(4092/T)</code> (7.56e-3 Pa.s at 922 K), is
retained for reference as
<a href=\"modelica://MSRE.Media.MSRE_Properties.eta_legacy\">MSRE_Properties.eta_legacy</a>.</p>
</html>"));
end eta_T;
