within MSRE.Functions;
function corePowerShape
  "Fraction of the fission source generated in every reactor core cell (cosine axial profile times a radial profile)"
  extends Modelica.Icons.Function;

  input Integer nRings "# of radial rings";
  input Integer nAxial "# of axial nodes per channel";
  input Real nChannels[nRings] "# of fuel channels per ring";
  input Real f_radial[nRings] "Radial power peaking factor of each ring";
  input SI.Area A_channel "Flow area of a single fuel channel";
  input SI.Length H_channels "Active channel height";
  input SI.Length L_lowerPlenumNode
    "Axial length of the lower plenum node that belongs to the core";
  input SI.Length L_upperPlenumNode
    "Axial length of the upper plenum node that belongs to the core";
  input SI.Volume V_lowerPlenumNode "Volume of that lower plenum node";
  input SI.Volume V_upperPlenumNode "Volume of that upper plenum node";
  input Real f_extrapolation=1.2 "Axial extrapolation factor of the cosine profile";
  input Boolean plenumFissionSource=false
    "ASSUMPTION: =false puts no fission source in the two plenum core nodes. =true restores the volume-weighted treatment used before O-20, for sensitivity only";
  output Real SF[nRings*nAxial + 2] "Fission source fraction of each core cell, sum = 1";

protected
  Integer nCells=nRings*nAxial + 2;
  Integer idx;
  SI.Length L_core=L_lowerPlenumNode + H_channels + L_upperPlenumNode;
  SI.Length L_extrapolated=L_core*f_extrapolation;
  SI.Length z;
  Real P[nRings*nAxial + 2];
algorithm
  for r in 1:nRings loop
    for k in 1:nAxial loop
      idx := (r - 1)*nAxial + k;
      z := L_lowerPlenumNode + H_channels*(k - 0.5)/nAxial;
      P[idx] := f_radial[r]*Modelica.Math.cos(Modelica.Constants.pi*(z - 0.5*L_core)/
        L_extrapolated)*A_channel*H_channels/nAxial*nChannels[r];
    end for;
  end for;

  /* Fission source domain. The two plenum core nodes hold no graphite, so they are not an
     active fuel region; with plenumFissionSource = false they receive no fission source at all.
     They remain in the array, and in the delayed-neutron precursor inventory and transport
     domain, with SF = 0: precursors entering them are still carried and still decay. See the
     documentation for why this is an ASSUMPTION rather than a measurement. */
  z := 0.5*L_lowerPlenumNode;
  P[nRings*nAxial + 1] := if plenumFissionSource then Modelica.Math.cos(Modelica.Constants.pi
    *(z - 0.5*L_core)/L_extrapolated)*V_lowerPlenumNode else 0;

  z := L_lowerPlenumNode + H_channels + 0.5*L_upperPlenumNode;
  P[nRings*nAxial + 2] := if plenumFissionSource then Modelica.Math.cos(Modelica.Constants.pi
    *(z - 0.5*L_core)/L_extrapolated)*V_upperPlenumNode else 0;

  for m in 1:nCells loop
    SF[m] := P[m]/sum(P);
  end for;

  annotation (Documentation(info="<html>
<p>Builds the fission source distribution of paper Section 3.2: a cosine axial profile
(paper Fig. 3) over the whole core, which here spans the lower plenum core node, the fuel
channels and the upper plenum core node, multiplied by a radial profile over the rings.</p>

<p><code>f_extrapolation = 1.0</code> gives a cosine chopped exactly at the core boundary,
so the source vanishes at the two plenum nodes. The default 1.2 represents the usual
reflector saving and leaves a finite source there, which is the physically relevant case,
since the reason those plenum nodes are counted as core at all is that fission does occur in
them. Changing this factor reproduces the axial-profile sensitivity of paper Fig. 3.</p>

<p>The normalized flux needed by paper Eq. 4 follows from the returned shape as
<code>phi_i = SF_i*sum(V)/V_i</code>, which satisfies <code>sum(phi_i*V_i) = sum(V_i)</code>.</p>

<h4>Fission source domain (O-20 resolution)</h4>
<p><b>The delayed-neutron precursor domain and the fission source domain are not the same
set of cells.</b></p>
<table border=\"1\">
<tr><th>Domain</th><th>Cells</th><th>What happens there</th></tr>
<tr><td>fission source</td><td>the active fuel channel cells only</td>
    <td>the volumetric fission power and the precursor production term
        <code>S_i = beta_i/Lambda*N*SF</code></td></tr>
<tr><td>precursor inventory and transport</td>
    <td>channel cells <b>and</b> both plenum core nodes</td>
    <td>advection and decay, <code>dC_i/dt + div(u C_i) = -lambda_i C_i</code></td></tr>
</table>
<p>With the default <code>plenumFissionSource = false</code> the two plenum core nodes get
<code>SF = 0</code>, hence no fission power and no precursor production. They stay in the array
and in the precursor domain, so precursors born in the channels are still carried into them and
still decay there.</p>

<h4>Why, and what changed</h4>
<p>Every cell used to enter the sum weighted by its <b>volume</b> under a single cosine. That
was harmless while the plenum core nodes held 3.055 litres each. Once they became equal-volume
thirds of the referenced plenum totals they hold 0.1155 and 0.1070 m3, <b>65 times a channel
cell</b>, and volume weighting handed them a seventh of the fission source:</p>
<table border=\"1\">
<tr><th></th><th>nodes at 3.055 L</th><th>one third of a plenum, volume weighted</th>
    <th>active, no plenum source</th></tr>
<tr><td><code>SF</code> lower node</td><td>0.00201</td><td>0.07668</td><td><b>0</b></td></tr>
<tr><td><code>SF</code> upper node</td><td>0.00201</td><td>0.07104</td><td><b>0</b></td></tr>
<tr><td>both together</td><td>0.40 %</td><td><b>14.77 %</b></td><td><b>0 %</b></td></tr>
</table>
<p>The plena contain no graphite, so they are not moderated and their thermal flux should be
<i>lower</i> than in the channels, not comparable. Placing a seventh of the fission there was
an artefact of volume weighting, not a physical statement. The three figures above are kept as
an <b>error quantification only</b> - none of them is used as a correction factor, a scaling or
a fitted parameter anywhere.</p>

<h4>Status: ASSUMPTION, not a measurement</h4>
<pre>
PLENUM_FISSION_SOURCE = 0
ASSUMPTION
</pre>
<p>Fission in the MSRE plena is not exactly zero: the plena sit against the graphite stack and
see a thermal flux tail, which is precisely why Jeong counts Volumes 120-03 and 190-01 as part
of the reactor core at all. What is not available is any published statement of how much source
those two MARS volumes carry. Between two unsupported choices - a volume-weighted share that
gives them 14.8 %, and zero - zero is the less unphysical, and it is the one that keeps the
precursor-transport benchmark from being contaminated by an invented source distribution.
Setting <code>plenumFissionSource = true</code> restores the previous treatment for
sensitivity. Resolving it properly needs the MARS node source fractions or a transport
calculation, and is tracked with O-12B, the physical volume of the same two nodes.</p>

<p>The normalized flux needed by paper Eq. 4 follows from the returned shape as
<code>phi_i = SF_i*sum(V)/V_i</code>, which satisfies <code>sum(phi_i*V_i) = sum(V_i)</code>.
That identity is unaffected: <code>sum(SF) = 1</code> still holds, it is now summed over the
channel cells alone, so the normalisation the point-kinetics model divides by is unchanged and
the precursor inventory of the plena continues to enter it.</p>
</html>"));
end corePowerShape;
