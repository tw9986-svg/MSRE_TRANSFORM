within MSRE.Media.FuelSalt.Utilities;
function eta_T "Dynamic viscosity of the MSRE fuel salt"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.DynamicViscosity eta "Dynamic viscosity";
algorithm
  eta := 8.4e-5*exp(4340/T);
  annotation (Inline=true, Documentation(info="<html>
<p><code>mu [Pa.s] = 8.4e-5*exp(4340/T [K])</code>, from S. Cantor, ORNL-TM-2316 (1968), as
tabulated by INL for the MSRE fuel salt. 9.30e-3 Pa.s at 922 K, 1.00e-2 Pa.s at 908 K.</p>

<p>This replaced <code>8.94e-5*exp(4092/T)</code>, which gave 7.57e-3 Pa.s at 922 K and whose
origin this library had been unable to identify: it was neither TRANSFORM's expression nor one
that could be traced to an ORNL document. The new correlation is 23 % higher at MSRE conditions.</p>

<p>The consequence is confined to the friction and heat transfer correlations. The channel
Reynolds number at rated flow falls from about 855 to about 695, which is further into the laminar
regime rather than across a transition, so the reasoning that the ring flow split responds
linearly to the viscosity is unaffected. The core friction pressure drop is 0.08 % of the loop
total, so the delivered flow rate barely moves.</p>

<p>TRANSFORM's MSRE fuel salt medium carries <code>0.116e-3*exp(3755/T)</code>, 6.81e-3 Pa.s at
922 K. That is the generic FLiBe viscosity reused verbatim for the fuel salt, not a
fuel-salt-specific fit, which is why it is not adopted here.</p>
</html>"));
end eta_T;
