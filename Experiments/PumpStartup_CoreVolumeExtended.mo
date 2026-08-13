within MSRE.Experiments;
model PumpStartup_CoreVolumeExtended
  "Pump startup with the core boundary moved outward: the transit time sensitivity of paper Section 4.1.2"
  extends MSRE.Experiments.PumpStartup(msre(geometry(V_upperPlenum=V_upperPlenum_extended,
          V_downcomer=V_downcomer_reduced)));

  parameter MSRE.Data.BenchmarkTargets targets "Values reported by the paper";
  parameter MSRE.Data.Geometry geometry_base "Unmodified geometry, for the volumes to start from";

  parameter SI.Time dtau=targets.dtau_coreExtension
    "Transit time moved out of the loop and into the core (1.11 s in the paper)";
  parameter SI.Density d_ref=2063.1 "Fuel salt density at 908 K";

  final parameter SI.Volume dV_core=dtau*targets.m_flow_rated/d_ref
    "Fuel salt volume that has to change hands to move dtau";

  /* The core node of the upper plenum is one of nUP equally sized nodes, so growing the core
     by dV_core means growing the whole plenum by nUP*dV_core. Of that, dV_core lands in the
     core and (nUP-1)*dV_core lands in the loop, so the downcomer has to give up nUP*dV_core
     for the loop to lose dV_core on balance. Total inventory is unchanged. */
  final parameter SI.Volume V_upperPlenum_extended=geometry_base.V_upperPlenum + geometry_base.nUP
      *dV_core "Upper plenum volume of this case";
  final parameter SI.Volume V_downcomer_reduced=geometry_base.V_downcomer - geometry_base.nUP*
      dV_core "Downcomer volume of this case";

  /* ---------------- What the steady state says this should do ---------------- */
  final parameter SI.Time tau_C_extended=targets.tau_C + dtau "Core transit time of this case";
  final parameter SI.Time tau_L_extended=targets.tau_L - dtau "Loop transit time of this case";
  final parameter Real drho_analytic_extended_pcm=1e5*MSRE.Functions.driftReactivity(
      msre.data_PG.alphas*msre.data_PG.Beta,
      msre.data_PG.lambdas,
      tau_C_extended,
      tau_L_extended) "Paper Eq. 8 at the shifted transit times [pcm]";
  final parameter Real drho_shift_asymptotic_pcm=drho_analytic_extended_pcm -
      drho_analytic_pcm "Steady-state change of the reactivity loss [pcm]";

  annotation (
    experiment(
      StopTime=750,
      __Dymola_NumberOfIntervals=7500,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>The test</h4>
<p>Section 4.1.2 of the paper asks what happens if the boundary between core and loop is drawn
differently. It lengthens Component 190-01, the upper plenum node that counts as core, from
0.0635 m to 0.1435 m and takes the same length off 190-02 and 190-03, so the core grows and the
loop shrinks by the same volume. The core transit time rises by 1.11 s, the loop transit time
falls by 1.11 s, and MARS then predicts <b>14.2 pcm less</b> reactivity loss at 50 s.</p>

<p>It is worth reproducing because it is a falsifiable number that needs no measurement, and
because it probes the one modelling choice the paper itself flags as ambiguous - where the core
ends. The plena are neutronically neither core nor loop, thermal neutrons leaking from the
graphite cause fission in them, and there is no standard rule for the importance cut-off.</p>

<h4>How this model does it, and how that differs from the paper</h4>
<p>Here the plena are pipes with equally sized nodes, so a node cannot be lengthened at the
expense of its neighbours. The same transit time shift is produced instead by growing the whole
upper plenum, which grows its core node by <code>dV_core</code>, and taking the volume out of
the downcomer so the loop still loses <code>dV_core</code> on balance. The circulating
inventory is unchanged, and so are <code>tau_C + tau_L</code> and the oscillation period.</p>

<p>The difference matters for one reason only: the added volume arrives as a <b>single coarse
cell</b> at the core outlet, roughly 0.116 m3 against 0.026 m3 in the base case, giving that
cell a residence time of about 1.4 s. That is a real loss of resolution where the precursor
concentration is highest.
<a href=\"modelica://MSRE.Verification.Discrete_DriftReactivity\">Discrete_DriftReactivity</a>
can be pointed at this configuration to price it: the discretization error grows from -0.8 pcm
in the base case to about +3.9 pcm here, so the asymptote of this case carries several pcm of
mesh error that the base case does not. Read the shift, not the absolute value.</p>

<p>The clean fix is to let a plenum have unequally sized nodes, which means giving
<a href=\"modelica://MSRE.Components.SaltPipe\">SaltPipe</a> a volume vector instead of a total
volume. That is a change to a component every part of the loop is built from, so it has not
been made here.</p>

<h4>What to compare</h4>
<table border=\"1\">
<tr><th>Quantity</th><th>Value</th></tr>
<tr><td>MARS, change of reactivity loss at 50 s</td><td>-14.2 pcm</td></tr>
<tr><td>Eq. 8, change of the steady-state loss</td><td>-20.8 pcm
(<code>drho_shift_asymptotic_pcm</code>)</td></tr>
</table>

<p>These two are not the same quantity and must not be quoted against each other. At 50 s the
long-lived groups are far from equilibrium - group 1 has a 55 s half life, and the pump has
only been running for 50 s - so the transient has realized only part of the steady-state
change. Compare like with like: read
<code>msre.rho_CR_pcm</code> at <code>msre.t_rel = 50</code> from this model and from
<a href=\"modelica://MSRE.Experiments.PumpStartup\">PumpStartup</a>, and compare that
<i>difference</i> with -14.2 pcm. The asymptotic values are then a second, independent
comparison against -20.8 pcm, and the two together say more than either alone: the first tests
the transient response, the second the steady state it is heading for.</p>
</html>"));
end PumpStartup_CoreVolumeExtended;
