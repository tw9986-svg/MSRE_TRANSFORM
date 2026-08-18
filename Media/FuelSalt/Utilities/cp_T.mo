within MSRE.Media.FuelSalt.Utilities;
function cp_T "Specific heat capacity of the MSRE fuel salt"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.SpecificHeatCapacity cp "Specific heat capacity";
algorithm
  cp := 2009.66;
  annotation (Inline=true, Documentation(info="<html>
<p>2009.66 J/(kg.K), constant, from S. Cantor, ORNL-TM-2316 (1968), as tabulated by INL for the
MSRE fuel salt LiF-BeF2-ZrF4-UF4.</p>

<p>This replaced 1967 J/(kg.K), which was the value common to the published MSRE models but which
no primary document had been checked for. The two are 2.2 % apart, so nothing that depends on the
specific heat moves appreciably; what changes is that the number now has a source.</p>

<p>TRANSFORM's MSRE fuel salt medium carries 2386.5 J/(kg.K), which is <i>the coolant salt's</i>
value reused (<code>from_cal_gK(0.57)</code> against the coolant's <code>from_btu_lbF(0.57)</code>,
the same magnitude written two ways). Cantor's 2009.66 is 16 % below it, in the direction physical
reasoning requires: the fuel salt carries ZrF4 and UF4 and is about 15 % denser than pure FLiBe, so
its specific heat per unit mass must be lower. The argument for preferring this library's value
over TRANSFORM's is now a source rather than an inference.</p>

<p>The specific heat does not enter the zero-power pump tests at all; it matters only for the
full-power and natural-circulation cases.</p>
</html>"));
end cp_T;
