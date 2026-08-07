within MSRE.Media.FuelSalt.Utilities;
function lambda_T "Thermal conductivity of the MSRE fuel salt"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.ThermalConductivity lambda "Thermal conductivity";
algorithm
  lambda := 1.44;
  annotation (Inline=true, Documentation(info="<html>
<p>0.83 Btu/(hr.ft.degF).</p>
</html>"));
end lambda_T;
