within MSRE.Verification;
model Transient_DriftReactivity
  "Check the pump startup transient against paper Eq. 8 and against the system transit time"
  extends MSRE.Experiments.PumpStartup(t_null=600);

  parameter SI.Time t_settled=750
    "Time after the start of the transient by which the asymptote is taken to be reached. Chosen well beyond the longest precursor half-life of 55 s"
    annotation (Dialog(group="Acceptance criteria"));
  parameter Real tol_rho_pcm=8
    "Tolerance on the asymptotic reactivity [pcm]. The paper's own transient sits 1.9 pcm below its Eq. 8 value"
    annotation (Dialog(group="Acceptance criteria"));
  parameter Real tol_period=0.10
    "Relative tolerance on the oscillation period"
    annotation (Dialog(group="Acceptance criteria"));

  SIadd.NonDim err_rho=msre.rho_CR_pcm - drho_analytic_pcm
    "Transient minus analytic asymptotic reactivity [pcm]";

protected
  discrete Real t_peak1(start=0, fixed=true) "Time of the first reactivity peak";
  discrete Real t_peak2(start=0, fixed=true) "Time of the second reactivity peak";
  discrete Integer nPeaks(start=0, fixed=true) "Peaks seen so far";
  Real drho_dt=der(msre.rho_CR_pcm) "Rate of change of the control rod reactivity";
  Boolean rising=drho_dt > 0 "Reactivity currently increasing";

equation
  /* The precursors that leave the core come back one system transit time later, so the
     reactivity peaks are spaced by tau_core + tau_loop. A peak is a falling edge of `rising`;
     the t_rel guard skips the ramp at the very start of the transient. */
  when not rising and pre(rising) and msre.t_rel > 5 then
    nPeaks = pre(nPeaks) + 1;
    t_peak1 = if pre(nPeaks) == 0 then msre.t_rel else pre(t_peak1);
    t_peak2 = if pre(nPeaks) == 1 then msre.t_rel else pre(t_peak2);
  end when;

  when msre.t_rel >= t_settled then
    assert(abs(msre.rho_CR_pcm - drho_analytic_pcm) < tol_rho_pcm,
      "The transient settles at a control rod reactivity of " + String(msre.rho_CR_pcm)
       + " pcm, while paper Eq. 8 at the same transit times gives " + String(drho_analytic_pcm)
       + " pcm. These have to agree: Eq. 8 is the steady-state limit of the same precursor
transport the transient solves. A gap means the transport, the core definition used for Eq. 4,
or the power shape is wrong. For scale, the paper's own MARS transient lands 1.9 pcm below its
analytic value and calls that very good agreement.", AssertionLevel.error);

    assert(nPeaks >= 2 and abs((t_peak2 - t_peak1)/(msre.tau_core + msre.tau_loop) - 1) < tol_period,
      "The reactivity oscillation period came out as " + String(t_peak2 - t_peak1)
       + " s against a system transit time of " + String(msre.tau_core + msre.tau_loop)
       + " s. The oscillation is caused by precursors re-entering the core one transit time
after they left it, so the two must match. The paper measures 25.5 s against a transit time of
25.63 s.", AssertionLevel.error);
  end when;

  annotation (
    experiment(StopTime=1350, Tolerance=1e-6),
    Documentation(info="<html>
<h4>Two checks that need no measurement</h4>

<p><b>The asymptote.</b> Paper Eq. 8 is the steady-state limit of the precursor transport that
the transient integrates. Once the flow is steady and the long-lived groups have settled, the
control rod reactivity of the transient must converge to it. This is a genuine code-to-analytic
check: the two are computed by completely different routes, one a closed form over the
precursor data and the two transit times, the other a distributed transport solved over 400-odd
fluid volumes with the reactivity taken from Eq. 7. The paper does exactly this comparison and
gets 226.5 pcm against 228.4 pcm.</p>

<p><b>The period.</b> At the start of the test the precursors sit only in the core, because the
salt has been stagnant and whatever was in the loop has decayed. When the pump starts they are
swept out and return one system transit time later, which makes the reactivity oscillate with
that period. Matching it checks the transport velocity field and the fuel inventory
independently of any reactivity data. The paper measures peaks at 15.3, 40.7 and 66.2 s, a
period of about 25.5 s, against a transit time of 25.63 s.</p>

<h4>What this does not check</h4>
<p>The flow history itself. The pump is driven by a first-order speed ramp fitted to the
paper's description of the flow reaching rated in about 10 s, not to the estimated flow of the
benchmark, which is not in hand. Both checks here are insensitive to that: the asymptote does
not depend on how the flow got there, and the period depends on the final transit time only.
That insensitivity is why they are worth having, but it also means a pump model that is wrong
in detail will pass.</p>

<h4>Status</h4>
<p>Never executed. No Modelica compiler was available while this was written, so the peak
detection in particular has not been exercised and may need its thresholds adjusted against a
real solution. Treat the numbers as the acceptance criteria, not as results.</p>
</html>"));
end Transient_DriftReactivity;
