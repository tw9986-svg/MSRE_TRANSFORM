within MSRE.Media;
package MSRE_Properties
  "Provenance of the MSRE fuel salt property correlations, and the alternatives they were chosen over"
  extends Modelica.Icons.Package;

  function d_Cantor
    "ACTIVE fuel salt density, Cantor, ORNL-TM-2316 (1968)"
    extends Modelica.Icons.Function;
    input SI.Temperature T "Temperature";
    output SI.Density d "Density";
  algorithm
    d := 2553.3 - 0.562*(T - 273.15);
    annotation (Inline=true, Documentation(info="<html>
<p><code>rho [kg/m3] = 2553.3 - 0.562*T [degC]</code>, LiF-BeF2-ZrF4-UF4
65.0-29.17-5.0-0.83 mol%. This is the correlation the library uses;
<a href=\"modelica://MSRE.Media.FuelSalt.Utilities.d_T\">FuelSalt.Utilities.d_T</a> is the same
expression. The argument is degrees Celsius, hence the <code>(T - 273.15)</code>.</p>
<p>2196.51 kg/m3 at 908 K, 2188.65 kg/m3 at 922 K, 2180.78 kg/m3 at 936 K. Cross-checked
against the INL MSRE VTB/SAM fuel-salt equation of state, which evaluates the same fit at
476.85 degC and reports 2285.31 kg/m3.</p>
</html>"));
  end d_Cantor;

  function eta_Cantor "ACTIVE fuel salt dynamic viscosity, Cantor, ORNL-TM-2316 (1968)"
    extends Modelica.Icons.Function;
    input SI.Temperature T "Temperature";
    output SI.DynamicViscosity eta "Dynamic viscosity";
  algorithm
    eta := 8.4e-5*exp(4340/T);
    annotation (Inline=true, Documentation(info="<html>
<p><code>mu [Pa.s] = 8.4e-5*exp(4340/T [K])</code>. Same expression as
<a href=\"modelica://MSRE.Media.FuelSalt.Utilities.eta_T\">FuelSalt.Utilities.eta_T</a>.
9.3025e-3 Pa.s at 922 K. The argument of this fit is kelvin, unlike the density fit.</p>
</html>"));
  end eta_Cantor;

  function d_Compere
    "REFERENCE ONLY: fuel salt density, Compere et al., ORNL-TM-4865 (1975)"
    extends Modelica.Icons.Function;
    input SI.Temperature T "Temperature";
    output SI.Density d "Density";
  algorithm
    d := 2575.0 - 0.513*(T - 273.15);
    annotation (Inline=true, Documentation(info="<html>
<p><code>rho [kg/m3] = 2575 - 0.513*T [degC]</code>, for LiF-BeF2-ZrF4-UF4 65-29.1-5-0.9 mol%.
2249.3 kg/m3 at 908 K, 2242.1 kg/m3 at 922 K.</p>
<p><b>This is no longer the correlation the medium uses</b>: the fuel salt now runs on
<a href=\"modelica://MSRE.Media.MSRE_Properties.d_Cantor\">d_Cantor</a>. It is kept because
<a href=\"modelica://MSRE.Verification.Properties_TransitTime\">Properties_TransitTime</a> and
<a href=\"modelica://MSRE.Verification.Analytic_DriftReactivity\">Analytic_DriftReactivity</a>
call it explicitly, and because the volumes in
<a href=\"modelica://MSRE.Data.Geometry\">Data.Geometry</a> were derived against it. Do not mix
it with the Cantor set.</p>
<p>It also appears as Eq. (10) of Mao et al., Energies (2026), and it is the correlation behind
the LiF-BeF2-ZrF4-UF4 medium that TRANSFORM ships, which Fischer et al. (2024) used, so three
independent MSRE modelling efforts agree on it. The Cantor fit was preferred over it not
because it is better corroborated but because it comes with a matching cp, mu and k from the
same primary source, which this one does not.</p>
</html>"));
  end d_Compere;

  function d_legacy
    "REFERENCE ONLY: fuel salt density used by this library before Phase 2"
    extends Modelica.Icons.Function;
    input SI.Temperature T "Temperature";
    output SI.Density d "Density";
  algorithm
    d := 2575.3 - 0.5641*T;
    annotation (Inline=true, Documentation(info="<html>
<p><code>rho [kg/m3] = 2575.3 - 0.5641*T [K]</code>. Retained only so that
<a href=\"modelica://MSRE.Verification.Properties_TransitTime\">Properties_TransitTime</a> can
quantify what replacing it changed. Do not use it for results.</p>
<p>The constant is the same 2575 as the Compere correlation but the argument is in kelvin
rather than degrees Celsius, which is the signature of the degC correlation having been read
with a kelvin argument and the slope then re-fitted to land near the right value at one
temperature. It runs about 9 % low at MSRE conditions.</p>
</html>"));
  end d_legacy;

  function cp_legacy
    "REFERENCE ONLY: fuel salt specific heat used by this library before the Cantor update"
    extends Modelica.Icons.Function;
    input SI.Temperature T "Temperature";
    output SI.SpecificHeatCapacity cp "Specific heat capacity";
  algorithm
    cp := 1967;
    annotation (Inline=true, Documentation(info="<html>
<p><code>cp = 1967 J/(kg.K)</code>, i.e. 0.47 Btu/(lb.degF). The value common to the published
MSRE benchmark models; never traced to a primary source. Superseded by the Cantor value
2009.66 J/(kg.K) in
<a href=\"modelica://MSRE.Media.FuelSalt.Utilities.cp_T\">FuelSalt.Utilities.cp_T</a>. Retained
for comparison only - do not use it for results.</p>
</html>"));
  end cp_legacy;

  function eta_legacy
    "REFERENCE ONLY: fuel salt dynamic viscosity used by this library before the Cantor update"
    extends Modelica.Icons.Function;
    input SI.Temperature T "Temperature";
    output SI.DynamicViscosity eta "Dynamic viscosity";
  algorithm
    eta := 8.94e-5*exp(4092/T);
    annotation (Inline=true, Documentation(info="<html>
<p><code>mu [Pa.s] = 8.94e-5*exp(4092/T [K])</code>, 7.56e-3 Pa.s at 922 K against the
9.30e-3 Pa.s of the Cantor fit. Never traced to a primary source. Superseded by
<a href=\"modelica://MSRE.Media.FuelSalt.Utilities.eta_T\">FuelSalt.Utilities.eta_T</a>.
Retained for comparison only - do not use it for results.</p>
<p>Note that the temperature sensitivity discussion in
<a href=\"modelica://MSRE.Components.CoreChannel\">CoreChannel</a> quotes this correlation. Its
logarithmic slope is <code>-4092/T^2 = -0.481 %/K</code> at 922 K against
<code>-4340/T^2 = -0.511 %/K</code> for the Cantor fit, so that argument is unaffected in
substance.</p>
</html>"));
  end eta_legacy;

  function lambda_legacy
    "REFERENCE ONLY: fuel salt thermal conductivity used by this library before the Cantor update"
    extends Modelica.Icons.Function;
    input SI.Temperature T "Temperature";
    output SI.ThermalConductivity lambda "Thermal conductivity";
  algorithm
    lambda := 1.44;
    annotation (Inline=true, Documentation(info="<html>
<p><code>k = 1.44 W/(m.K)</code>, i.e. 0.83 Btu/(hr.ft.degF). Never traced to a primary source.
Superseded by the Cantor value 1.0 W/(m.K) in
<a href=\"modelica://MSRE.Media.FuelSalt.Utilities.lambda_T\">FuelSalt.Utilities.lambda_T</a>.
Retained for comparison only - do not use it for results.</p>
</html>"));
  end lambda_legacy;

  constant SI.Temperature T_melt_Cantor=722.15
    "Fuel salt melting temperature, Cantor ORNL-TM-2316 (1968). Recorded here because the TRANSFORM medium interface carries no melting-temperature parameter";

  annotation (Documentation(info="<html>
<h4>Active property set: Cantor, ORNL-TM-2316 (1968)</h4>
<p>The MSRE fuel salt medium runs on the property set of S. Cantor, <i>Physical Properties of
Molten-Salt Reactor Fuel, Coolant, and Flush Salts</i>, ORNL-TM-2316 (1968), for
LiF-BeF2-ZrF4-UF4 65.0-29.17-5.0-0.83 mol%, in the form used by the INL MSRE VTB/SAM model.
It is a single self-consistent set from one primary source; it must not be mixed with the
legacy values below.</p>
<table border=\"1\">
<tr><th>Property</th><th>Active (Cantor)</th><th>@ 922 K</th><th>Legacy (superseded)</th><th>@ 922 K</th></tr>
<tr><td>density</td><td><code>2553.3 - 0.562*T[degC]</code></td><td>2188.65 kg/m3</td>
    <td><code>2575 - 0.513*T[degC]</code> (Compere, ORNL-TM-4865)</td><td>2242.1 kg/m3</td></tr>
<tr><td>dynamic viscosity</td><td><code>8.4e-5*exp(4340/T[K])</code></td><td>9.3025e-3 Pa.s</td>
    <td><code>8.94e-5*exp(4092/T[K])</code> (untraced)</td><td>7.56e-3 Pa.s</td></tr>
<tr><td>specific heat</td><td><code>2009.66</code> constant</td><td>2009.66 J/(kg.K)</td>
    <td><code>1967</code> constant (untraced)</td><td>1967 J/(kg.K)</td></tr>
<tr><td>thermal conductivity</td><td><code>1.0</code> constant</td><td>1.0 W/(m.K)</td>
    <td><code>1.44</code> constant (untraced)</td><td>1.44 W/(m.K)</td></tr>
<tr><td>melting temperature</td><td><code>722.15 K</code></td><td>-</td>
    <td>not represented</td><td>-</td></tr>
</table>

<p>Live implementations are the four functions in
<a href=\"modelica://MSRE.Media.FuelSalt.Utilities\">FuelSalt.Utilities</a>.
<code>d_Cantor</code> and <code>eta_Cantor</code> here restate the two temperature dependent
ones so that a verification model can call them without going through the medium;
<code>d_Compere</code>, <code>d_legacy</code>, <code>cp_legacy</code>, <code>eta_legacy</code>
and <code>lambda_legacy</code> are reference-only and are not used by any component.</p>

<h4>Units: the density fit is in degC, the viscosity fit is in K</h4>
<p>The published density fit takes degrees Celsius. Implemented directly against a Modelica
kelvin temperature it gives 2035 kg/m3 at 922 K instead of 2189 kg/m3. The conversion in
<a href=\"modelica://MSRE.Media.FuelSalt.Utilities.d_T\">d_T</a> is therefore mandatory, and it
is cross-checked against the INL SAM implementation, which evaluates the same fit at
476.85 degC (750 K) and reports 2285.31 kg/m3. The viscosity fit takes kelvin and is
implemented without conversion.</p>

<h4>Retained assumptions</h4>
<p>No source was established in this pass for the following, so they keep the values they had -
<b>retained existing model assumption, not modified in this property update</b>:</p>
<ul>
<li><code>FuelSalt.kappa_const = 2.89e-10 1/Pa</code>, isothermal compressibility, taken from
the TRANSFORM FLiBe model. The primary system is essentially incompressible at MSRE
conditions, so it only sets the (stiff) acoustic time scale.</li>
<li><code>FuelSalt.MM_const = 0.0331 kg/mol</code>, molar mass, required by the TRANSFORM
medium interface.</li>
<li><code>FuelSalt.reference_p = 1e5 Pa</code>, <code>reference_s = 0</code>, and the
<code>reference_h</code> convention <code>cp*(T_ref - 273.15)</code>.</li>
<li><code>Data.Geometry.d_fuel_ref = 2249.3 kg/m3</code> and
<code>BaseClasses.PartialFuelPump.d_nominal = 2242 kg/m3</code>, both ORNL-TM-4865 numbers
belonging to the geometry/pump side, deliberately left alone by this property-only change.
<b>Both were migrated to this correlation later, under open item O-13</b>:
<code>d_fuel_ref</code> is now <code>FuelSalt.Utilities.d_T(908 K)</code> and the pump default
is the 922 K value, 2188.646 kg/m3.</li>
</ul>
<p><code>FuelSalt.beta_const</code> is the one derived parameter that did move, from 2.2880e-4
to 2.5678e-4 1/K, because it is nothing but <code>0.562/2188.65</code> - the isobaric expansion
coefficient of the new density fit at the reference temperature.</p>

<h4>Consequences left visible rather than absorbed</h4>
<p>The density dropped by 2.4 % at 922 K relative to Compere. The geometry record and the pump
models were not adjusted to compensate, so the transit times
<code>PrimarySystem.tau_core</code> and <code>tau_loop</code>, which are computed from the
medium density, move by the same 2.4 %. That is the intended behaviour of a property-only
change: the inconsistency stays computable rather than being hidden by re-fitting volumes.
<a href=\"modelica://MSRE.Verification.Properties_TransitTime\">Properties_TransitTime</a> and
<a href=\"modelica://MSRE.Verification.Analytic_DriftReactivity\">Analytic_DriftReactivity</a>
evaluated <code>d_Compere</code> explicitly at the time of that change and were unaffected by
it. <b>That is no longer the case:</b> under open item O-18 both were moved onto
<a href=\"modelica://MSRE.Media.FuelSalt.Utilities.d_T\">FuelSalt.Utilities.d_T</a>, so their
active results now follow the medium. They still compute the Compere figures alongside, as
reference comparisons that no assertion depends on.</p>

<h4>Jeong et al. (2026) do not publish theirs</h4>
<p>The reference paper states only that <q>molten salt thermophysical property models were
implemented in the MARS code first</q> and refers to two earlier papers for them. No
correlation and no property value appears in the paper itself, so the MARS properties cannot be
compared against these directly, and no attempt is made here to reverse-engineer them. What the
paper does report is the transit times, and those constrain the density without any correlation
being quoted, because a transit time multiplied by a mass flow rate is a mass. That indirect
route is worked out in
<a href=\"modelica://MSRE.Verification.Properties_TransitTime\">Properties_TransitTime</a>.</p>
</html>"));
end MSRE_Properties;
