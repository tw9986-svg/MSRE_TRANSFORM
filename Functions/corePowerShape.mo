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
</html>"));
end corePowerShape;
