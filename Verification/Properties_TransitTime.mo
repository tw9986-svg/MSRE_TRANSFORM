within MSRE.Verification;
model Properties_TransitTime
  "Recover the fuel salt density the reported transit times imply, without using any volume from this library"
  extends Modelica.Icons.Example;

  parameter MSRE.Data.Geometry geometry "Plant geometry";
  parameter MSRE.Data.PrecursorGroups.U235_6group pg "U-235 precursor data (paper Table 1)";

  /* ---------------- What the paper reports ---------------- */
  parameter SI.Time tau_C_paper=9.56 "Core transit time reported by the paper";
  parameter SI.Time tau_L_paper=16.14 "External loop transit time reported by the paper";
  parameter SI.MassFlowRate m_flow=168 "Rated fuel salt mass flow rate";
  parameter SI.Temperature T=908 "Fuel salt temperature of the zero-power tests";

  /* ---------------- Step 1: the density-free content of the benchmark ----------------
     A transit time multiplied by a mass flow rate is a mass. These two numbers therefore
     survive any change of density correlation, and they are the only thing the reported
     transit times actually pin down. */
  final parameter SI.Mass m_core=tau_C_paper*m_flow "Fuel salt mass in the reactor core";
  final parameter SI.Mass m_loop=tau_L_paper*m_flow "Fuel salt mass in the external loop";

  /* ---------------- Step 2: candidate core volumes from published hardware ----------------
     The MARS core is the fuel channels plus one lower and one upper plenum node. The plenum
     nodes are small in this record, so the channel volume alone is close to the whole core
     volume and the density it implies is close to an upper bound. Two independent statements
     of the channel geometry are available. */
  final parameter SI.Volume V_channels_repo=geometry.nChannels_total*geometry.A_channel*
      geometry.H_channels
    "Channel volume from the geometry record (1140 channels of ORNL/INL hardware cross-section)";
  parameter SI.Area A_core_Mao=0.4315 "Core flow area, Mao et al. Energies (2026) Table 2";
  parameter SI.Length H_core_Mao=1.6406 "Core height, Mao et al. Energies (2026) Table 2";
  final parameter SI.Volume V_channels_Mao=A_core_Mao*H_core_Mao
    "Channel volume from the retired Mao geometry, kept as a reference comparison";

  final parameter SI.Density d_implied_repo=m_core/V_channels_repo
    "Core density implied by the reported core transit time and the repository channel volume";
  final parameter SI.Density d_implied_Mao=m_core/V_channels_Mao
    "Core density implied by the reported core transit time and the Mao channel volume";

  /* ---------------- Step 3: the candidate correlations at the same temperature ----------
     d_Cantor is the ACTIVE one and it is read from the same function the fuel salt medium
     uses, so this model cannot drift away from the medium. The other two are REFERENCE
     comparisons kept for provenance and are not used by any assertion or by any active
     result below. */
  final parameter SI.Density d_Cantor=MSRE.Media.FuelSalt.Utilities.d_T(T)
    "ACTIVE | Cantor ORNL-TM-2316, the correlation the fuel salt medium runs on (2196.514 kg/m3 at 908 K)";
  final parameter SI.Density d_Compere=MSRE.Media.MSRE_Properties.d_Compere(T)
    "REFERENCE ONLY | ORNL-TM-4865, the correlation this library used between Phase 2 and Phase 3 (2249.322 kg/m3 at 908 K)";
  final parameter SI.Density d_legacy=MSRE.Media.MSRE_Properties.d_legacy(T)
    "REFERENCE ONLY | what the library used before Phase 2 (2063.097 kg/m3 at 908 K)";

  final parameter SIadd.NonDim err_Cantor_repo=d_implied_repo/d_Cantor - 1
    "ACTIVE | relative gap between the implied density and Cantor, repository channel volume";
  final parameter SIadd.NonDim err_Cantor_Mao=d_implied_Mao/d_Cantor - 1
    "ACTIVE | relative gap between the implied density and Cantor, Mao channel volume";
  final parameter SIadd.NonDim err_Compere_repo=d_implied_repo/d_Compere - 1
    "REFERENCE ONLY | the same gap against Compere";
  final parameter SIadd.NonDim err_Compere_Mao=d_implied_Mao/d_Compere - 1
    "REFERENCE ONLY | the same gap against Compere, Mao channel volume";
  final parameter SIadd.NonDim err_legacy_repo=d_implied_repo/d_legacy - 1
    "REFERENCE ONLY | the same gap against the pre-Phase-2 correlation";

  /* ---------------- Step 4: transit times of this library's geometry --------------------
     tau = rho*V/m_flow. The benchmark states a MASS flow rate, so a density is needed to turn
     a volume into a transit time and this model is genuinely density dependent. The Cantor row
     is the active result; the other two exist so that the Compere-versus-Cantor difference is
     a computed number rather than an argument. */
  final parameter SI.Time tau_C_model=geometry.V_core*d_Cantor/m_flow
    "ACTIVE | core transit time of this library's geometry at the Cantor density";
  final parameter SI.Time tau_L_model=geometry.V_loop*d_Cantor/m_flow
    "ACTIVE | loop transit time of this library's geometry at the Cantor density";
  final parameter SI.Time tau_S_model=tau_C_model + tau_L_model
    "ACTIVE | system transit time at the Cantor density";

  final parameter SI.Time tau_C_Compere=geometry.V_core*d_Compere/m_flow
    "REFERENCE ONLY | the same at the Compere density";
  final parameter SI.Time tau_L_Compere=geometry.V_loop*d_Compere/m_flow
    "REFERENCE ONLY | the same at the Compere density";
  final parameter SI.Time tau_S_Compere=tau_C_Compere + tau_L_Compere
    "REFERENCE ONLY | the same at the Compere density";
  final parameter SI.Time tau_C_legacy=geometry.V_core*d_legacy/m_flow
    "REFERENCE ONLY | the same at the pre-Phase-2 density";
  final parameter SI.Time tau_L_legacy=geometry.V_loop*d_legacy/m_flow
    "REFERENCE ONLY | the same at the pre-Phase-2 density";
  final parameter SI.Time tau_S_legacy=tau_C_legacy + tau_L_legacy
    "REFERENCE ONLY | the same at the pre-Phase-2 density";

  final parameter SIadd.NonDim drho_paper=MSRE.Functions.driftReactivity(
      pg.alphas*pg.Beta,
      pg.lambdas,
      tau_C_paper,
      tau_L_paper) "Drift reactivity at the transit times the paper reports";
  final parameter SIadd.NonDim drho_model=MSRE.Functions.driftReactivity(
      pg.alphas*pg.Beta,
      pg.lambdas,
      tau_C_model,
      tau_L_model) "ACTIVE | drift reactivity at this library's transit times";
  final parameter SIadd.NonDim drho_Compere=MSRE.Functions.driftReactivity(
      pg.alphas*pg.Beta,
      pg.lambdas,
      tau_C_Compere,
      tau_L_Compere) "REFERENCE ONLY | the same at the Compere density";
  final parameter Real drho_paper_pcm=1e5*drho_paper "[pcm]";
  final parameter Real drho_model_pcm=1e5*drho_model "[pcm]";
  final parameter Real drho_Compere_pcm=1e5*drho_Compere "[pcm]";
  final parameter Real drho_gap_pcm=drho_model_pcm - drho_paper_pcm
    "How far the drift reactivity moves, in pcm";

equation
  /* ---- What the benchmark implies about the density, against the ACTIVE correlation ----
     The channel volume is documented hardware and the core mass follows from the reported
     transit time with no correlation involved, so their ratio is an independent estimate of
     the density MARS used. This assertion was written when the core geometry came from the
     Mao flow area and it held with margin. It no longer holds: with the channel geometry built
     from the ORNL/INL hardware dimensions the implied density is far above every correlation,
     which is the PARTIAL_GEOMETRY_BASELINE mismatch and not a property error. The tolerance is
     deliberately left at 5 % - see open item O-14. */
  assert(abs(err_Cantor_repo) < 0.05, "The core density implied by the reported core transit
time and the documented channel volume is " + String(d_implied_repo) + " kg/m3, which is "
     + String(100*err_Cantor_repo) + " % from the active Cantor value of " + String(d_Cantor) +
    " kg/m3. These were expected to agree within a few percent, since the plenum nodes that
make up the rest of the core are small. A larger gap means either the channel geometry or the
reading of the reported transit time is wrong, or the MARS core node contains salt this record
counts as plenum and downcomer. See MSRE.Data.Geometry, open items O-12 and O-14.",
    AssertionLevel.error);

  assert(abs(err_Cantor_repo) < abs(err_legacy_repo), "The implied core density is closer to
the pre-Phase-2 correlation (" + String(100*err_legacy_repo) + " %) than to the active Cantor
correlation (" + String(100*err_Cantor_repo) + " %). Every property decision since Phase 2 rests
on the reverse holding. Re-check before reporting anything that depends on the density.",
    AssertionLevel.error);

  annotation (
    experiment(StopTime=1),
    Documentation(info="<html>
<h4>Active density baseline</h4>
<p><b>ACTIVE verification density: Cantor / ORNL-TM-2316</b>, read from
<a href=\"modelica://MSRE.Media.FuelSalt.Utilities.d_T\">FuelSalt.Utilities.d_T</a>, which is
the same function the fuel salt medium itself uses. The Compere and pre-Phase-2 correlations
are retained here only for reference comparison and provenance tracking; no assertion and no
active result depends on them. The current transit-time mismatch is attributed to the
unresolved partial geometry baseline and must not be corrected by changing the density model
or the assertion tolerances.</p>

<h4>The question this answers</h4>
<p>Jeong et al. (2026) do not publish the fuel salt properties their MARS model used, so the
density cannot be compared directly. It can be compared indirectly.</p>

<p>A transit time multiplied by a mass flow rate is a <b>mass</b>, with no density in it. The
reported <code>tau_C = 9.56 s</code> at 168 kg/s therefore states that the MARS core holds
<b>1606 kg</b> of fuel salt, whatever correlation produced it. Divide that by a core volume
taken from documented hardware and the result is the density MARS must have been using.</p>

<table border=\"1\">
<tr><th>Core volume used</th><th>Implied density</th><th>vs Cantor 2196.5</th>
    <th>vs Compere 2249.3</th><th>vs legacy 2063.1</th></tr>
<tr><td>1140 channels of ORNL/INL cross-section, 1.6256 m (<b>this library</b>)</td>
    <td><b>3014.2 kg/m3</b></td><td><b>+37.2 %</b></td><td>+34.0 %</td><td>+46.1 %</td></tr>
<tr><td>0.4315 m2 x 1.6406 m (Mao Table 2, retired)</td>
    <td>2268.7 kg/m3</td><td>+3.3 %</td><td>+0.9 %</td><td>+10.0 %</td></tr>
</table>

<h4>What that table says now, and what it used to say</h4>
<p>Read the second row alone and the implied density lands within a few percent of the
published correlations, which is what this model was written to show. Read the first row and it
does not: 1606 kg cannot fit in 1140 channels of documented cross-section at any plausible
MSRE fuel-salt density. The difference between the two rows is entirely the flow area - Mao's
0.4315 m2 against the 0.32778 m2 that 1140 channels of 1.2 x 0.4 in with 0.2 in rounded corners
actually add up to.</p>

<p>Since the core geometry was rebuilt from the hardware dimensions, the first row is the
active one. The conclusion has therefore inverted: this is no longer evidence about which
density correlation MARS used, it is evidence that <b>the MARS core node is not the fuel
channels alone</b>. Either the plena are much larger than this record assumes or MARS counts
salt as core that this record counts as plenum and downcomer. See
<a href=\"modelica://MSRE.Data.Geometry\">Data.Geometry</a>, open item O-12.</p>

<h4>Transit times of this library's geometry</h4>
<table border=\"1\">
<tr><th>Property model</th><th>rho at 908 K</th><th>tau_core</th><th>tau_loop</th>
    <th>tau_system</th><th>drift reactivity</th></tr>
<tr><td><b>Cantor (ACTIVE)</b></td><td><b>2196.514</b></td><td><b>9.877 s</b></td>
    <td><b>17.534 s</b></td><td><b>27.411 s</b></td><td><b>227.1 pcm</b></td></tr>
<tr><td>Compere (reference)</td><td>2249.322</td><td>10.114 s</td><td>17.956 s</td>
    <td>28.070 s</td><td>224.4 pcm</td></tr>
<tr><td>legacy (reference)</td><td>2063.097</td><td>9.277 s</td><td>16.469 s</td>
    <td>25.746 s</td><td>234.1 pcm</td></tr>
<tr><td><i>paper (MARS)</i></td><td><i>not published</i></td><td><i>9.56 s</i></td>
    <td><i>16.14 s</i></td><td><i>25.63 s</i></td><td><i>228.4 pcm</i></td></tr>
</table>

<p><code>tau = rho*V/m_flow</code>: the benchmark states a <b>mass</b> flow rate, so this model
is genuinely density dependent and switching the baseline moves every row. The gap to the paper
is now +3.3 % on the core side and +8.6 % on the loop side, against a 2.3 % spread between the
two density correlations, so <b>the residual mismatch is not a Compere-versus-Cantor
question</b>. It also should not be read as agreement: the core row is that close because the
two core-boundary nodes are assumed to be equal-volume thirds of the referenced plenum totals,
which is an assumption and not a measurement. See
<a href=\"modelica://MSRE.Data.Geometry\">Data.Geometry</a>, open item O-12B.</p>

<h4>Why this is not circular</h4>
<p>Nothing here uses a volume that was calibrated against a transit time. The channel volume is
1140 channels of documented bore and length. The core mass comes from the reported transit time
and the reported flow rate. The only assumption is that the MARS core is mostly its fuel
channels, which is exactly the assumption the first row of the table now calls into
question.</p>

<p>The loop side is different and no assertion is made about it. <code>V_loop</code> in this
library was never independent until Phase 5: <code>V_downcomer</code> had been set to absorb
the balance of the inventory. It is now the vessel annulus, but <code>L_downcomer</code>,
<code>V_pumpBowl</code> and the pipe lengths remain assumptions, so the loop row is weaker
evidence than the core row.</p>

<h4>Status of the assertions</h4>
<p>Both are parameter-time and need no solver.</p>
<ul>
<li>The first <b>fails</b>: 37.2 % against a 5 % tolerance. This is
<code>EXPECTED_MISMATCH_DURING_PARTIAL_GEOMETRY_BASELINE</code>. It failed at 34.0 % before the
density baseline was unified, so unifying it did not cause the failure and does not cure it.
The tolerance has deliberately not been widened - see open item O-14.</li>
<li>The second <b>holds</b>: 37.2 % against 46.1 %.</li>
</ul>
<p>Evaluated numerically outside Modelica. No Modelica toolchain is available in the
environment these values were produced in, so they are hand calculations rather than
simulation results.</p>
</html>"));
end Properties_TransitTime;
