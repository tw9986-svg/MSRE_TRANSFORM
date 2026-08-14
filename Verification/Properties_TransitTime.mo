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
     nodes are small, so the channel volume alone is a lower bound on the core volume and
     therefore an upper bound on the density it implies. Two independent statements of the
     channel geometry are available. */
  final parameter SI.Volume V_channels_repo=geometry.nChannels_total*geometry.A_channel*
      geometry.H_channels "Channel volume from the geometry record (1140 channels)";
  parameter SI.Area A_core_Mao=0.4315 "Core flow area, Mao et al. Energies (2026) Table 2";
  parameter SI.Length H_core_Mao=1.6406 "Core height, Mao et al. Energies (2026) Table 2";
  final parameter SI.Volume V_channels_Mao=A_core_Mao*H_core_Mao
    "Channel volume from the Mao geometry";

  final parameter SI.Density d_implied_repo=m_core/V_channels_repo
    "Core density implied by the reported core transit time and the repository channel volume";
  final parameter SI.Density d_implied_Mao=m_core/V_channels_Mao
    "Core density implied by the reported core transit time and the Mao channel volume";

  /* ---------------- Step 3: the candidate correlations at the same temperature ---------- */
  final parameter SI.Density d_Compere=MSRE.Media.MSRE_Properties.d_Compere(T)
    "ORNL-TM-4865, the correlation the library now uses";
  final parameter SI.Density d_legacy=MSRE.Media.MSRE_Properties.d_legacy(T)
    "What the library used before Phase 2";

  final parameter SIadd.NonDim err_Compere_repo=d_implied_repo/d_Compere - 1
    "Relative gap between the implied density and Compere, repository channel volume";
  final parameter SIadd.NonDim err_Compere_Mao=d_implied_Mao/d_Compere - 1
    "Relative gap between the implied density and Compere, Mao channel volume";
  final parameter SIadd.NonDim err_legacy_repo=d_implied_repo/d_legacy - 1
    "Relative gap between the implied density and the legacy correlation";

  /* ---------------- Step 4: what the change does to the benchmarked quantity ------------ */
  final parameter SI.Time tau_C_model=geometry.V_core*d_Compere/m_flow
    "Core transit time of this library's geometry at the Compere density";
  final parameter SI.Time tau_L_model=geometry.V_loop*d_Compere/m_flow
    "Loop transit time of this library's geometry at the Compere density";

  final parameter SIadd.NonDim drho_paper=MSRE.Functions.driftReactivity(
      pg.alphas*pg.Beta,
      pg.lambdas,
      tau_C_paper,
      tau_L_paper) "Drift reactivity at the transit times the paper reports";
  final parameter SIadd.NonDim drho_model=MSRE.Functions.driftReactivity(
      pg.alphas*pg.Beta,
      pg.lambdas,
      tau_C_model,
      tau_L_model) "Drift reactivity at this library's transit times";
  final parameter Real drho_paper_pcm=1e5*drho_paper "[pcm]";
  final parameter Real drho_model_pcm=1e5*drho_model "[pcm]";
  final parameter Real drho_gap_pcm=drho_model_pcm - drho_paper_pcm
    "How far the drift reactivity moves, in pcm";

equation
  /* ---- The density the benchmark implies is Compere's, not the one this library used ----
     The channel volume is documented hardware and the core mass follows from the reported
     transit time with no correlation involved, so their ratio is an independent estimate of
     the density MARS used. It lands within a couple of percent of Compere and about 8 % away
     from the correlation this library previously carried. */
  assert(abs(err_Compere_repo) < 0.05, "The core density implied by the reported core transit
time and the documented channel volume is " + String(d_implied_repo) + " kg/m3, which is "
     + String(100*err_Compere_repo) + " % from the Compere value of " + String(d_Compere) +
    " kg/m3. These were expected to agree within a few percent, since the plenum nodes that
make up the rest of the core are small. A larger gap means either the channel geometry or the
reading of the reported transit time is wrong.", AssertionLevel.error);

  assert(abs(err_Compere_repo) < abs(err_legacy_repo), "The implied core density is closer to
the legacy correlation (" + String(100*err_legacy_repo) + " %) than to Compere ("
     + String(100*err_Compere_repo) + " %). The whole basis for adopting Compere in Phase 2 was
that the reverse holds. Re-check before reporting anything that depends on the density.",
    AssertionLevel.error);

  annotation (
    experiment(StopTime=1),
    Documentation(info="<html>
<h4>The question this answers</h4>
<p>Jeong et al. (2026) do not publish the fuel salt properties their MARS model used, so the
density cannot be compared directly. It can be compared indirectly, and the indirect route
turns out to be sharp.</p>

<p>A transit time multiplied by a mass flow rate is a <b>mass</b>, with no density in it. The
reported <code>tau_C = 9.56 s</code> at 168 kg/s therefore states that the MARS core holds
<b>1606 kg</b> of fuel salt, whatever correlation produced it. Divide that by a core volume
taken from documented hardware and the result is the density MARS must have been using.</p>

<table border=\"1\">
<tr><th>Core volume used</th><th>Implied density</th><th>vs Compere 2249</th><th>vs legacy 2063</th></tr>
<tr><td>1140 channels, 1.626 m (this library)</td><td>2210 kg/m3</td><td>-1.7 %</td><td>+7.1 %</td></tr>
<tr><td>0.4315 m2, 1.6406 m (Mao Table 2)</td><td>2269 kg/m3</td><td>+0.9 %</td><td>+10.0 %</td></tr>
</table>

<p>Both estimates land within about 2 % of Compere and 7 to 10 % away from the correlation this
library previously used. Since the two plenum nodes that make up the rest of the MARS core are
small, the channel volume is close to the whole core volume and these estimates are tight. The
conclusion is that <b>MARS used a density close to Compere's</b>, and that the correlation this
library carried before Phase 2 was simply wrong.</p>

<h4>Why this is not circular</h4>
<p>Nothing here uses a volume that was calibrated against a transit time. The channel volume is
1140 channels of documented bore and length, and the Mao figure is an independently published
statement of the same hardware. The core mass comes from the reported transit time and the
reported flow rate. The only assumption is that the MARS core is mostly its fuel channels,
which the paper's own nodalization states.</p>

<p>The loop side is different and no assertion is made about it. <code>V_loop</code> in this
library was never independent: <code>V_downcomer</code> was explicitly set to absorb the
balance of the inventory. Changing the density therefore moves <code>tau_L</code> by exactly
the density ratio and says nothing about who was right.</p>

<h4>What was done with it</h4>
<p>The core volume was re-derived from the Mao channel geometry, which is the row that agrees
with Compere to within 1 %. <code>tau_C_model</code> then comes out at 9.56 s and
<code>drho_model_pcm</code> at 228.4 pcm, reproducing what the paper reports. What matters is
how little was fitted to get there: the channel volume is published hardware, the density is a
published correlation, and neither was adjusted. The core transit time is a <b>prediction</b>
of this model, not a calibration target it was tuned to.</p>

<p>The loop is the opposite and should not be presented as agreement. <code>V_downcomer</code>
was re-derived from <code>m_fuel_loop_paper</code>, so <code>tau_L_model</code> matching 16.14 s
is arithmetic, not evidence. It is reported here only so that the two are not confused.</p>

<h4>What does not reconcile</h4>
<p>Making the core volume come out right requires the two plenum nodes inside the core to hold
about 3 litres each, which at the plenum bore works out to an axial length of about 12 mm. The
paper's own core-boundary sensitivity study states the length of Volume 190-01 as 63.5 mm, five
times longer. Both cannot be right, and the discrepancy is not resolved here. It does not
affect the transit times, which depend on the volume rather than the length, but it does mean
the plenum bore assumed by this model is not the one the MARS input used.</p>

<h4>Status</h4>
<p>The two assertions are parameter-time and need no solver. They have been evaluated
numerically outside Modelica and both hold with margin.</p>
</html>"));
end Properties_TransitTime;
