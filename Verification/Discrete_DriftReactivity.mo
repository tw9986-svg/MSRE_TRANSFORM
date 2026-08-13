within MSRE.Verification;
model Discrete_DriftReactivity
  "How far the discretized precursor transport sits from paper Eq. 8, and why"
  extends Modelica.Icons.Example;

  parameter MSRE.Data.PrecursorGroups.U235_6group pg "U-235 precursor data (paper Table 1)";
  parameter MSRE.Data.Geometry geometry "Plant geometry and nodalization";
  parameter MSRE.Data.BenchmarkTargets targets "Values reported by the paper";

  parameter SI.MassFlowRate m_flow=geometry.m_flow_nominal "Fuel salt flow rate";
  parameter SI.Density d=2063.1 "Fuel salt density at 908 K, the zero power test temperature";

  /* ==================================================================
     The mesh the plant model actually uses, written out cell by cell
     ================================================================== */
  final parameter SI.Volume Vs_core[geometry.nAxial + 2]=cat(
      1,
      {geometry.V_lowerPlenum/geometry.nLP},
      fill(geometry.V_channels/geometry.nAxial, geometry.nAxial),
      {geometry.V_upperPlenum/geometry.nUP})
    "Core cells in flow order: lower plenum core node, fuel channels, upper plenum core node";

  final parameter SI.Volume Vs_loop[geometry.nUP - 1 + geometry.nOutletPipe + geometry.nPumpBowl
     + geometry.nPumpToHX + geometry.nHX + geometry.nHXToVessel + geometry.nDC + geometry.nLP
     - 1]=cat(
      1,
      fill(geometry.V_upperPlenum/geometry.nUP, geometry.nUP - 1),
      fill(pi/4*geometry.D_pipe^2*geometry.L_outletPipe/geometry.nOutletPipe, geometry.nOutletPipe),
      fill(geometry.V_pumpBowl/geometry.nPumpBowl, geometry.nPumpBowl),
      fill(pi/4*geometry.D_pipe^2*geometry.L_pumpToHX/geometry.nPumpToHX, geometry.nPumpToHX),
      fill(geometry.V_hxShell/geometry.nHX, geometry.nHX),
      fill(pi/4*geometry.D_pipe^2*geometry.L_hxToVessel/geometry.nHXToVessel, geometry.nHXToVessel),
      fill(geometry.V_downcomer/geometry.nDC, geometry.nDC),
      fill(geometry.V_lowerPlenum/geometry.nLP, geometry.nLP - 1))
    "External loop cells in flow order, from the core exit back to the core inlet";

  final parameter SI.Time tau_C=d*sum(Vs_core)/m_flow "Core transit time of this mesh";
  final parameter SI.Time tau_L=d*sum(Vs_loop)/m_flow "Loop transit time of this mesh";

  /* ==================================================================
     1. The continuous reference: paper Eq. 8 at the same transit times
     ================================================================== */
  final parameter Real drho_continuous_pcm=1e5*MSRE.Functions.driftReactivity(
      pg.alphas*pg.Beta,
      pg.lambdas,
      tau_C,
      tau_L) "Paper Eq. 8 evaluated at this mesh's transit times [pcm]";

  /* ==================================================================
     2. The same problem on the mesh, and under refinement
     ================================================================== */
  parameter Integer nSubs[:]={1,2,4,8}
    "Refinement levels; 1 is the mesh the plant model runs on"
    annotation (Dialog(group="Refinement study"));
  final parameter Integer nLevels=size(nSubs, 1);

  final parameter Real drho_discrete_pcm[nLevels]={1e5*MSRE.Functions.driftReactivityDiscrete(
      pg.alphas*pg.Beta,
      pg.lambdas,
      Vs_core,
      Vs_loop,
      m_flow,
      d,
      nSubs[i],
      1.0) for i in 1:nLevels}
    "Drift reactivity of the upwind discretization at each refinement level [pcm]";
  final parameter Real bias_pcm[nLevels]={drho_discrete_pcm[i] - drho_continuous_pcm for i in
          1:nLevels} "Discretization error at each refinement level [pcm]";
  final parameter Real order[nLevels - 1]={bias_pcm[i]/bias_pcm[i + 1] for i in 1:nLevels - 1}
    "Ratio of consecutive errors; 2 means first order convergence";

  /* ==================================================================
     3. What the model's own power shape does to the same number
     ================================================================== */
  final parameter Real drho_shaped_pcm=1e5*MSRE.Functions.driftReactivityDiscrete(
      pg.alphas*pg.Beta,
      pg.lambdas,
      Vs_core,
      Vs_loop,
      m_flow,
      d,
      8,
      geometry.f_axialExtrapolation)
    "Drift reactivity on a converged mesh with the axial source shape the plant model uses [pcm]";
  final parameter Real shapeEffect_pcm=drho_shaped_pcm - drho_discrete_pcm[nLevels]
    "How much the extrapolated cosine moves the asymptote away from Eq. 8 [pcm]";

  /* ==================================================================
     4. Ex-core decay: the check Fischer and Bures use
     ================================================================== */
  final parameter Real xi_analytic[pg.nC]={1 - exp(-pg.lambdas[j]*tau_L) for j in 1:pg.nC}
    "Fraction of each group that decays in the external loop, continuous";
  final parameter Real xi_discrete[pg.nC]={1 - product({1/(1 + pg.lambdas[j]*d*Vs_loop[k]/
      m_flow) for k in 1:size(Vs_loop, 1)}) for j in 1:pg.nC}
    "The same fraction on the loop mesh of the plant model";
  final parameter Real xi_error[pg.nC]={xi_discrete[j] - xi_analytic[j] for j in 1:pg.nC}
    "Error of the ex-core decayed fraction";

  /* ==================================================================
     Acceptance criteria
     ================================================================== */
  parameter Real tol_bias_pcm=3.0
    "Largest discretization error accepted on the mesh the plant model runs on"
    annotation (Dialog(group="Acceptance criteria"));
  parameter Real tol_order=0.35
    "Tolerance on the error ratio around the first order value of 2"
    annotation (Dialog(group="Acceptance criteria"));
  parameter Real tol_xi=0.02
    "Largest error accepted on any ex-core decayed fraction"
    annotation (Dialog(group="Acceptance criteria"));

equation
  assert(abs(bias_pcm[1]) < tol_bias_pcm, "On the mesh the plant model runs on, the upwind
precursor transport gives a drift reactivity of " + String(drho_discrete_pcm[1])
     + " pcm against " + String(drho_continuous_pcm) + " pcm from paper Eq. 8, a discretization
error of " + String(bias_pcm[1]) + " pcm. That has to be small compared with the gap the
benchmark is about: the paper's own MARS transient lands 1.9 pcm below its Eq. 8 value and
calls that very good agreement. If the mesh error is of the same size, the comparison measures
the mesh rather than the physics.", AssertionLevel.error);

  assert(max({abs(order[i] - 2) for i in 1:nLevels - 1}) < tol_order, "The error does not halve
under mesh refinement: consecutive ratios are " + String(order[1]) + ", " + String(order[
    nLevels - 1]) + ", against 2 for the first order upwind scheme. Either the discrete
solution is not converging to Eq. 8, which would mean the two are not solving the same problem,
or the coarsest level is not yet in the asymptotic range.", AssertionLevel.error);

  assert(max({abs(xi_error[j]) for j in 1:pg.nC}) < tol_xi, "The fraction of a precursor group
that decays in the external loop is off by up to " + String(max({abs(xi_error[j]) for j in 1:pg.nC}))
     + " from the analytic 1 - exp(-lambda*tau_L). This is the ex-core convergence check of
Fischer and Bures (their Table 4) and it isolates the loop nodalization: it depends on the
loop cell sizes and on nothing else - not on the power shape, not on the core mesh.",
    AssertionLevel.error);

  annotation (
    experiment(StopTime=1),
    Documentation(info="<html>
<h4>The question this model answers</h4>
<p>The headline number of the benchmark is a reactivity of about 227 pcm lost to precursor
drift. The plant model produces it by transporting six trace substances round a closed loop
with the first-order upwind scheme TRANSFORM applies to trace substances. Upwinding is
numerically diffusive, and a diffused precursor profile decays in the wrong place, so the mesh
biases exactly the quantity being benchmarked. Before any agreement with the paper means
anything, that bias has to be shown to be small.</p>

<p>Both published Modelica/TRANSFORM models of the MSRE treat this as the central numerical
argument. Fischer and Bures (Nucl. Eng. Des. 416 (2024) 112768) converge the ex-core decayed
fraction against <code>1 - exp(-lambda*tau_ec)</code> and settle on 4 nodes per ex-core pipe on
that basis. Mao et al. (Energies 19 (2026) 13) sweep the axial core node count and find the
predicted drift reactivity moves visibly with it, coarse meshes under-predicting the loss
because the averaging inside a cell under-resolves the concentration gradient.</p>

<p>This model runs the same two checks against the mesh in
<a href=\"modelica://MSRE.Data.Geometry\">MSRE.Data.Geometry</a>, without simulating anything:
<a href=\"modelica://MSRE.Functions.driftReactivityDiscrete\">driftReactivityDiscrete</a> solves
the discretized steady state in closed form, so the whole study is a parameter evaluation.</p>

<h4>What comes out</h4>
<table border=\"1\">
<tr><th>Quantity</th><th>Value</th></tr>
<tr><td>core / loop transit time of this mesh</td><td>9.56 s / 16.14 s</td></tr>
<tr><td>paper Eq. 8 at those transit times</td><td>228.37 pcm</td></tr>
<tr><td>upwind solution on the plant mesh (22 core cells, 40 loop cells)</td><td>227.58 pcm</td></tr>
<tr><td>discretization error</td><td>-0.79 pcm</td></tr>
<tr><td>error at 2x, 4x, 8x refinement</td><td>-0.39, -0.20, -0.10 pcm</td></tr>
<tr><td>largest ex-core decayed fraction error (group 3)</td><td>0.009</td></tr>
</table>

<p>The error halves at every refinement, which is the first-order behaviour the scheme is
supposed to have, and it converges to Eq. 8 rather than to something else. On the mesh the
plant model runs on it is 0.79 pcm, about 0.35 % of the quantity, and it makes the drift
loss slightly <i>smaller</i> - the same direction Mao et al. report for coarse meshes.
That is comfortably inside the 1.9 pcm the paper treats as very good agreement, so the
nodalization is fine and the comparison against the paper is about the physics.</p>

<h4>The result that is not reassuring</h4>
<p><code>shapeEffect_pcm</code> is the one to read carefully. Paper Eq. 8 is derived for a
cosine axial power profile <i>chopped at the core boundary</i>; that is where its
<code>1/(1 + (lambda*tau_C/pi)^2)</code> factor comes from. The plant model does not use that
profile. <a href=\"modelica://MSRE.Data.Geometry\">Geometry.f_axialExtrapolation</a> defaults to
1.2, which leaves a finite fission source in the two plenum nodes, on the argument that the
reason those nodes are counted as core at all is that fission occurs in them.</p>

<p>That choice moves the converged drift reactivity by about <b>+6.9 pcm</b>, to roughly
235 pcm. It is more than three times the discretization error and more than three times the
1.9 pcm gap the paper reports between its own transient and its own Eq. 8. In other words the
axial source shape, not the mesh and not the transport, is the largest single thing standing
between this model's asymptote and the paper's 228.4 pcm.</p>

<p>This is a modelling decision, not a bug, and it is left open deliberately. Set
<code>f_axialExtrapolation = 1.0</code> to compare like with like against Eq. 8; keep 1.2 if the
plenum fission source is judged the more faithful representation, and then compare the
transient against <code>drho_shaped_pcm</code> rather than against Eq. 8.
<a href=\"modelica://MSRE.Verification.Transient_DriftReactivity\">Transient_DriftReactivity</a>
currently asserts against Eq. 8 with an 8 pcm tolerance, which is only just wide enough to
absorb this and would be measuring the wrong thing.</p>

<h4>What this does not check</h4>
<p>Everything time dependent. This is a steady-state statement: it says where the transient
must end up, not how it gets there. The oscillation the pump startup test is really about is
checked in
<a href=\"modelica://MSRE.Verification.Transient_DriftReactivity\">Transient_DriftReactivity</a>.
It also assumes the radial rings all carry the same axial residence time, which holds when the
flow splits in proportion to volume; a large ring-to-ring velocity spread would need the rings
solved separately.</p>
</html>"));
end Discrete_DriftReactivity;
