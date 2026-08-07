within MSRE.Media.FuelSalt.Utilities;
function cp_T "Specific heat capacity of the MSRE fuel salt"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.SpecificHeatCapacity cp "Specific heat capacity";
algorithm
  cp := 1967;
  annotation (Inline=true, Documentation(info="<html>
<p>0.47 Btu/(lb.degF), reported as temperature independent over the MSRE operating range.</p>
</html>"));
end cp_T;
