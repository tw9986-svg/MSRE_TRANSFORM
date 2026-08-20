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

  z := 0.5*L_lowerPlenumNode;
  P[nRings*nAxial + 1] := Modelica.Math.cos(Modelica.Constants.pi*(z - 0.5*L_core)/
    L_extrapolated)*V_lowerPlenumNode;

  z := L_lowerPlenumNode + H_channels + 0.5*L_upperPlenumNode;
  P[nRings*nAxial + 2] := Modelica.Math.cos(Modelica.Constants.pi*(z - 0.5*L_core)/
    L_extrapolated)*V_upperPlenumNode;

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

<h4>Open item O-20: the plenum nodes now carry a large share of the source</h4>
<p>The two plenum core nodes enter the sum weighted by their <b>volume</b>, with the same
cosine amplitude as the channel region. That was harmless while they held 3.055 litres each.
Since they became equal-volume thirds of the referenced plenum totals they hold 0.1155 and
0.1070 m3, 65 times a channel cell, and the shape they receive changes accordingly:</p>
<table border=\"1\">
<tr><th></th><th>plenum nodes at 3.055 litres</th><th>plenum nodes at one third of a plenum</th></tr>
<tr><td><code>SF</code> of the lower node</td><td>0.00201</td><td><b>0.07668</b></td></tr>
<tr><td><code>SF</code> of the upper node</td><td>0.00201</td><td><b>0.07104</b></td></tr>
<tr><td>both together</td><td>0.40 % of core fission</td><td><b>14.77 %</b></td></tr>
<tr><td>channel axial peak/average</td><td>1.348</td><td>1.265</td></tr>
</table>
<p>Nearly a seventh of the fission source is now placed in salt that has <b>no graphite around
it</b>, which is difficult to defend: the plena are unmoderated, so the thermal flux there
should be lower than in the channels rather than comparable, and the paper describes the two
nodes as thin slices at the core boundary. This function was not changed - it still applies
one cosine over the whole core height and weights by volume - because correcting it means
choosing a physical treatment (excluding the plena from the moderated shape, weighting them by
a moderator-presence factor, or taking the shape from a transport calculation), and that is a
modelling decision rather than a cleanup. It is recorded as O-20 together with O-12B, the
unresolved physical volume of the two nodes, which is the same question seen from the other
side.</p>
</html>"));
end corePowerShape;
