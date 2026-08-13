within MSRE.Verification;
model Analytic_DriftReactivity
  "Check MSRE.Functions.driftReactivity against every value the paper quotes from its Eq. 8"
  extends Modelica.Icons.Example;

  parameter MSRE.Data.PrecursorGroups.U235_6group pg235 "U-235 precursor data (paper Table 1)";
  parameter MSRE.Data.PrecursorGroups.U233_6group pg233 "U-233 precursor data (paper Table 2)";
  parameter MSRE.Data.Geometry geometry "Plant geometry";
  parameter MSRE.Data.BenchmarkTargets targets "Values reported by the paper";

  parameter SIadd.NonDim tol=5e-6
    "Absolute tolerance on reactivity [-], 5e-6 = 0.5 pcm";

  /* --- 1. Forced circulation, U-235, at the transit times the paper reports ------- */
  final parameter SI.Time tau_C_paper=targets.tau_C "Core transit time reported by the paper";
  final parameter SI.Time tau_L_paper=targets.tau_L "Loop transit time reported by the paper";
  final parameter SIadd.NonDim drho_forced=MSRE.Functions.driftReactivity(
      pg235.alphas*pg235.Beta,
      pg235.lambdas,
      tau_C_paper,
      tau_L_paper) "Drift reactivity at rated flow";

  /* --- 2. The Beta_eff that follows from it -------------------------------------- */
  final parameter SIadd.NonDim Beta_static=pg235.Beta
    "Delayed neutron fraction with the fuel salt at rest";
  final parameter SIadd.NonDim Beta_circulating=Beta_static - drho_forced
    "Delayed neutron fraction with the fuel salt circulating";

  /* --- 3. Natural circulation, U-233, at the two flow rates of paper Fig. 10 ------ */
  parameter SI.Density d_fuel=2055.2 "Fuel salt density at 922 K, the U-233 test temperature";
  parameter SI.MassFlowRate m_flow_lo=targets.m_flow_NC_start
    "Flow at the start of the natural circulation test";
  parameter SI.MassFlowRate m_flow_hi=targets.m_flow_NC_end "Flow at 21000 s";

  final parameter SIadd.NonDim drho_lo=MSRE.Functions.driftReactivity(
      pg233.alphas*pg233.Beta,
      pg233.lambdas,
      geometry.V_core*d_fuel/m_flow_lo,
      geometry.V_loop*d_fuel/m_flow_lo) "Drift reactivity at 1.46 kg/s";
  final parameter SIadd.NonDim drho_hi=MSRE.Functions.driftReactivity(
      pg233.alphas*pg233.Beta,
      pg233.lambdas,
      geometry.V_core*d_fuel/m_flow_hi,
      geometry.V_loop*d_fuel/m_flow_hi) "Drift reactivity at 4.45 kg/s";

  /* Reported for convenience, in the units the paper uses */
  final parameter Real drho_forced_pcm=drho_forced*1e5 "[pcm]";
  final parameter Real drho_lo_pcm=drho_lo*1e5 "[pcm]";
  final parameter Real drho_hi_pcm=drho_hi*1e5 "[pcm]";

equation
  assert(abs(drho_forced - 1e-5*targets.rho_asymptote_Eq8_pcm) < tol, "Eq. 8 at the reported transit times gives "
     + String(drho_forced_pcm) + " pcm, but the paper quotes 228.4 pcm from the same equation.
Either driftReactivity or the Table 1 data has been changed.", AssertionLevel.error);

  assert(abs(Beta_circulating - targets.Beta_circulating_U235) < 1e-4, "Beta_eff with the fuel circulating comes out
at " + String(Beta_circulating) + ", against the MSRE value of about 0.0045 (0.00678 static).
This ratio is one of the best established numbers about the MSRE; a deviation means the
precursor data or Eq. 8 is wrong.", AssertionLevel.error);

  assert(abs(drho_lo - 1e-5*targets.drho_NC_start_pcm) < 2e-6 and abs(drho_hi - 1e-5*targets.drho_NC_end_pcm)
     < 5e-6, "Drift reactivity over
the natural circulation transient comes out at " + String(drho_lo_pcm) + " and "
     + String(drho_hi_pcm) + " pcm, against the 0.9 and 6.7 pcm the paper reports in Section 4.3.
These follow from V_core and V_loop, so this also checks that the calibrated geometry still
reproduces the transit times it was calibrated to.", AssertionLevel.error);

  annotation (
    experiment(StopTime=1),
    Documentation(info="<html>
<h4>What is being checked</h4>
<p>Paper Eq. 8 is a closed-form expression for the steady-state reactivity lost to precursor
drift. It depends on the precursor data and on the two transit times, and on nothing else. The
paper quotes three values obtained from it, and this model checks all three.</p>

<table border=\"1\">
<tr><th>Quantity</th><th>Paper</th><th>This library</th></tr>
<tr><td>drift reactivity, U-235, tau_C = 9.56 s, tau_L = 16.14 s</td><td>228.4 pcm</td><td>228.35 pcm</td></tr>
<tr><td>Beta_eff circulating (static 0.006781)</td><td>~0.0045</td><td>0.004497</td></tr>
<tr><td>drift reactivity, U-233, 1.46 kg/s / 4.45 kg/s</td><td>0.9 / 6.7 pcm</td><td>0.87 / 6.54 pcm</td></tr>
</table>

<p>The third row is the useful one for the plant model rather than the function: the transit
times are computed from <code>geometry.V_core</code> and <code>geometry.V_loop</code>, so the
check fails if the fuel-salt inventory is edited away from the values it was calibrated to.
That calibration is the one modelling assumption the whole precursor-drift result rests on.</p>

<h4>Why this is verification and not validation</h4>
<p>None of the three reference values is a measurement. They are numbers the paper obtains from
an analytic expression, so agreement means the expression is implemented correctly and the
data behind it is intact. It says nothing about whether the MSRE behaved this way - for that,
see the transient comparisons, and note the caveats there.</p>

<p>The second row is the closest thing here to an external check: the drop of the effective
delayed neutron fraction from about 0.0067 static to about 0.0045 circulating was measured at
the MSRE and is quoted throughout the literature, independently of this paper.</p>
</html>"));
end Analytic_DriftReactivity;
