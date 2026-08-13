within MSRE.Data;
record BenchmarkTargets
  "Every quantity the reference paper reports, with the section or figure it comes from"
  extends Modelica.Icons.Record;

  /* ==================================================================
     Section 3.2 - transit times of the MARS input model
     ================================================================== */
  parameter SI.Time tau_C=9.56 "Core transit time at rated flow [Section 4.1.2]";
  parameter SI.Time tau_L=16.14 "External loop transit time at rated flow [Section 4.1.2]";
  parameter SI.Time tau_system=25.63 "System transit time at full power [Section 3.2]";
  parameter SI.Time tau_system_measured=25.2
    "Measured system transit time, Refs. [27,34] of the paper [Section 3.2]";
  parameter SI.MassFlowRate m_flow_rated=168 "Rated fuel salt flow rate [Section 4.2]";

  /* ==================================================================
     Section 4.1 - pump startup test, U-235, ~100 W, 908 K
     ================================================================== */
  parameter Real rho_startup_exp_pcm=227.3
    "Rod reactivity averaged over 25 to 45 s, experiment [Section 4.1.1, Fig. 5]";
  parameter Real rho_startup_MARS_pcm=222.4
    "Rod reactivity averaged over 25 to 45 s, MARS [Section 4.1.1, Fig. 5]";
  parameter SI.Time t_avg_start=25 "Start of the averaging window [Section 4.1.1]";
  parameter SI.Time t_avg_end=45 "End of the averaging window [Section 4.1.1]";

  parameter SI.Time t_peaks[3]={15.3,40.7,66.2}
    "Times of the first three reactivity peaks, MARS [Section 4.1.1, Fig. 6]";
  parameter SI.Time T_oscillation=25.5
    "Reactivity oscillation period implied by those peaks [Section 4.1.1]";

  parameter Real rho_asymptote_MARS_pcm=226.5
    "Asymptotic reactivity loss at 150 s, MARS [Section 4.1.2, Fig. 6]";
  parameter Real rho_asymptote_Eq8_pcm=228.4
    "The same quantity from Eq. 8 at tau_C and tau_L [Section 4.1.2]";

  /* Core volume extension sensitivity: Component 190-01 lengthened from 0.0635 m to
     0.1435 m at the expense of 190-02 and 190-03. */
  parameter SI.Time dtau_coreExtension=1.11
    "Transit time moved from the loop into the core [Section 4.1.2]";
  parameter Real drho_coreExtension_pcm=-14.2
    "Resulting change of the reactivity loss at 50 s, MARS [Section 4.1.2, Fig. 5]";

  /* ==================================================================
     Section 4.2 - pump coastdown test, U-235
     ================================================================== */
  parameter SI.Time t_coastdown_valid=70
    "The reactivity comparison is reported as good up to this time [Section 4.2]";
  parameter SI.Time t_coastdown_data_end=20
    "Estimated flow rate data end here, standard deviation 1.4 % [Section 4.2, Fig. 7]";

  /* ==================================================================
     Section 4.3 - natural circulation test, U-233
     ================================================================== */
  parameter SI.Power Q_NC_start=8.0e3 "Initial core power [Section 4.3]";
  parameter SI.MassFlowRate m_flow_NC_start=1.46
    "Natural circulation flow at 0 s, MARS [Section 4.3, Fig. 10]";
  parameter SI.MassFlowRate m_flow_NC_end=4.45
    "Natural circulation flow at 21000 s, MARS [Section 4.3, Fig. 10]";
  parameter Real drho_NC_start_pcm=0.9
    "Drift reactivity from Eq. 8 at 1.46 kg/s [Section 4.3]";
  parameter Real drho_NC_end_pcm=6.7
    "Drift reactivity from Eq. 8 at 4.45 kg/s [Section 4.3]";
  parameter SI.TemperatureDifference dT_NC=-4.0
    "Change of the average primary fuel salt temperature over the transient [Section 4.3]";
  parameter Real drho_NC_temperature_pcm=60
    "Positive reactivity that temperature change is worth [Section 4.3]";
  parameter SI.Power Q_NC_end_MARS=304.5e3
    "Core power at 21000 s, MARS base case [Section 4.3, Fig. 11]";
  parameter SI.Power Q_NC_end_exp=354e3
    "Core power at 21000 s, experiment [Section 4.3, Fig. 11]";
  parameter SI.Power dQ_NC_case_C1=12.2e3
    "Power increase of sensitivity case C1, 10 % larger heat exchanger area [Section 4.3]";
  parameter SI.Time t_NC_steps[5]={0,1200,4500,8400,11700}
    "Times at which the radiator heat removal was stepped up [Section 4.3]";

  /* ==================================================================
     Independent of the paper
     ================================================================== */
  parameter SIadd.NonDim Beta_static_U235=0.006781
    "Static delayed neutron fraction, sum of paper Table 1";
  parameter SIadd.NonDim Beta_circulating_U235=0.0045
    "Circulating value measured at the MSRE and quoted throughout the literature";

  annotation (defaultComponentName="targets", Documentation(info="<html>
<h4>What this record is for</h4>
<p>It is the single place where the numbers this library is benchmarked against are written
down, so that an assertion, a plot annotation and a README table cannot drift apart from one
another. Every entry carries the section or figure of</p>

<blockquote>
J.J. Jeong, Y.J. Cho, H.C. Lee, B. Yun, <i>Benchmarking the MARS code for molten salt reactor
applications using MSRE transient experiments</i>, Nuclear Engineering and Technology 58 (2026)
104438.
</blockquote>

<p>that it was taken from.</p>

<h4>Read the provenance before using an entry as an acceptance criterion</h4>
<p>The entries are not all the same kind of number and they do not all carry the same weight:</p>

<table border=\"1\">
<tr><th>Kind</th><th>Entries</th><th>What agreement proves</th></tr>
<tr><td>Measurement</td><td><code>rho_startup_exp_pcm</code>,
<code>tau_system_measured</code>, <code>Q_NC_end_exp</code></td>
<td>Validation. These are the only entries that are evidence about the MSRE rather than about
a code.</td></tr>
<tr><td>Analytic</td><td><code>rho_asymptote_Eq8_pcm</code>, <code>drho_NC_start_pcm</code>,
<code>drho_NC_end_pcm</code></td>
<td>Verification only: both sides come from Eq. 8, so agreement means the equation and the
precursor data are implemented correctly.</td></tr>
<tr><td>MARS result</td><td>everything else</td>
<td>Code-to-code comparison. A gap is a difference between two models, and says nothing on its
own about which is closer to the reactor.</td></tr>
</table>

<p>Two entries deserve a specific warning.</p>

<p><code>drho_coreExtension_pcm</code> is read off a transient at <b>50 s</b>, not from a
converged asymptote. The long-lived precursor groups are nowhere near equilibrium at 50 s, so
it must not be compared against the steady-state change that Eq. 8 predicts for the same
transit time shift, which is about -20.8 pcm. See
<a href=\"modelica://MSRE.Experiments.PumpStartup_CoreVolumeExtended\">PumpStartup_CoreVolumeExtended</a>.</p>

<p><code>tau_C</code> and <code>tau_L</code> are MARS results, not measurements; only their sum
has a measured counterpart, and even that is 25.2 s against the 25.63 s MARS computes. The
geometry in <a href=\"modelica://MSRE.Data.Geometry\">Geometry</a> is calibrated to
<code>tau_C</code> and <code>tau_L</code>, so any check that consumes them is checking
consistency with the MARS input model, not with the MSRE.</p>
</html>"));
end BenchmarkTargets;
