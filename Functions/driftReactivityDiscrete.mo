within MSRE.Functions;
function driftReactivityDiscrete
  "Steady-state drift reactivity of the first-order upwind discretization that the fluid model actually solves"
  extends Modelica.Icons.Function;

  input Real betas[:] "Delayed neutron fraction of each precursor group";
  input SIadd.InverseTime lambdas[size(betas, 1)] "Decay constant of each precursor group";
  input SI.Volume Vs_core[:]
    "Fuel salt volume of every reactor core cell, in flow order";
  input SI.Volume Vs_loop[:]
    "Fuel salt volume of every external loop cell, in flow order";
  input SI.MassFlowRate m_flow "Fuel salt mass flow rate";
  input SI.Density d "Fuel salt density";
  input Integer nSub=1
    "Every cell is split into nSub equal cells before solving; nSub -> inf recovers driftReactivity";
  input Real f_extrapolation=1.0
    "Axial extrapolation factor of the cosine source. 1.0 is the chopped cosine that paper Eq. 8 assumes";
  output SIadd.NonDim drho "Reactivity loss (positive number)";

protected
  Integer nG=size(betas, 1);
  Integer nC=size(Vs_core, 1)*nSub "# of core cells after subdivision";
  Integer nL=size(Vs_loop, 1)*nSub "# of loop cells after subdivision";
  SI.Volume dVs_C[size(Vs_core, 1)*nSub] "Volume of each core cell after subdivision";
  SI.Time taus_C[size(Vs_core, 1)*nSub] "Residence time of each core cell";
  SI.Time taus_L[size(Vs_loop, 1)*nSub] "Residence time of each loop cell";
  Real S[size(Vs_core, 1)*nSub] "Fission source fraction of each core cell";
  SI.Volume L_core "Total core volume, used as the axial coordinate";
  SI.Volume L_ext "Extrapolated core volume";
  SI.Volume z_offset "Offset that places the extrapolated cosine over the core";
  SI.Volume z0;
  SI.Volume z1;
  Real gain "Ratio of outlet to inlet concentration once round the loop with no source";
  Real C "Precursor concentration, in units where the total source rate is beta";
  Real C_in "Concentration entering the first core cell";
  Real inventory "Precursor inventory of the reactor core, same units";
  Real Beta_eff "Effective delayed neutron fraction of the circulating fuel";

algorithm
  /* Residence times. tau = d*V/m_flow is what the upwind balance of a cell depends on;
     nothing else about the geometry enters. */
  for i in 1:size(Vs_core, 1) loop
    for s in 1:nSub loop
      dVs_C[(i - 1)*nSub + s] := Vs_core[i]/nSub;
      taus_C[(i - 1)*nSub + s] := d*Vs_core[i]/nSub/m_flow;
    end for;
  end for;
  for i in 1:size(Vs_loop, 1) loop
    for s in 1:nSub loop
      taus_L[(i - 1)*nSub + s] := d*Vs_loop[i]/nSub/m_flow;
    end for;
  end for;

  /* Cell-integrated cosine source, laid out over the cumulative core volume so that the
     source seen by a cell is proportional to the source seen by the fluid that dwells in it. */
  L_core := sum(Vs_core);
  L_ext := L_core*f_extrapolation;
  z_offset := (L_ext - L_core)/2;
  z1 := 0;
  for k in 1:nC loop
    z0 := z1;
    z1 := z0 + dVs_C[k];
    S[k] := L_ext/Modelica.Constants.pi*(Modelica.Math.cos(Modelica.Constants.pi*(z0 +
      z_offset)/L_ext) - Modelica.Math.cos(Modelica.Constants.pi*(z1 + z_offset)/L_ext));
  end for;
  S := S/sum(S);

  /* One group at a time. The discretized steady state is linear in the inlet concentration,
     so it is solved exactly: sweep once from a zero inlet to get the source response, close
     the loop with the no-source gain, then sweep again to collect the core inventory. */
  Beta_eff := 0;
  for g in 1:nG loop
    gain := 1;
    for k in 1:nC loop
      gain := gain/(1 + lambdas[g]*taus_C[k]);
    end for;
    for k in 1:nL loop
      gain := gain/(1 + lambdas[g]*taus_L[k]);
    end for;

    C := 0;
    for k in 1:nC loop
      C := (C + betas[g]*S[k])/(1 + lambdas[g]*taus_C[k]);
    end for;
    for k in 1:nL loop
      C := C/(1 + lambdas[g]*taus_L[k]);
    end for;
    C_in := C/(1 - gain);

    C := C_in;
    inventory := 0;
    for k in 1:nC loop
      C := (C + betas[g]*S[k])/(1 + lambdas[g]*taus_C[k]);
      inventory := inventory + C*taus_C[k];
    end for;
    Beta_eff := Beta_eff + lambdas[g]*inventory;
  end for;

  drho := sum(betas) - Beta_eff;

  annotation (Documentation(info="<html>
<h4>Why this function exists</h4>
<p><a href=\"modelica://MSRE.Functions.driftReactivity\">driftReactivity</a> evaluates paper
Eq. 8, the <i>continuous</i> steady-state drift reactivity. The plant model does not solve that
equation; it solves the precursor transport of paper Eq. 3 on a finite mesh with the
first-order upwind scheme that TRANSFORM applies to trace substances. First-order upwinding is
numerically diffusive, and the quantity being benchmarked - the reactivity lost while
precursors sit outside the core - is exactly the kind of quantity numerical diffusion biases.</p>

<p>This function solves the <b>same discretization</b> analytically in the steady state, so the
difference between the two is the discretization error alone, with no simulation involved.
Both prior Modelica/TRANSFORM studies of the MSRE make this check the centre of their
numerical argument: Fischer and Bures (Nucl. Eng. Des. 416 (2024) 112768, their Table 4)
converge the ex-core decayed fraction against its analytic value as the ex-core node count
rises, and Mao et al. (Energies 19 (2026) 13, their Figs. 8-9) show that the axial core node
count changes the predicted drift reactivity by a visible margin, coarse meshes
<i>under</i>-predicting the loss.</p>

<h4>What is solved</h4>
<p>For each group, the steady-state upwind balance of cell <i>k</i> with residence time
<code>tau_k = d*V_k/m_flow</code> is</p>

<p><code>C_k = (C_(k-1) + s_k/m_flow) / (1 + lambda*tau_k)</code></p>

<p>which is walked once round the closed loop. The problem is linear in the inlet
concentration, so the loop is closed exactly rather than iterated: one sweep from a zero inlet
gives the source response, the product of the cell factors gives the no-source gain, and the
fixed point follows. The effective delayed neutron fraction is then
<code>Beta_eff = sum_i lambda_i*C_i</code> over the core cells, in the normalization where the
total source rate of group <i>i</i> is <code>beta_i</code>, and the returned drift reactivity
is <code>sum(beta) - Beta_eff</code>. This is the same definition
<a href=\"modelica://MSRE.Functions.driftReactivity\">driftReactivity</a> returns, so the two
are directly comparable.</p>

<h4>Assumptions, and how they line up with Eq. 8</h4>
<ul>
<li>Uniform neutron importance, as everywhere in the paper.</li>
<li>Flow split between the radial rings in proportion to volume, so every ring has the same
axial residence time. The rings then all have the same axial precursor profile and can be
collapsed onto one path; the radial power shape drops out of the drift reactivity entirely.</li>
<li><code>f_extrapolation = 1.0</code> gives the chopped cosine that the derivation of Eq. 8
assumes. Any other value is a different source shape, and the discrete result will then
converge to something other than Eq. 8 as the mesh is refined - which is the point of exposing
it, see <a href=\"modelica://MSRE.Verification.Discrete_DriftReactivity\">Discrete_DriftReactivity</a>.</li>
</ul>
</html>"));
end driftReactivityDiscrete;
