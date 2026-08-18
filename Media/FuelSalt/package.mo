within MSRE.Media;
package FuelSalt
  "MSRE fuel salt LiF-BeF2-ZrF4-UF4 (65-29.1-5-0.9 mol%) | linear compressibility"

  extends TRANSFORM.Media.Interfaces.Fluids.PartialLinearFluid(
    mediumName="MSRE fuel salt",
    constantJacobian=false,
    reference_p=1e5,
    reference_T=922.0,
    reference_d=Utilities.d_T(reference_T),
    reference_h=Utilities.cp_T(reference_T)*(reference_T - 273.15),
    reference_s=0,
    beta_const=2.2880e-4,
    kappa_const=2.89e-10,
    cp_const=Utilities.cp_T(reference_T),
    MM_const=0.0331,
    T_default=922.0);

  redeclare function extends dynamicViscosity "Dynamic viscosity"
  algorithm
    eta := Utilities.eta_T(state.T);
    annotation (Inline=true);
  end dynamicViscosity;

  redeclare function extends thermalConductivity "Thermal conductivity"
  algorithm
    lambda := Utilities.lambda_T(state.T);
    annotation (Inline=true);
  end thermalConductivity;

  function massFraction "Return independent mass fractions (if any)"
    extends Modelica.Icons.Function;
    input ThermodynamicState state "Thermodynamic state record";
    output MassFraction Xi[nXi] "Independent mass fractions";
  algorithm
    Xi := fill(0, 0);
    annotation (Documentation(info="<html>
<p>Required by <code>Modelica.Media.Interfaces.PartialMedium</code> as of MSL 4.1.0 and absent
from the TRANSFORM media hierarchy; see
<a href=\"modelica://MSRE.Media\">MSRE.Media</a> for why it is declared here rather than
inherited. The salt is a single substance, so <code>nXi</code> is zero and there is nothing to
return. This is the same body MSL gives
<code>Modelica.Media.Interfaces.PartialPureSubstance.massFraction</code>.</p>
</html>"));
  end massFraction;

  annotation (Documentation(info="<html>
<h4>Property correlations</h4>
<table border=\"1\">
<tr><th>Property</th><th>Correlation</th><th>Value at 922 K</th></tr>
<tr><td>density</td><td>2575 - 0.513*T [degC]</td><td>2242 kg/m3</td></tr>
<tr><td>specific heat</td><td>2009.66 [J/(kg.K)] (constant)</td><td>2009.66 J/(kg.K)</td></tr>
<tr><td>dynamic viscosity</td><td>8.4e-5*exp(4340/T) [Pa.s]</td><td>9.30e-3 Pa.s (9.3 cP)</td></tr>
<tr><td>thermal conductivity</td><td>1.0 [W/(m.K)] (constant)</td><td>1.0 W/(m.K)</td></tr>
</table>
<p>The isobaric expansion coefficient <code>beta_const</code> follows from the density fit,
<code>0.513/2242 = 2.288e-4 1/K</code>. The isothermal compressibility
<code>kappa_const</code> is taken from the TRANSFORM FLiBe model; the primary system is
essentially incompressible at MSRE conditions so this value only sets the (stiff)
acoustic time scale.</p>
<p><b>Three of the four now carry a primary source and one does not.</b> The specific heat,
viscosity and conductivity are from S. Cantor, ORNL-TM-2316 (1968), as tabulated by INL for the
MSRE fuel salt, and they replaced values that had no traceable origin. What they replaced, and by
how much:</p>
<table border=\"1\">
<tr><th>at 922 K</th><th>previously</th><th>now (Cantor)</th><th>change</th><th>TRANSFORM MSRE medium</th></tr>
<tr><td>specific heat [J/(kg.K)]</td><td>1967</td><td>2009.66</td><td>+2.2 %</td><td>2386.5</td></tr>
<tr><td>viscosity [Pa.s]</td><td>7.57e-3</td><td>9.30e-3</td><td>+23 %</td><td>6.81e-3</td></tr>
<tr><td>conductivity [W/(m.K)]</td><td>1.44</td><td>1.0</td><td>-31 %</td><td>1.0</td></tr>
</table>
<p>The conductivity is the clearest gain: 1.44 was the outlier of every value available, while
Cantor, TRANSFORM and the modern fluoride-salt reviews all sit at 1.0. The specific heat barely
moves but is now sourced, and it settles the disagreement with TRANSFORM in this library's favour
&mdash; TRANSFORM reuses the coolant salt's 2386.5 for the fuel salt, which physical reasoning
already argued had to be too high.</p>

<p>The <b>density is the one still without a primary source</b>, and it is the property the
benchmark is most sensitive to. It has corroboration rather than tracing: the identical expression
is carried by Mao et al. Eq. (10) and, character for character, by the MSRE fuel salt medium
TRANSFORM ships. Cantor's own density correlation, <code>2553.3 - 0.562*T</code>, is a different
one, and the INL tabulation of it does not state whether T is in kelvin or Celsius &mdash; read as
kelvin it gives 2035 kg/m3 at 922 K, read as Celsius 2189, against 2242 here. That ambiguity is
unresolved and is tracked as an open item; see
<a href=\"modelica://MSRE.Media.MSRE_Properties\">MSRE_Properties</a> for it, for the reason
TRANSFORM's medium is not adopted whole, and for the unresolved report number.</p>

<p>No valid temperature range has been established for any of the four.</p>

<p>Jeong et al. (2026) publish no property correlations and no property values, so <b>no
correlation here may be described as Jeong exact</b>. This is a surrogate set throughout.</p>

<p>The density carries the benchmark, which is why it was the one worth tracing: it converts
the fuel salt volumes into the transit times, and the transit times are the only thing paper
Eq. 8 depends on. The specific heat does not enter the zero-power tests at all, and the
viscosity and conductivity act only through the friction and the heat transfer, neither of
which the pump tests are sensitive to at 100 W.</p>
</html>"));
end FuelSalt;
