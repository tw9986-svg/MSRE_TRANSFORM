within MSRE.Functions;
function coreCellVolumes "Fuel salt volume of every reactor core cell, in the core cell ordering"
  extends Modelica.Icons.Function;

  input Integer nRings "# of radial rings";
  input Integer nAxial "# of axial nodes per channel";
  input Real nChannels[nRings] "# of fuel channels per ring";
  input SI.Area A_channel "Flow area of a single fuel channel";
  input SI.Length H_channels "Active channel height";
  input SI.Volume V_lowerPlenumNode "Volume of the lower plenum node that belongs to the core";
  input SI.Volume V_upperPlenumNode "Volume of the upper plenum node that belongs to the core";
  output SI.Volume Vs[nRings*nAxial + 2] "Volume of each core cell";

protected
  Integer idx;
algorithm
  for r in 1:nRings loop
    for k in 1:nAxial loop
      idx := (r - 1)*nAxial + k;
      Vs[idx] := A_channel*H_channels/nAxial*nChannels[r];
    end for;
  end for;
  Vs[nRings*nAxial + 1] := V_lowerPlenumNode;
  Vs[nRings*nAxial + 2] := V_upperPlenumNode;

  annotation (Documentation(info="<html>
<p>Returns the same volumes that
<a href=\"modelica://MSRE.Components.ReactorCore\">ReactorCore</a> exports as
<code>Vs_core</code>, but as a parameter expression, so that the power and flux shapes can be
declared as parameters.</p>
</html>"));
end coreCellVolumes;
