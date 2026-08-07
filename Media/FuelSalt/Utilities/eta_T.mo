within MSRE.Media.FuelSalt.Utilities;
function eta_T "Dynamic viscosity of the MSRE fuel salt"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.DynamicViscosity eta "Dynamic viscosity";
algorithm
  eta := 8.94e-5*exp(4092/T);
  annotation (Inline=true, Documentation(info="<html>
<p>7.6 cP at 922 K (1200 degF), matching the reported MSRE fuel-salt viscosity.</p>
</html>"));
end eta_T;
