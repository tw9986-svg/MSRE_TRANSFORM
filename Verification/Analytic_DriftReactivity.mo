within MSRE.Verification;
model Analytic_DriftReactivity
  "Check MSRE.Functions.driftReactivity against every value the paper quotes from its Eq. 8"
  extends Modelica.Icons.Example;

  parameter MSRE.Data.PrecursorGroups.U235_6group pg235 "U-235 precursor data (paper Table 1)";
  parameter MSRE.Data.PrecursorGroups.U233_6group pg233 "U-233 precursor data (paper Table 2)";
  parameter MSRE.Data.Geometry geometry "Plant geometry";

  parameter SIadd.NonDim tol=5e-6
    "Absolute tolerance on reactivity [-], 5e-6 = 0.5 pcm";

  /* --- 1. Forced circulation, U-235, at the transit times the paper reports ------- */
  final parameter SI.Time tau_C_paper=9.56 "Core transit time reported by the paper";
  final parameter SI.Time tau_L_paper=16.14 "Loop transit time reported by the paper";
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

  /* --- 3. Natural circulation, U-233, at the two flow rates of paper Fig. 10 ------
     The transit times here are rho*V/m_flow, so a density is needed. It is read from the same
     function the fuel salt medium uses, so this model cannot run on a different property
     baseline from the plant model. The Compere row below is a REFERENCE comparison only. */
  final parameter SI.Density d_fuel=MSRE.Media.FuelSalt.Utilities.d_T(922)
    "ACTIVE | Cantor ORNL-TM-2316 at 922 K, the U-233 test temperature (2188.646 kg/m3)";
  final parameter SI.Density d_fuel_Compere=MSRE.Media.MSRE_Properties.d_Compere(922)
    "REFERENCE ONLY | ORNL-TM-4865 at the same temperature (2242.140 kg/m3); used by no active result";
  parameter SI.MassFlowRate m_flow_lo=1.46 "Flow at the start of the natural circulation test";
  parameter SI.MassFlowRate m_flow_hi=4.45 "Flow at 21000 s";

  final parameter SIadd.NonDim drho_lo=MSRE.Functions.driftReactivity(
      pg233.alphas*pg233.Beta,
      pg233.lambdas,
      geometry.V_core*d_fuel/m_flow_lo,
      geometry.V_loop*d_fuel/m_flow_lo) "ACTIVE | drift reactivity at 1.46 kg/s";
  final parameter SIadd.NonDim drho_hi=MSRE.Functions.driftReactivity(
      pg233.alphas*pg233.Beta,
      pg233.lambdas,
      geometry.V_core*d_fuel/m_flow_hi,
      geometry.V_loop*d_fuel/m_flow_hi) "ACTIVE | drift reactivity at 4.45 kg/s";

  final parameter SIadd.NonDim drho_lo_Compere=MSRE.Functions.driftReactivity(
      pg233.alphas*pg233.Beta,
      pg233.lambdas,
      geometry.V_core*d_fuel_Compere/m_flow_lo,
      geometry.V_loop*d_fuel_Compere/m_flow_lo)
    "REFERENCE ONLY | the same at the Compere density";
  final parameter SIadd.NonDim drho_hi_Compere=MSRE.Functions.driftReactivity(
      pg233.alphas*pg233.Beta,
      pg233.lambdas,
      geometry.V_core*d_fuel_Compere/m_flow_hi,
      geometry.V_loop*d_fuel_Compere/m_flow_hi)
    "REFERENCE ONLY | the same at the Compere density";

  /* Reported for convenience, in the units the paper uses */
  final parameter Real drho_forced_pcm=drho_forced*1e5 "[pcm]";
  final parameter Real drho_lo_pcm=drho_lo*1e5 "[pcm]";
  final parameter Real drho_hi_pcm=drho_hi*1e5 "[pcm]";
  final parameter Real drho_lo_Compere_pcm=drho_lo_Compere*1e5 "[pcm]";
  final parameter Real drho_hi_Compere_pcm=drho_hi_Compere*1e5 "[pcm]";

equation
  assert(abs(drho_forced - 228.4e-5) < tol, "Eq. 8 at the reported transit times gives "
     + String(drho_forced_pcm) + " pcm, but the paper quotes 228.4 pcm from the same equation.
Either driftReactivity or the Table 1 data has been changed.", AssertionLevel.error);

  assert(abs(Beta_circulating - 0.0045) < 1e-4, "Beta_eff with the fuel circulating comes out
at " + String(Beta_circulating) + ", against the MSRE value of about 0.0045 (0.00678 static).
This ratio is one of the best established numbers about the MSRE; a deviation means the
precursor data or Eq. 8 is wrong.", AssertionLevel.error);

  /* Unlike the two above, this one tests the geometry rather than Eq. 8: drho_lo and drho_hi
     follow from V_core and V_loop. Neither volume is fitted to a transit time, so it checks a
     prediction rather than a calibration. The low-flow case now holds at 0.818 pcm and the
     high-flow case misses by about 0.001 pcm at 6.199. It also misses at the Compere density
     (0.781 and 5.959), so nothing here is a property-baseline effect. The tolerances are
     deliberately unchanged; see open item O-14. */
  assert(abs(drho_lo - 0.9e-5) < 2e-6 and abs(drho_hi - 6.7e-5) < 5e-6, "Drift reactivity over
the natural circulation transient comes out at " + String(drho_lo_pcm) + " and "
     + String(drho_hi_pcm) + " pcm, against the 0.9 and 6.7 pcm the paper reports in Section 4.3.
These follow from V_core and V_loop, so this also checks that the geometry reproduces the
transit times. The low-flow case holds; the high-flow case misses its 0.5 pcm limit by about
0.001 pcm, which is marginal rather than informative. Both volumes rest on the core-boundary
nodes being equal-volume thirds of the referenced plenum totals, which is an assumption. See
MSRE.Data.Geometry, open items O-12B and O-14.", AssertionLevel.error);

  annotation (
    experiment(StopTime=1),
    Documentation(info="<html>
<h4>What is being checked</h4>
<p>Paper Eq. 8 is a closed-form expression for the steady-state reactivity lost to precursor
drift. It depends on the precursor data and on the two transit times, and on nothing else. The
paper quotes three values obtained from it, and this model checks all three.</p>

<h4>Active density baseline</h4>
<p><b>ACTIVE verification density: Cantor / ORNL-TM-2316</b>, read from
<a href=\"modelica://MSRE.Media.FuelSalt.Utilities.d_T\">FuelSalt.Utilities.d_T</a>, the same
function the fuel salt medium uses. The Compere correlation is retained here only for
reference comparison and provenance tracking, as <code>d_fuel_Compere</code>,
<code>drho_lo_Compere</code> and <code>drho_hi_Compere</code>; no assertion and no active
result depends on it. The current mismatch in the third row is attributed to the unresolved
partial geometry baseline and must not be corrected by changing the density model or the
assertion tolerances.</p>

<table border=\"1\">
<tr><th>Quantity</th><th>Paper</th><th>This library (ACTIVE, Cantor)</th>
    <th>Compere (reference)</th></tr>
<tr><td>drift reactivity, U-235, tau_C = 9.56 s, tau_L = 16.14 s</td><td>228.4 pcm</td>
    <td>228.35 pcm</td><td>same - density free</td></tr>
<tr><td>Beta_eff circulating (static 0.006781)</td><td>~0.0045</td><td>0.004497</td>
    <td>same - density free</td></tr>
<tr><td>drift reactivity, U-233, 1.46 kg/s / 4.45 kg/s</td><td>0.9 / 6.7 pcm</td>
    <td><b>0.818 / 6.199 pcm</b></td><td>0.781 / 5.959 pcm</td></tr>
</table>

<p>The first two rows use the transit times the paper reports directly, so no density enters
them and switching the baseline leaves them untouched. They still hold.</p>

<p>The third row is the useful one for the plant model rather than the function: those transit
times are <code>rho*V/m_flow</code> from <code>geometry.V_core</code> and
<code>geometry.V_loop</code>, so the row moves whenever either the geometry or the density
moves. The low-flow case now holds at 0.82 pcm against 0.9 +- 0.2; the high-flow case is
6.1991 pcm against 6.7 +- 0.5, a deviation of 0.5009 pcm against a 0.5 pcm limit, so it fails
by 0.0009 pcm. That is a marginal fail and should be read as such rather than as a result.
Neither tolerance was touched.</p>

<p>Both numbers moved because the two core-boundary nodes became equal-volume thirds of the
referenced plenum totals, which enlarged <code>V_core</code> and reduced <code>V_loop</code>.
That is an assumption, not a measurement, so the improvement is not evidence that the geometry
is right. See <a href=\"modelica://MSRE.Data.Geometry\">Data.Geometry</a>, open items O-12B
and O-14.</p>

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
