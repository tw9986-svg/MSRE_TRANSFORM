within MSRE.ClosureRelations;
model Nus_MoltenSalt
  "Gnielinski correlation for the fuel and coolant salts, used by both the core channels and the heat exchanger"
  extends
    TRANSFORM.Fluid.ClosureRelations.HeatTransfer.Models.DistributedPipe_1D_MultiTransferSurface.PartialSinglePhase;

  input SI.Length L_char[nHT,nSurfaces]=transpose({dimensions for i in 1:nSurfaces})
    "Length scale the Nusselt number is referred to; defaults to the hydraulic diameter, which is also what the Reynolds number is formed with"
    annotation (Dialog(group="Inputs"));
  parameter SI.ReynoldsNumber Re_min=100
    "Numerical guard applied to the friction-factor logarithm only. Far below the validity limit of the correlation, so it never alters a result the correlation is entitled to produce"
    annotation (Dialog(tab="Advanced"));

protected
  Real Re_eff[nHT] "Reynolds number used by the correlation";
  Real fs[nHT] "Darcy friction factor of the Filonenko/Petukhov fit";

equation
  for i in 1:nHT loop
    Re_eff[i] = max(abs(Res[i]), Re_min);
    fs[i] = (0.79*Modelica.Math.log(Re_eff[i]) - 1.64)^(-2);
    for j in 1:nSurfaces loop
      Nus[i, j] = (fs[i]/8)*(Re_eff[i] - 1000)*Prs[i]/(1 + 12.7*sqrt(fs[i]/8)*(Prs[i]^(2/3)
         - 1));
      alphas[i, j] = Nus[i, j]*mediaProps[i].lambda/L_char[i, j];
    end for;
  end for;

  annotation (defaultComponentName="heatTransfer", Documentation(info="<html>
<h4>Correlation</h4>
<p>Gnielinski, applied unchanged to both sides of the heat
exchanger tube and shell sides. There is deliberately no shell-side enhancement factor and no
calibration coefficient of any kind. The core channels use the laminar-capable variant
<a href=\"modelica://MSRE.ClosureRelations.Nus_Core\">Nus_Core</a>, which falls back to this
same expression once the flow is turbulent.</p>

<p><code>f = [0.79*ln(Re) - 1.64]^(-2)</code></p>
<p><code>Nu = (f/8)*(Re - 1000)*Pr / [1 + 12.7*sqrt(f/8)*(Pr^(2/3) - 1)]</code></p>
<p><code>alpha = Nu*lambda/L_char</code></p>

<p><code>Re</code> and <code>Pr</code> come from the TRANSFORM heat-transfer interface and
<code>L_char</code> defaults to the same hydraulic diameter the Reynolds number is formed with,
so the correlation is used self-consistently. <code>Re_eff</code> takes the magnitude of the
Reynolds number so that reverse flow is treated symmetrically, and <code>Re_min</code> keeps
the logarithm away from the pole the friction-factor fit has near <code>Re = 8</code>; neither
touches any result inside the correlation's validity range.</p>

<h4>Validity, and where this model is used</h4>
<p>Gnielinski is valid for roughly <code>3000 &lt; Re &lt; 5e6</code>. Below about
<code>Re = 1000</code> the <code>(Re - 1000)</code> factor turns negative and the expression
returns a negative Nusselt number, so this model must only be applied where the flow is
turbulent. In this library that means the <b>heat exchanger</b>, both sides:</p>
<table border=\"1\">
<tr><th>Location</th><th>Re at rated flow</th><th>Pr</th><th>Nu</th><th>alpha [W/(m2.K)]</th></tr>
<tr><td>heat exchanger shell side</td><td>8637</td><td>20.1</td><td>101.6</td><td>1812</td></tr>
<tr><td>heat exchanger tube side</td><td>10510</td><td>15.8</td><td>112.2</td><td>11684</td></tr>
</table>

<p>The <b>core fuel channels are laminar at rated flow</b>, <code>Re = 812</code>, so they do
not use this model. They use
<a href=\"modelica://MSRE.ClosureRelations.Nus_Core\">Nus_Core</a>, which is a generic fully
developed laminar closure below <code>Re = 2300</code>, this correlation above
<code>Re = 3000</code>, and a smoothstep blend between. That split is the resolution of open
item O-19; see that model for the reasoning and for what remains open.</p>

<h4>What this replaced</h4>
<p>The retired closure was <code>Nu = Nu_floor + f_enhance*0.023*Re^0.8*Pr^0.4</code>, with
<code>Nu_floor</code> and <code>f_enhance</code> exposed and used to calibrate the full-power
and natural-circulation duties. Both inputs are gone. The parameters that fed them,
<code>Data.Geometry.f_shellHT</code> and <code>Nu_floor_shell</code>, are retained there as
LEGACY/DEPRECATED and are connected to nothing. For comparison, at the rated points above that
closure gave 333 and 119 on the shell and tube sides.</p>
</html>"));
end Nus_MoltenSalt;
