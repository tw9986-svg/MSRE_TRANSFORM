within MSRE.Media.FuelSalt.Utilities;
function eta_T "Dynamic viscosity of the MSRE fuel salt"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.DynamicViscosity eta "Dynamic viscosity";
algorithm
  eta := 8.94e-5*exp(4092/T);
  annotation (Inline=true, Documentation(info="<html>
<p><code>eta [Pa.s] = 8.94e-5*exp(4092/T[K])</code>, i.e. 0.0894*exp(4092/T) in cP, giving
7.565 cP at 922 K (1200 degF).</p>

<p><b>Source level: source-unverified &mdash; origin unidentified.</b> This is the weakest of
the four. The prefactor and the activation constant could not be matched to any document or to
any other MSRE model examined, and in particular it is <i>not</i> TRANSFORM's: TRANSFORM's MSRE
fuel salt codes <code>0.116e-3*exp(3755/T)</code>, which is the generic FLiBe viscosity of
<code>Utilities_FLiBe</code> verbatim and gives 6.81 cP at 922 K &mdash; 11 % below this one.
Neither the composition nor the valid temperature range of the expression coded here has been
established.</p>

<p>The two forms differ in shape as well as magnitude, since the activation constants differ
(4092 against 3755), so they diverge away from 922 K: the gap widens to about 15 % at 800 K and
narrows to about 8 % at 1000 K.</p>

<p><b>Why this matters more than its 100 W duty suggests.</b> The channel Reynolds number is
about 855, so the fuel channels are laminar and their pressure drop is proportional to velocity
rather than to its square. The viscosity is then the only mechanism in the model that
redistributes flow between the fifteen rings without a fitted coefficient, at about
-0.5 %/K. An 11 % uncertainty in the viscosity is therefore not negligible for any ring-level
flow claim, even though it is negligible for the loop total, where the core friction is only
0.08 % of the loop pressure drop. See
<a href=\"modelica://MSRE.Media.MSRE_Properties\">MSRE_Properties</a>.</p>
</html>"));
end eta_T;
