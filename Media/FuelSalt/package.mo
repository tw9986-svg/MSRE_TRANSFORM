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
    beta_const=2.7448e-4,
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

  annotation (Documentation(info="<html>
<h4>Property correlations</h4>
<table border=\"1\">
<tr><th>Property</th><th>Correlation</th><th>Value at 922 K</th></tr>
<tr><td>density</td><td>2575.3 - 0.5641*T [kg/m3]</td><td>2055 kg/m3</td></tr>
<tr><td>specific heat</td><td>1967 [J/(kg.K)] (constant)</td><td>1967 J/(kg.K)</td></tr>
<tr><td>dynamic viscosity</td><td>8.94e-5*exp(4092/T) [Pa.s]</td><td>7.56e-3 Pa.s (7.6 cP)</td></tr>
<tr><td>thermal conductivity</td><td>1.44 [W/(m.K)] (constant)</td><td>1.44 W/(m.K)</td></tr>
</table>
<p>The isobaric expansion coefficient <code>beta_const</code> follows from the density fit,
<code>0.5641/2055 = 2.745e-4 1/K</code>. The isothermal compressibility
<code>kappa_const</code> is taken from the TRANSFORM FLiBe model; the primary system is
essentially incompressible at MSRE conditions so this value only sets the (stiff)
acoustic time scale.</p>
<p>These are the values commonly used in the published MSRE benchmark models
(ORNL-TM-728 and the MSRE code-to-code comparisons). They are collected in
<a href=\"modelica://MSRE.Media.FuelSalt.Utilities\">Utilities</a> so that they can be
replaced in one place.</p>
</html>"));
end FuelSalt;
