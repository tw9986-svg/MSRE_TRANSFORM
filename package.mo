within ;
package MSRE "Molten-Salt Reactor Experiment (MSRE) system model built on the TRANSFORM library"
  extends Modelica.Icons.Package;

  import SI = Modelica.Units.SI;
  import SIadd = TRANSFORM.Units;
  import Modelica.Constants.pi;

  annotation (
    uses(Modelica(version="4.1.0"), TRANSFORM(version="1.1")),
    version="0.2.2",
    Icon(coordinateSystem(preserveAspectRatio=false)),
    Documentation(info="<html>
<p>A one-dimensional, coupled neutronic / thermal-hydraulic model of the Molten-Salt
Reactor Experiment (MSRE), written for Dymola using the
<a href=\"modelica://TRANSFORM\">TRANSFORM</a> library.</p>

<p>The model is a Modelica re-implementation of the MARS input model documented in</p>
<blockquote>
J.J. Jeong, Y.J. Cho, H.C. Lee, B. Yun,
<i>Benchmarking the MARS code for molten salt reactor applications using MSRE transient
experiments</i>, Nuclear Engineering and Technology 58 (2026) 104438.
</blockquote>

<h4>What is reproduced</h4>
<ul>
<li>The <b>modified point-kinetics model</b>: the conventional precursor balance is replaced by a
delayed-neutron-precursor (DNP) <b>transport</b> equation solved over the whole primary system
(paper Eq. 3). In Modelica this is done by declaring the six DNP groups as
<i>trace substances</i> of the fuel-salt medium, so that the TRANSFORM fluid components
transport them automatically; the source/decay terms are supplied through the
<code>InternalTraceGen</code> closure model.</li>
<li>The effective core precursor number <code>C_i(t)</code> of paper Eq. 4, including the
importance and flux weighting.</li>
<li>The effective delayed-neutron fraction <code>Beta_eff</code> obtained from the steady state
(paper Eq. 6) after a null transient, and then held constant through the transient.</li>
<li>The reactivity model of paper Eq. 5 (fuel / graphite temperature feedback plus external
reactivity).</li>
<li>The ideal control-rod (flux servo) reactivity of paper Eq. 7, used for the zero-power
pump tests.</li>
<li>The analytic steady-state drift reactivity of paper Eq. 8, provided as
<a href=\"modelica://MSRE.Functions.driftReactivity\">MSRE.Functions.driftReactivity</a>
so that the simulated asymptotic reactivity loss can be checked against it
(the paper reports 226.5 pcm simulated vs 228.4 pcm analytic).</li>
</ul>

<h4>Package structure</h4>
<ul>
<li><a href=\"modelica://MSRE.Media\">Media</a> - MSRE fuel salt and coolant salt property models.</li>
<li><a href=\"modelica://MSRE.Data\">Data</a> - kinetics data (paper Tables 1-3) and the plant geometry record.</li>
<li><a href=\"modelica://MSRE.Nuclear\">Nuclear</a> - the modified point-kinetics model.</li>
<li><a href=\"modelica://MSRE.Components\">Components</a> - graphite-moderated fuel channel, fuel pump.</li>
<li><a href=\"modelica://MSRE.Systems\">Systems</a> - the complete primary + secondary boundary system model.</li>
<li><a href=\"modelica://MSRE.Experiments\">Experiments</a> - the three benchmark transients:
pump startup, pump coastdown and natural circulation.</li>
</ul>

<h4>Status of the input data</h4>
<p>Publicly reported MSRE data do not include a complete node-by-node volume breakdown.
The component volumes in <a href=\"modelica://MSRE.Data.Geometry\">MSRE.Data.Geometry</a>
were therefore chosen to reproduce the quantities that actually govern the benchmarked
physics, namely the reported fuel-salt transit times
(core 9.56 s, external loop 16.14 s, system 25.63 s at 168 kg/s) together with the
documented MSRE hardware dimensions where those are available (1140 fuel channels,
1.626 m active height, 16 in heat-exchanger shell, 163 tubes, 24.1 m2 heat-transfer area).
Every one of these values is an exposed parameter. Items that are explicit estimates
are marked in the record.</p>
</html>"));
end MSRE;
