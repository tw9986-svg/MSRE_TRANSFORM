within MSRE.Media.FuelSalt.Utilities;
function d_T "Density of the MSRE fuel salt"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.Density d "Density";
algorithm
  d := 2575.3 - 0.5641*T;
  annotation (Inline=true, Documentation(info="<html>
<p>LiF-BeF2-ZrF4-UF4 (65-29.1-5-0.9 mol%). 2055 kg/m3 at 922 K, 2063 kg/m3 at 908 K.</p>
</html>"));
end d_T;
