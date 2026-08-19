within MSRE.ClosureRelations;
model Nus_Core
  "Core fuel channel Nusselt number: generic fully developed laminar closure below Re 2300, Gnielinski above Re 3000, smoothly blended between"
  extends
    TRANSFORM.Fluid.ClosureRelations.HeatTransfer.Models.DistributedPipe_1D_MultiTransferSurface.PartialSinglePhase;

  parameter Real Nu_laminar=4.36
    "ASSUMPTION / GENERIC LAMINAR CLOSURE: fully developed laminar Nusselt number. 4.36 is the circular-duct constant-heat-flux value, 3.66 the constant-wall-temperature one"
    annotation (Dialog(group="Laminar closure"));
  parameter SI.ReynoldsNumber Re_laminar=2300
    "Upper end of the laminar branch" annotation (Dialog(group="Laminar closure"));
  parameter SI.ReynoldsNumber Re_turbulent=3000
    "Lower end of the Gnielinski branch, its usual validity limit"
    annotation (Dialog(group="Laminar closure"));

  input SI.Length L_char[nHT,nSurfaces]=transpose({dimensions for i in 1:nSurfaces})
    "Length scale the Nusselt number is referred to; defaults to the hydraulic diameter, which is also what the Reynolds number is formed with"
    annotation (Dialog(group="Inputs"));
  parameter SI.ReynoldsNumber Re_min=100
    "Numerical guard applied to the friction-factor logarithm only" annotation (Dialog(tab="Advanced"));

protected
  Real Re_eff[nHT] "Reynolds number magnitude used by the correlations";
  Real fs[nHT] "Darcy friction factor of the Filonenko/Petukhov fit";
  Real Nu_gnielinski[nHT] "Gnielinski branch, evaluated everywhere but only weighted in above Re_laminar";
  Real x[nHT] "Position within the transition window";
  Real w[nHT] "Smoothstep weight of the Gnielinski branch";

equation
  for i in 1:nHT loop
    Re_eff[i] = max(abs(Res[i]), Re_min);
    fs[i] = (0.79*Modelica.Math.log(Re_eff[i]) - 1.64)^(-2);
    Nu_gnielinski[i] = (fs[i]/8)*(Re_eff[i] - 1000)*Prs[i]/(1 + 12.7*sqrt(fs[i]/8)*(Prs[i]^(
      2/3) - 1));
    x[i] = max(0, min(1, (Re_eff[i] - Re_laminar)/(Re_turbulent - Re_laminar)));
    w[i] = x[i]^2*(3 - 2*x[i]);
    for j in 1:nSurfaces loop
      Nus[i, j] = (1 - w[i])*Nu_laminar + w[i]*Nu_gnielinski[i];
      alphas[i, j] = Nus[i, j]*mediaProps[i].lambda/L_char[i, j];
    end for;
  end for;

  annotation (defaultComponentName="heatTransfer", Documentation(info="<html>
<h4>Why the core needs its own closure</h4>
<p>The MSRE fuel channels are <b>laminar at rated flow</b>. At 168 kg/s through
1140 channels of 2.875244e-4 m2, the bulk velocity is 0.2333 m/s and</p>
<p><code>Re = m_flow*Dh/(A_total*mu) = 168*0.015851/(0.327778*1.0002e-2) = <b>812</b></code></p>
<p>so the core never enters the range Gnielinski is defined for, under any condition this
library simulates. Reaching Re = 2300 would need 476 kg/s, 2.8 times the rated flow. The heat
exchanger is a different matter - both its sides run at Re of order 1e4 - which is why it keeps
the plain Gnielinski closure
<a href=\"modelica://MSRE.ClosureRelations.Nus_MoltenSalt\">Nus_MoltenSalt</a> and the core
uses this one.</p>

<h4>Structure</h4>
<table border=\"1\">
<tr><th>Range</th><th>Nusselt number</th></tr>
<tr><td><code>Re &lt; 2300</code></td><td><code>Nu_laminar</code>, constant</td></tr>
<tr><td><code>2300 &lt;= Re &lt; 3000</code></td>
    <td>smoothstep blend, <code>w = x^2(3-2x)</code> with
        <code>x = (Re-2300)/700</code></td></tr>
<tr><td><code>Re &gt;= 3000</code></td><td>Gnielinski</td></tr>
</table>
<p>The blend weight and its first derivative both vanish at each end of the window, so the
Nusselt number is continuously differentiable across it. There is <b>no multiplier, no
enhancement factor and no Nusselt floor</b> anywhere in this model: the laminar branch is a
constant because fully developed laminar duct flow has a constant Nusselt number, not because
a value was needed to make a result come out.</p>

<h4>Provenance of the laminar constant</h4>
<pre>
ASSUMPTION / GENERIC LAMINAR CLOSURE
Used only as an interim closure for the 1-D TRANSFORM benchmark model.
Not an experimentally validated MSRE-specific heat-transfer correlation.
</pre>
<p><code>Nu_laminar = 4.36</code> is the fully developed laminar value for a <b>circular</b>
duct at <b>constant wall heat flux</b>; 3.66 is the corresponding constant-wall-temperature
value. The constant-heat-flux value is used because that is what the graphite boundary in
<a href=\"modelica://MSRE.Components.CoreChannel\">CoreChannel</a> actually imposes: the
graphite annulus is adiabatic on its outer radius and on both ends, and its only internal
source is the <code>f_graphiteHeating</code> share of the fission power, so whatever it
generates must leave through the salt interface. The wall therefore sets a flux, not a
temperature. With the default <code>f_graphiteHeating = 0</code> that flux is zero in steady
state and the choice does not matter; it matters in transients and in the paper's
graphite-heating sensitivity case.</p>

<p><b>This constant is not MSRE-specific and is not claimed to be.</b> The real channel is an
obround 3.048 x 1.016 cm with a 0.508 cm corner radius - since the radius is exactly half the
short dimension, the two ends are semicircular - and a duct of that shape has a laminar Nusselt
number of its own, distinguishably different from the circular 4.36. Correcting for it is
deliberately deferred:</p>
<table border=\"1\">
<tr><th>Stage</th><th>Treatment</th></tr>
<tr><td>current implementation</td><td>generic laminar closure, this model</td></tr>
<tr><td>future refinement</td><td>geometry-dependent rectangular/obround laminar correlation</td></tr>
<tr><td>future refinement</td><td>ORNL/MSRE-specific heat-transfer treatment</td></tr>
<tr><td>future refinement</td><td>Poppendiek effect and graphite-fuel coupling</td></tr>
</table>

<h4>What this does and does not affect</h4>
<p>It sets the fuel-to-graphite temperature difference and hence the graphite temperature. It
does <b>not</b> enter the core bulk energy balance: the fission power reaches the salt as a
volumetric source in each axial control volume
(<code>CoreChannel.pipe.InternalHeatGen</code>, fed by
<code>ReactorCore.Qs_channels = Qs_core*(1 - f_graphiteHeating)</code>), not through this
closure, so the core outlet temperature, the core delta-T and <code>Q_core</code> follow from
<code>Q = m_flow*cp*dT</code> independently of any Nusselt number.</p>
</html>"));
end Nus_Core;
