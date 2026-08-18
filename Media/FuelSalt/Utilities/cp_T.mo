within MSRE.Media.FuelSalt.Utilities;
function cp_T "Specific heat capacity of the MSRE fuel salt (Cantor, ORNL-TM-2316)"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.SpecificHeatCapacity cp "Specific heat capacity";
algorithm
  cp := 2009.66;
  annotation (Inline=true, Documentation(info="<html>
<p><code>cp = 2009.66 J/(kg.K)</code>, constant, for LiF-BeF2-ZrF4-UF4
(65.0-29.17-5.0-0.83 mol%). This is the value the INL MSRE VTB/SAM fuel-salt equation of state
uses, traced to S. Cantor, ORNL-TM-2316 (1968). It is reported as temperature independent over
the MSRE operating range, so the temperature argument is unused and kept only so that the
signature matches the other correlations.</p>
<p>The previous value, 1967 J/(kg.K) (0.47 Btu/(lb.degF)), is retained for reference as
<a href=\"modelica://MSRE.Media.MSRE_Properties.cp_legacy\">MSRE_Properties.cp_legacy</a>.</p>
</html>"));
end cp_T;
