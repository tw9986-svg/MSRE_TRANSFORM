within MSRE.Media.FuelSalt.Utilities;
function cp_T "Specific heat capacity of the MSRE fuel salt"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.SpecificHeatCapacity cp "Specific heat capacity";
algorithm
  cp := 1967;
  annotation (Inline=true, Documentation(info="<html>
<p>0.47 Btu/(lb.degF) = 1967.8 J/(kg.K), coded as 1967 (-0.04 %), and taken as temperature
independent over the MSRE operating range.</p>

<p><b>Source level: source-unverified.</b> 0.47 Btu/(lb.degF) is the value common to the
published MSRE models but no primary document stating it has been opened, and neither the
composition it belongs to nor its valid temperature range has been established.</p>

<p>TRANSFORM's own MSRE fuel salt medium instead codes <code>from_cal_gK(0.57)</code> =
2386.5 J/(kg.K), 21 % higher, which is the same number its <i>coolant</i> salt uses. The fuel
salt is about 15 % denser than the coolant salt because of the ZrF4 and UF4 it carries, so its
specific heat per unit mass should be the <b>lower</b> of the two, which is the sense 0.47 has
and 0.57 does not. That is an argument from physical reasoning and it is the reason this value
was kept, not a source. See
<a href=\"modelica://MSRE.Media.MSRE_Properties\">MSRE_Properties</a>.</p>

<p>The specific heat does not enter the zero-power pump tests at all, so the discrepancy is
inert for the present benchmark and first-order at full power.</p>
</html>"));
end cp_T;
