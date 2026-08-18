within MSRE.Media;
package FuelSalt
  "MSRE fuel salt LiF-BeF2-ZrF4-UF4 (65.0-29.17-5.0-0.83 mol%) | linear compressibility"

  extends TRANSFORM.Media.Interfaces.Fluids.PartialLinearFluid(
    mediumName="MSRE fuel salt",
    constantJacobian=false,
    reference_p=1e5,
    reference_T=922.0,
    reference_d=Utilities.d_T(reference_T),
    reference_h=Utilities.cp_T(reference_T)*(reference_T - 273.15),
    reference_s=0,
    beta_const=2.5678e-4,
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

  /* Modelica Standard Library 4.1.0 added the function massFraction to
     Modelica.Media.Interfaces.PartialMedium. TRANSFORM does not extend that package: it keeps its
     own copy of the media interfaces (TRANSFORM.Media.Interfaces.Fluids.PartialMedium), so a
     TRANSFORM-based medium such as this one only matches Modelica.Media.Interfaces.PartialMedium
     structurally. The added function breaks that match, and then every
     `redeclare package Medium` of a Modelica.Fluid or TRANSFORM component fails with
     "Redeclaration requires a subtype ... missing public function massFraction". Declaring it
     here restores the match. The body is the one MSL gives in PartialPureSubstance: the salt is a
     single substance (fixedX = true), so nXi = 0 and the returned vector is empty. It is inert
     under MSL 4.0.0, where nothing calls it. */
  function massFraction "Return independent mass fractions (if any)"
    extends Modelica.Icons.Function;
    input ThermodynamicState state "Thermodynamic state record";
    output MassFraction Xi[nXi] "Independent mass fractions";
  algorithm
    Xi := fill(0, 0);
    annotation (Inline=true);
  end massFraction;

  annotation (Documentation(info="<html>
<h4>Property correlations</h4>
<p>All four are those of S. Cantor, <i>Physical Properties of Molten-Salt Reactor Fuel,
Coolant, and Flush Salts</i>, ORNL-TM-2316 (1968), for LiF-BeF2-ZrF4-UF4
65.0-29.17-5.0-0.83 mol%, in the form the INL MSRE VTB/SAM model uses them.</p>
<table border=\"1\">
<tr><th>Property</th><th>Correlation</th><th>Value at 922 K</th></tr>
<tr><td>density</td><td>2553.3 - 0.562*T [degC]</td><td>2188.65 kg/m3</td></tr>
<tr><td>specific heat</td><td>2009.66 [J/(kg.K)] (constant)</td><td>2009.66 J/(kg.K)</td></tr>
<tr><td>dynamic viscosity</td><td>8.4e-5*exp(4340/T [K]) [Pa.s]</td><td>9.30e-3 Pa.s (9.3 cP)</td></tr>
<tr><td>thermal conductivity</td><td>1.0 [W/(m.K)] (constant)</td><td>1.0 W/(m.K)</td></tr>
</table>

<p>The density fit takes its argument in <b>degrees Celsius</b> and the viscosity fit takes its
argument in <b>kelvin</b>; the conversion in
<a href=\"modelica://MSRE.Media.FuelSalt.Utilities.d_T\">d_T</a> is therefore load bearing, and
writing the density as <code>2553.3 - 0.562*T[K]</code> would be wrong by 7 %.</p>

<h4>Values over the MSRE operating range</h4>
<table border=\"1\">
<tr><th>T</th><th>rho [kg/m3]</th><th>mu [Pa.s]</th><th>cp [J/(kg.K)]</th><th>k [W/(m.K)]</th></tr>
<tr><td>908 K (core inlet)</td><td>2196.51</td><td>1.0000e-2</td><td>2009.66</td><td>1.0</td></tr>
<tr><td>922 K (core average)</td><td>2188.65</td><td>9.3025e-3</td><td>2009.66</td><td>1.0</td></tr>
<tr><td>936 K (core outlet)</td><td>2180.78</td><td>8.6702e-3</td><td>2009.66</td><td>1.0</td></tr>
</table>

<h4>Melting temperature</h4>
<p>Cantor gives <code>T_melt = 722.15 K</code> for this salt. The TRANSFORM
<code>PartialLinearFluid</code> interface carries no melting-temperature parameter and no
model in this library needs one, so it is recorded here and as
<a href=\"modelica://MSRE.Media.MSRE_Properties\">MSRE_Properties.T_melt_Cantor</a> rather than
added to the medium; the medium interface is deliberately left unchanged.</p>

<h4>Derived and retained parameters</h4>
<p><code>beta_const = 0.562/2188.65 = 2.5678e-4 1/K</code> is not an independent datum: it is
the isobaric expansion coefficient of the density fit above, evaluated at the reference
temperature, and it moves whenever the density fit moves.</p>
<p><code>kappa_const = 2.89e-10 1/Pa</code> (isothermal compressibility, taken from the
TRANSFORM FLiBe model) and <code>MM_const = 0.0331 kg/mol</code> are <b>retained existing model
assumptions - not modified in this property update</b>. No source for either was established
for the MSRE fuel salt in this pass, and the primary system is essentially incompressible at
MSRE conditions, so <code>kappa_const</code> only sets the (stiff) acoustic time scale.</p>

<h4>What this replaced</h4>
<p>The library previously carried a mixed set: the Compere et al. ORNL-TM-4865 (1975) density
<code>2575 - 0.513*T[degC]</code> together with cp, mu and k that had not been traced to any
primary source. Those four are preserved unchanged, and not used, in
<a href=\"modelica://MSRE.Media.MSRE_Properties\">MSRE_Properties</a>; only the functions in
<a href=\"modelica://MSRE.Media.FuelSalt.Utilities\">Utilities</a> are live. The two sets must
not be mixed - anything reported from this medium is Cantor throughout.</p>

<p>The density carries the benchmark, which is why it is the one to watch: it converts the
fuel salt volumes into the transit times, and the transit times are the only thing paper
Eq. 8 depends on. The specific heat does not enter the zero-power tests at all, and the
viscosity and conductivity act only through friction and heat transfer, neither of which the
pump tests are sensitive to at 100 W. The geometry record and the pump models were
deliberately <b>not</b> touched in this property update, so the transit times reported by
<a href=\"modelica://MSRE.Systems.PrimarySystem\">PrimarySystem</a> move with the new density.</p>
</html>"));
end FuelSalt;
