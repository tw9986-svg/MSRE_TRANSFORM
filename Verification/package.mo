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
</table>

<h4>Status</h4>
<p><code>Analytic_DriftReactivity</code> has been evaluated numerically outside Modelica and
its assertions pass with margin. <code>Transient_DriftReactivity</code> and
<code>Steady_LoopBalance</code> have never been run: no Modelica compiler was available while
this library was written. Treat them as stated acceptance criteria rather than as results.</p>
</html>"));
end Verification;
