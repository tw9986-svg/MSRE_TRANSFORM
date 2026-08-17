within MSRE;
package Verification
  "Checks that need no measured data, and therefore hold regardless of what is in the archive"
  extends Modelica.Icons.ExamplesPackage;

  annotation (Documentation(info="<html>
<h4>Why this package exists separately from Experiments</h4>
<p><b>Verification</b> asks whether the equations are solved correctly. <b>Validation</b> asks
whether they describe the reactor. The two need very different evidence, and mixing them is
how a model comes to look better supported than it is.</p>

<p>Everything in this package is verification. None of it uses a measurement, so none of it can
be made to agree by choosing an input: the reference values are either closed-form results or
quantities the paper reports independently of the transient it is comparing against. These
checks are the part of the library that stands on its own.</p>

<p><a href=\"modelica://MSRE.Experiments\">MSRE.Experiments</a> is the validation side, and it
is in worse shape. The two pump tests are driven by pump behaviour fitted to a verbal
description rather than to the estimated flow histories of the benchmark, and
<a href=\"modelica://MSRE.Experiments.NaturalCirculation\">NaturalCirculation</a> has no
measured boundary condition at all and refuses to run without one.</p>

<h4>The checks</h4>
<table border=\"1\">
<tr><th>Model</th><th>Checks</th><th>Needs a solver?</th></tr>
<tr><td><a href=\"modelica://MSRE.Verification.Analytic_DriftReactivity\">Analytic_DriftReactivity</a></td>
    <td>paper Eq. 8 against the three values the paper quotes from it, and the resulting
        circulating <code>Beta_eff</code> against the known MSRE value</td>
    <td>no, parameters only</td></tr>
<tr><td><a href=\"modelica://MSRE.Verification.Transient_DriftReactivity\">Transient_DriftReactivity</a></td>
    <td>the asymptotic control-rod reactivity of the pump startup transient against Eq. 8, and
        the reactivity oscillation period against the system transit time</td>
    <td>yes</td></tr>
<tr><td><a href=\"modelica://MSRE.Verification.Steady_LoopBalance\">Steady_LoopBalance</a></td>
    <td>elevation closure of the loop, mass balance between pump and core, an even flow split
        between the 15 hydraulically identical rings, no reversed ring, and the laminar flow
        regime the ring physics assumes</td>
    <td>yes</td></tr>
<tr><td><a href=\"modelica://MSRE.Verification.Properties_TransitTime\">Properties_TransitTime</a></td>
    <td>the fuel salt density the reported transit times imply, recovered without using any
        volume this library calibrated</td>
    <td>no, parameters only</td></tr>
<tr><td><a href=\"modelica://MSRE.Verification.Properties_FuelSalt\">Properties_FuelSalt</a></td>
    <td>the four property correlations against their own docstrings, the medium's
        <code>beta_const</code> against its density slope, and the gaps against the MSRE fuel
        salt medium TRANSFORM ships</td>
    <td>no, parameters only</td></tr>
</table>

<h4>Status</h4>
<table border=\"1\">
<tr><th>Model</th><th>Translated?</th><th>Simulated?</th><th>Checked how</th></tr>
<tr><td><code>Analytic_DriftReactivity</code></td><td>no</td><td>no</td>
    <td>evaluated numerically outside Modelica; passes with margin</td></tr>
<tr><td><code>Properties_TransitTime</code></td><td>no</td><td>no</td>
    <td>evaluated numerically outside Modelica; passes with margin</td></tr>
<tr><td><code>Properties_FuelSalt</code></td><td>no</td><td>no</td>
    <td><code>docs/verification/property_check.py</code> runs the same checks and passes</td></tr>
<tr><td><code>Transient_DriftReactivity</code></td><td>no</td><td>no</td><td>&mdash;</td></tr>
<tr><td><code>Steady_LoopBalance</code></td><td>partly &mdash; Dymola 2026x reported two errors,
    both since addressed at source; not re-translated</td><td>no</td><td>&mdash;</td></tr>
</table>

<p><b>Nothing in this package has been simulated.</b> No Modelica compiler, no Modelica Standard
Library and no TRANSFORM installation exist in the environment these models were written and
last revised in; the raw evidence is <code>docs/verification/toolchain_probe.log</code>. The
first three rows are checkable at parameter time and have been checked by independent
re-implementation, which is worth something but is not the same as translating the Modelica.
Treat every tolerance in this package as a stated acceptance criterion rather than an observed
result.</p>
</html>"));
end Verification;
