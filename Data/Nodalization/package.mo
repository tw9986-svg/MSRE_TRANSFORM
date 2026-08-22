within MSRE.Data;
package Nodalization
  "Spatial nodalization of the reactor core, kept separate from the physical geometry"
  extends Modelica.Icons.Package;

  annotation (Documentation(info="<html>
<h4>Physical geometry is not spatial nodalization</h4>
<p><a href=\"modelica://MSRE.Data.Geometry\">Data.Geometry</a> is the single source of truth for
what the MSRE <i>is</i>: channel dimensions and count, core height, vessel and plenum
dimensions, piping, pump and heat-exchanger hardware. Nothing in it may be duplicated per
benchmark branch.</p>

<p>How that hardware is <i>discretized</i> is a modelling choice, and it is the one thing the
1-D and 2-D benchmarks are meant to differ in. It lives here:</p>
<table border=\"1\">
<tr><th>Record</th><th>Rings</th><th>Axial</th><th>Radial shape</th><th>Used by</th></tr>
<tr><td><a href=\"modelica://MSRE.Data.Nodalization.Core1D\">Core1D</a></td><td>1</td><td>20</td>
    <td>{1.0}, by construction</td><td>benchmark/1d-zero-power</td></tr>
<tr><td><a href=\"modelica://MSRE.Data.Nodalization.Core2D\">Core2D</a></td><td>15</td><td>20</td>
    <td>15-ring profile</td><td>benchmark/2d-zero-power</td></tr>
</table>

<p>Both records draw every physical quantity they need from <code>Data.Geometry</code>; neither
restates one. A 1-D and a 2-D run must therefore differ in spatial representation and in
nothing else - which is the whole point of the comparison.</p>

<h4>Migration status</h4>
<p><code>Data.Geometry</code> still carries its own <code>nRings</code>, <code>nAxial</code>,
<code>nChannels</code>, <code>f_radial</code>, <code>f_axialExtrapolation</code> and the
per-ring form-loss arrays, because <code>Systems.PrimarySystem</code> and
<code>Components.ReactorCore</code> read them from there. Those fields are the 2-D default and
are tagged NODALIZATION in the record. Removing them, and having the system model take a
nodalization record instead, is the next structural step and is tracked as open item O-21; it
is deliberately not done in the same commit as the closure and source-domain fixes.</p>
</html>"));
end Nodalization;
