within MSRE.Data.Nodalization;
record Core2D
  "2-D R-Z core nodalization: 15 radial rings, 20 axial cells"
  extends Modelica.Icons.Record;

  parameter MSRE.Data.Geometry geometry "Physical geometry, the single source of truth";

  parameter Integer nRings=15
    "NODALIZATION | # of concentric radial rings the 1140 fuel channels are grouped into";
  parameter Integer nAxial=20
    "NODALIZATION | # of axial cells per ring, as in the Jeong MARS core";

  final parameter Real nChannels[nRings]=fill(geometry.nChannels_total/nRings, nRings)
    "DERIVED | equal-area rings, so the channels divide evenly";
  parameter Real f_radial[nRings]={1.6067,1.5076,1.4115,1.3184,1.2283,1.1410,1.0565,0.9748,
      0.8958,0.8194,0.7456,0.6743,0.6055,0.5392,0.4751}
    "ASSUMPTION | radial peaking factor of each ring, channel-weighted average 1. A J0 shape with a 25 % reflector saving, NOT the paper's Serpent tabulation, which is not public";

  parameter Real f_axialExtrapolation=geometry.f_axialExtrapolation
    "NODALIZATION | axial extrapolation factor of the cosine source profile; taken from the common record so that 1-D and 2-D share it";
  parameter Real K_channelInlet[nRings]=zeros(nRings)
    "NODALIZATION | form loss where each ring leaves the lower plenum, per channel";
  parameter Real K_channelExit[nRings]=zeros(nRings)
    "NODALIZATION | form loss where each ring enters the upper plenum, per channel";

  final parameter Integer nV_core=nRings*nAxial + 2
    "DERIVED | core cells seen by the kinetics: channel cells plus the two plenum core nodes";

  annotation (defaultComponentName="nodalization", Documentation(info="<html>
<p>15 radial rings of 76 channels, 20 axial cells each, plus the two plenum core nodes:
<code>nV_core = 302</code>. This is the nodalization of the Jeong MARS core.</p>

<h4>The radial profile is an ASSUMPTION, not a measurement</h4>
<p>Jeong et al. take the radial power profile from a Serpent calculation (their Ref. [9]) and
that tabulation is not published. The 15 values here are a J0 shape with a 25 % reflector
saving, giving a radial peak-to-average of 1.61, and they are carried over from
<code>Data.Geometry</code> unchanged. <b>They must not be presented as the paper's radial
distribution or as an MSRE measurement.</b> Replace them if the Serpent tabulation becomes
available.</p>

<h4>Radial discretization is not yet a radial flow model</h4>
<p>With <code>K_channelInlet = K_channelExit = 0</code> and every ring geometrically identical,
the rings differ only through their power. The hydraulic flow split will therefore come out
close to uniform, which is a property of this input set rather than of the MSRE - the measured
MSRE channel flow distribution would need the Kedl (ORNL-TM-3229) form losses, which have not
been extracted. Having 15 rings is not by itself a physical radial flow model, and the
hydraulic audit of the 2-D benchmark has to establish which of the two it is.</p>
</html>"));
end Core2D;
