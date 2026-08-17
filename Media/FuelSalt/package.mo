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
<tr><td>specific heat</td><td>1967 [J/(kg.K)] (constant)</td><td>1967 J/(kg.K)</td></tr>
<tr><td>dynamic viscosity</td><td>8.94e-5*exp(4092/T) [Pa.s]</td><td>7.56e-3 Pa.s (7.6 cP)</td></tr>
<tr><td>thermal conductivity</td><td>1.44 [W/(m.K)] (constant)</td><td>1.44 W/(m.K)</td></tr>
</table>
<p>The isobaric expansion coefficient <code>beta_const</code> follows from the density fit,
<code>0.513/2242 = 2.288e-4 1/K</code>. The isothermal compressibility
<code>kappa_const</code> is taken from the TRANSFORM FLiBe model; the primary system is
essentially incompressible at MSRE conditions so this value only sets the (stiff)
acoustic time scale.</p>
<p><b>None of the four has been traced to a primary source.</b> No document host was reachable
from the environment in which this was last reviewed, so no page, table or equation reference
can be given for any of them, and no valid temperature range has been established for any of
them. What separates the density from the other three is <i>corroboration</i>, not tracing: the
identical expression is carried by Mao et al. Eq. (10) and, character for character, by the MSRE
fuel salt medium TRANSFORM itself ships. The other three are the values commonly used in the
published MSRE benchmark models, carried over unchanged, and all three disagree with TRANSFORM's
MSRE medium &mdash; by 17.6 % (cp), 11 % (mu) and 44 % (k). All four are collected in
<a href=\"modelica://MSRE.Media.FuelSalt.Utilities\">Utilities</a> so that they can be replaced
in one place, and their provenance, the reason TRANSFORM's medium is <i>not</i> adopted whole,
and the unresolved report number are set out in
<a href=\"modelica://MSRE.Media.MSRE_Properties\">MSRE_Properties</a>.</p>

<p>Jeong et al. (2026) publish no property correlations and no property values, so <b>no
correlation here may be described as Jeong exact</b>. This is a surrogate set throughout.</p>

<p>The density carries the benchmark, which is why it was the one worth tracing: it converts
the fuel salt volumes into the transit times, and the transit times are the only thing paper
Eq. 8 depends on. The specific heat does not enter the zero-power tests at all, and the
viscosity and conductivity act only through the friction and the heat transfer, neither of
which the pump tests are sensitive to at 100 W.</p>
</html>"));
end FuelSalt;
