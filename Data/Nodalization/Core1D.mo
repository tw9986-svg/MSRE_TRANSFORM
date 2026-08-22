within MSRE.Data.Nodalization;
record Core1D
  "1-D core nodalization: one equivalent radial group, 20 axial cells"
  extends Modelica.Icons.Record;

  parameter MSRE.Data.Geometry geometry "Physical geometry, the single source of truth";

  parameter Integer nRings=1
    "NODALIZATION | # of radial groups. One equivalent group collapses the 1140 hydraulically identical channels";
  parameter Integer nAxial=20
    "NODALIZATION | # of axial cells per group, matching the axial discretization of the Jeong MARS core";

  final parameter Real nChannels[nRings]={geometry.nChannels_total}
    "DERIVED | all 1140 physical channels in the single group";
  final parameter Real f_radial[nRings]={1.0}
    "DERIVED | radial peaking factor is unity by construction: with one group there is no radial resolution to carry a profile";

  parameter Real f_axialExtrapolation=geometry.f_axialExtrapolation
    "NODALIZATION | axial extrapolation factor of the cosine source profile; taken from the common record so that 1-D and 2-D share it";
  parameter Real K_channelInlet[nRings]=zeros(nRings)
    "NODALIZATION | form loss where the group leaves the lower plenum, per channel";
  parameter Real K_channelExit[nRings]=zeros(nRings)
    "NODALIZATION | form loss where the group enters the upper plenum, per channel";

  final parameter Integer nV_core=nRings*nAxial + 2
    "DERIVED | core cells seen by the kinetics: channel cells plus the two plenum core nodes";

  annotation (defaultComponentName="nodalization", Documentation(info="<html>
<p>One equivalent radial group of 1140 channels, 20 axial cells, plus the two plenum
core nodes: <code>nV_core = 22</code>.</p>

<p>The collapse is <b>hydraulic</b>, not physical. Every channel keeps its own documented
cross-section and hydraulic diameter; what is dropped is the ability to resolve a radial
profile. <code>f_radial = {1.0}</code> is therefore not an assumption about the MSRE, it is a
statement that a single group cannot carry radial detail - the flat profile is exact for the
representation, and the difference against a 15-ring run is exactly the spatial-representation
effect the 1-D/2-D comparison exists to measure.</p>

<p>Nothing physical is redefined here. <code>nChannels_total</code>,
<code>f_axialExtrapolation</code> and everything else come from
<a href=\"modelica://MSRE.Data.Geometry\">Data.Geometry</a>.</p>
</html>"));
end Core1D;
