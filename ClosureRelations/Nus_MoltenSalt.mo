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
<p>Gnielinski, applied unchanged to the core fuel channels and to both sides of the heat
exchanger. There is deliberately no separate core and shell-side closure and no calibration
coefficient of any kind.</p>

<p><code>f = [0.79*ln(Re) - 1.64]^(-2)</code></p>
<p><code>Nu = (f/8)*(Re - 1000)*Pr / [1 + 12.7*sqrt(f/8)*(Pr^(2/3) - 1)]</code></p>
<p><code>alpha = Nu*lambda/L_char</code></p>

<p><code>Re</code> and <code>Pr</code> come from the TRANSFORM heat-transfer interface and
<code>L_char</code> defaults to the same hydraulic diameter the Reynolds number is formed with,
so the correlation is used self-consistently. <code>Re_eff</code> takes the magnitude of the
Reynolds number so that reverse flow is treated symmetrically, and <code>Re_min</code> keeps
the logarithm away from the pole the friction-factor fit has near <code>Re = 8</code>; neither
touches any result inside the correlation's validity range.</p>

<h4>Validity, and what this model does outside it</h4>
<p><b>Gnielinski is valid for roughly <code>3000 &lt; Re &lt; 5e6</code>.</b> Below about
<code>Re = 1000</code> the <code>(Re - 1000)</code> factor turns negative and the correlation
returns a <b>negative Nusselt number</b>, which is not a physical heat transfer coefficient.
Nothing in this model corrects for that, by deliberate choice: adding a low-Reynolds floor is
what the retired closure did, and its two coefficients were being used to calibrate results.</p>

<p><b>This matters at the nominal operating point, not only in natural circulation.</b> At the
rated 168 kg/s the MSRE fuel channels run at</p>
<table border=\"1\">
<tr><th>Location</th><th>Re at rated flow</th><th>Pr</th><th>Gnielinski Nu</th></tr>
<tr><td>core fuel channel</td><td><b>812</b></td><td>20.1</td><td><b>-4.0</b></td></tr>
<tr><td>heat exchanger shell side</td><td>8637</td><td>20.1</td><td>102</td></tr>
<tr><td>heat exchanger tube side</td><td>10510</td><td>15.8</td><td>112</td></tr>
</table>
<p>The core channels are laminar at full flow - 0.23 m/s through a 15.85 mm hydraulic diameter
- so Gnielinski is outside its range there under every condition this library simulates, and
the core heat transfer coefficient it returns is negative. <b>The core side of this closure is
therefore not usable for a thermal result as it stands.</b> The heat exchanger, at
<code>Re</code> of order 1e4 on both sides, is inside the range and is fine.</p>

<p>How to treat the sub-transitional core channels is an open modelling decision and is
recorded as open item O-19. It is not resolved here because every way of resolving it -
a laminar constant, a transitional blend, a different correlation - is a modelling choice that
changes the full-power result, and picking one silently is how calibration coefficients get
reintroduced.</p>

<h4>What this replaced</h4>
<p>The retired closure was <code>Nu = Nu_floor + f_enhance*0.023*Re^0.8*Pr^0.4</code>, with
<code>Nu_floor</code> and <code>f_enhance</code> exposed and used to calibrate the full-power
and natural-circulation duties. Both inputs are gone. The parameters that fed them,
<code>Data.Geometry.f_shellHT</code> and <code>Nu_floor_shell</code>, are retained there as
LEGACY/DEPRECATED and are connected to nothing. For comparison, at the rated points above that
closure gave 20.6, 333 and 119 for the Nusselt numbers.</p>
</html>"));
end Nus_MoltenSalt;
