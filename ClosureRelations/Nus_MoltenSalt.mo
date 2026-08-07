within MSRE.ClosureRelations;
model Nus_MoltenSalt
  "Nusselt number valid from natural circulation to rated flow: Nu = Nu_floor + f*0.023*Re^0.8*Pr^0.4"
  extends
    TRANSFORM.Fluid.ClosureRelations.HeatTransfer.Models.DistributedPipe_1D_MultiTransferSurface.PartialSinglePhase;

  input Real Nu_floor=4.36
    "Low flow Nusselt number: 4.36 for a duct, higher for cross-flow over a tube bundle"
    annotation (Dialog(group="Inputs"));
  input Real f_enhance=1.0
    "Multiplier on the turbulent term (>1 for baffle induced cross-flow on a shell side)"
    annotation (Dialog(group="Inputs"));
  input SI.Length L_char[nHT,nSurfaces]=transpose({dimensions for i in 1:nSurfaces})
    "Length scale the Nusselt number is referred to; defaults to the hydraulic diameter"
    annotation (Dialog(group="Inputs"));
  parameter SI.ReynoldsNumber Re_reg=10
    "Reynolds number below which the turbulent term is regularized"
    annotation (Dialog(tab="Advanced"));

equation
  for i in 1:nHT loop
    for j in 1:nSurfaces loop
      Nus[i, j] = Nu_floor + f_enhance*0.023*(Res[i]^2 + Re_reg^2)^0.4*Prs[i]^0.4;
      alphas[i, j] = Nus[i, j]*mediaProps[i].lambda/L_char[i, j];
    end for;
  end for;

  annotation (defaultComponentName="heatTransfer", Documentation(info="<html>
<p>The paper identifies the heat transfer model as the dominant uncertainty of the natural
circulation test: at about 1.5 kg/s the fuel salt Reynolds number in the core channels is of
order 10 and on the heat exchanger shell side of order 100, so a bare Dittus-Boelter
correlation, which is what a system code applies by default, collapses to an unphysically
small heat transfer coefficient.</p>

<p>This closure adds a low-flow floor to the turbulent term instead of switching between them,
which keeps the model continuously differentiable and recovers</p>
<ul>
<li><code>Nu -&gt; Nu_floor</code> in the natural circulation regime, and</li>
<li><code>Nu -&gt; f_enhance*0.023*Re^0.8*Pr^0.4</code> at rated flow.</li>
</ul>

<h4>Choosing the two coefficients</h4>
<p>For a duct such as a fuel channel or a heat exchanger tube, <code>Nu_floor = 4.36</code> is
the fully developed laminar value at constant heat flux and <code>f_enhance = 1</code>.</p>

<p>The heat exchanger shell side is neither: the segmental baffles turn it into cross-flow over
a tube bundle. Two things change there. The Nusselt number should be referred to the tube outer
diameter rather than to the shell hydraulic diameter, which is what <code>L_char</code> is for,
and both coefficients are larger. The paper notes that segmental baffles typically raise the
shell-side coefficient by a factor of 2 to 5, so <code>f_enhance</code> in that range
calibrates the full-power steady state, while <code>Nu_floor</code> of order 10, the usual
low-Reynolds cross-flow value, sets the natural circulation performance.</p>

<p>Note that the Reynolds number is always formed with the hydraulic diameter, because that is
what the TRANSFORM interface provides; only the Nusselt number is referred to
<code>L_char</code>.</p>
</html>"));
end Nus_MoltenSalt;
