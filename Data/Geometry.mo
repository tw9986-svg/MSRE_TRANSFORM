within MSRE.Data;
record Geometry "MSRE nodalization and geometry (Modelica counterpart of the MARS input of paper Fig. 2)"
  extends Modelica.Icons.Record;

  /* ------------------------------------------------------------------
     Nodalization
     ------------------------------------------------------------------ */
  parameter Integer nRings=15 "# of concentric radial rings the 1140 fuel channels are grouped into";
  parameter Integer nAxial=20 "# of axial nodes per fuel channel";
  parameter Integer nLP=3 "# of axial nodes in the lower plenum";
  parameter Integer nUP=3 "# of axial nodes in the upper plenum";
  parameter Integer nDC=10 "# of nodes in the downcomer";
  parameter Integer nHX=10 "# of nodes on each side of the heat exchanger";
  parameter Integer nOutletPipe=4 "# of nodes in the reactor outlet pipe";
  parameter Integer nPumpBowl=2 "# of nodes in the fuel pump bowl / volute";
  parameter Integer nPumpToHX=4 "# of nodes in the pump discharge pipe";
  parameter Integer nHXToVessel=6 "# of nodes in the heat exchanger outlet pipe";

  /* Core boundary: following the paper, the last lower-plenum node and the first
     upper-plenum node are counted as part of the reactor core. */
  final parameter Integer iLP_core=nLP "Lower plenum node that belongs to the reactor core";
  final parameter Integer iUP_core=1 "Upper plenum node that belongs to the reactor core";
  final parameter Integer nV_core=nRings*nAxial + 2 "Total # of core cells seen by the kinetics";

  /* ------------------------------------------------------------------
     Reference operating point
     ------------------------------------------------------------------ */
  parameter SI.MassFlowRate m_flow_nominal=168 "Rated fuel salt mass flow rate";
  parameter SI.MassFlowRate m_flow_coolant_nominal=103.1
    "Rated coolant salt mass flow rate (850 gpm)";
  parameter SI.Temperature T_zeroPower=908
    "Fuel salt temperature of the zero-power pump tests";
  parameter SI.AbsolutePressure p_system=1.5e5 "System pressure set by the expansion tank";

  /* ------------------------------------------------------------------
     Fuel channels (graphite-moderated core region)
     ------------------------------------------------------------------ */
  parameter Real nChannels_total=1140 "Total # of vertical fuel channels";
  parameter Real nChannels[nRings]=fill(nChannels_total/nRings, nRings)
    "# of channels per radial ring (equal-area rings)";
  parameter SI.Length H_channels=1.626 "Active height of the fuel channels (64 in)";
  parameter SI.Area A_channel=3.9198e-4 "Flow area of a single fuel channel";
  parameter SI.Length Dh_channel=0.01778 "Hydraulic diameter of a single fuel channel (0.7 in)";
  final parameter SI.Volume V_channels=nChannels_total*A_channel*H_channels
    "Total fuel salt volume inside the graphite channels";

  final parameter SI.Length perimeter_channel=4*A_channel/Dh_channel
    "Wetted perimeter of a single fuel channel";

  /* Graphite: each channel is represented by an equivalent annulus of graphite. Its inner
     radius reproduces the wetted perimeter of the real (grooved) channel and its outer radius
     reproduces the per-channel share of the graphite stack, so that both the convective area
     and the graphite heat capacity are preserved. */
  parameter SI.Area A_graphite_perChannel=7.018e-4
    "Graphite cross-section per fuel channel (1.26 m graphite stack diameter / 1140 channels)";
  final parameter SI.Length r_graphite_inner=perimeter_channel/(2*pi)
    "Inner radius of the equivalent graphite annulus";
  final parameter SI.Length r_graphite_outer=sqrt(A_graphite_perChannel/pi + r_graphite_inner^2)
    "Outer radius of the equivalent graphite annulus";
  final parameter SI.Volume V_graphite=A_graphite_perChannel*H_channels*nChannels_total
    "Total graphite volume in the active core";
  parameter Integer nR_graphite=3 "# of radial nodes in the graphite";

  /* Radial power/flux profile. In the paper this is taken from a Serpent calculation
     (Ref. [9]); that tabulation is not public, so a J0 shape with a 25% reflector saving is
     used here (radial peak-to-average 1.61). Replace with the Serpent values if available. */
  parameter Real f_radial[nRings]={1.6067,1.5076,1.4115,1.3184,1.2283,1.1410,1.0565,0.9748,
      0.8958,0.8194,0.7456,0.6743,0.6055,0.5392,0.4751}
    "Radial power peaking factor of each ring (channel-weighted average = 1)";

  /* Axial power/flux profile: cosine, as in paper Fig. 3. */
  parameter Real f_axialExtrapolation=1.2
    "Axial extrapolation factor of the cosine profile (1 = chopped at the core boundary)";

  /* ------------------------------------------------------------------
     Reactor vessel plena and downcomer
     ------------------------------------------------------------------ */
  parameter SI.Volume V_lowerPlenum=0.0777 "Fuel salt volume of the lower plenum";
  parameter SI.Length L_lowerPlenum=0.30 "Height of the lower plenum";
  parameter SI.Volume V_upperPlenum=0.0777 "Fuel salt volume of the upper plenum";
  parameter SI.Length L_upperPlenum=0.30 "Height of the upper plenum";
  parameter SI.Volume V_downcomer=0.586872
    "Fuel salt volume of the flow distributor + downcomer annulus";
  parameter SI.Length L_downcomer=2.40 "Height of the downcomer";
  parameter SI.Length Dh_downcomer=0.1163 "Hydraulic diameter of the downcomer annulus";

  /* ------------------------------------------------------------------
     External loop piping and pump
     ------------------------------------------------------------------ */
  parameter SI.Length D_pipe=0.1286 "Inner diameter of the 5 in sch 40 loop piping";
  parameter SI.Length L_outletPipe=4.00 "Reactor outlet pipe length (vessel to pump)";
  parameter SI.Length L_pumpToHX=5.00 "Pump discharge pipe length (pump to heat exchanger)";
  parameter SI.Length L_hxToVessel=7.00 "Heat exchanger outlet pipe length (to the vessel inlet)";
  parameter SI.Volume V_pumpBowl=0.150 "Fuel salt volume of the pump bowl and volute";
  parameter SI.Length L_pumpBowl=0.60 "Effective flow length of the pump bowl";

  parameter SI.PressureDifference dp_pump_nominal=3.0e5
    "Fuel pump pressure rise at rated speed and rated flow (48.5 ft of salt)";
  parameter Real N_pump_nominal(unit="1/min") = 1160 "Rated fuel pump speed";
  parameter Real headRatio_shutoff=1.25
    "Ratio of shut-off head to rated head of the fuel pump";

  parameter Real K_pumpInlet=1.75 "Form loss coefficient at the fuel pump inlet";
  parameter Real K_pumpExit=1.75 "Form loss coefficient at the fuel pump exit";
  parameter Real K_loop=1.90 "Lumped form loss coefficient of the remaining loop hardware";

  /* ------------------------------------------------------------------
     Heat exchanger (fuel salt on the shell side, coolant salt in the tubes)
     ------------------------------------------------------------------ */
  parameter Real nTubes=163 "# of heat exchanger tubes";
  parameter SI.Length L_tube=3.70 "Heated tube length (gives 24.1 m2 of heat transfer area)";
  parameter SI.Length D_tube_inner=0.010566 "Tube inner diameter (0.5 in OD, 0.042 in wall)";
  parameter SI.Length th_tube=0.001067 "Tube wall thickness";
  parameter SI.Length L_shell=2.44 "Shell length (8 ft)";
  parameter SI.Volume V_hxShell=0.266 "Fuel salt volume on the shell side";
  final parameter SI.Area A_shell=V_hxShell/L_shell "Shell side flow area";
  parameter SI.Length Dh_shell=0.05606 "Shell side hydraulic diameter";
  final parameter SI.Length D_tube_outer=D_tube_inner + 2*th_tube "Tube outer diameter";
  parameter Real f_shellHT=3.0
    "Multiplier on the shell-side turbulent Nusselt number (baffle induced cross-flow enhancement); calibrates the full-power duty";
  parameter Real Nu_floor_shell=10.0
    "Shell-side low-flow Nusselt number referred to the tube outer diameter; calibrates the natural circulation duty";
  parameter Real f_area_hx=1.0
    "Multiplier on the heat transfer area (sensitivity case C1 of the paper uses 1.10)";

  /* ------------------------------------------------------------------
     Elevations (closed loop: the sum of all dheights is zero)
     ------------------------------------------------------------------ */
  parameter SI.Length dz_lowerPlenum=0.30 "Elevation rise across the lower plenum";
  parameter SI.Length dz_channels=1.626 "Elevation rise across the fuel channels";
  parameter SI.Length dz_upperPlenum=0.30 "Elevation rise across the upper plenum";
  parameter SI.Length dz_outletPipe=2.20 "Elevation rise of the reactor outlet riser";
  parameter SI.Length dz_pumpBowl=0.00 "Elevation rise across the pump bowl";
  parameter SI.Length dz_pumpToHX=-0.50 "Elevation change of the pump discharge pipe";
  parameter SI.Length dz_hxShell=-1.50 "Elevation change across the heat exchanger shell";
  parameter SI.Length dz_hxToVessel=-0.20 "Elevation change of the heat exchanger outlet pipe";
  final parameter SI.Length dz_downcomer=-(dz_lowerPlenum + dz_channels + dz_upperPlenum +
      dz_outletPipe + dz_pumpBowl + dz_pumpToHX + dz_hxShell + dz_hxToVessel)
    "Elevation change of the downcomer, set so that the loop closes";

  /* ------------------------------------------------------------------
     Derived inventories and transit times (reported quantities)
     ------------------------------------------------------------------ */
  final parameter SI.Volume V_core=V_channels + V_lowerPlenum/nLP + V_upperPlenum/nUP
    "Fuel salt volume of the reactor core as defined in the paper";
  final parameter SI.Volume V_loop=V_lowerPlenum*(nLP - 1)/nLP + V_upperPlenum*(nUP - 1)/nUP
       + pi/4*D_pipe^2*(L_outletPipe + L_pumpToHX + L_hxToVessel) + V_pumpBowl + V_hxShell
       + V_downcomer "Fuel salt volume of the external loop";
  final parameter SI.Volume V_total=V_core + V_loop "Circulating fuel salt volume";

  annotation (defaultComponentName="geometry", Documentation(info="<html>
<h4>Where the numbers come from</h4>
<p>Documented MSRE hardware dimensions are used wherever they are available:
1140 fuel channels, 1.626 m active height, 5 in sch 40 loop piping, a 16 in heat-exchanger
shell with 163 tubes of 0.5 in OD giving 24.1 m2 of heat transfer area, a rated fuel flow of
168 kg/s and a rated coolant flow of about 850 gpm.</p>

<p>The node-by-node fuel-salt volume breakdown of the MARS input is not published. The
volumes here are therefore <b>calibrated to reproduce the transit times reported in the
paper</b>, which are what actually govern the delayed-neutron drift physics (paper Eq. 8
depends on nothing else):</p>
<table border=\"1\">
<tr><th></th><th>this model</th><th>paper (MARS)</th></tr>
<tr><td>core volume</td><td>0.7784 m3</td><td>-</td></tr>
<tr><td>core transit time at 168 kg/s</td><td>9.56 s</td><td>9.56 s</td></tr>
<tr><td>loop transit time at 168 kg/s</td><td>16.14 s</td><td>16.14 s</td></tr>
<tr><td>system transit time</td><td>25.70 s</td><td>25.63 s (measured 25.2 s)</td></tr>
</table>
<p>(Transit times are evaluated with the fuel salt density at 908 K, 2063 kg/m3.)</p>

<p>The individual volumes that carry the largest uncertainty are
<code>V_downcomer</code> (which absorbs the balance of the loop inventory) and
<code>V_pumpBowl</code>. Form losses and the heat exchanger area were, as in the paper,
adjusted to give a sensible full-power steady state; both are exposed here so that the
paper's sensitivity cases can be run directly:</p>
<ul>
<li>case C1: <code>f_area_hx = 1.10</code></li>
<li>case C2: <code>K_pumpInlet = K_pumpExit = 0.5</code></li>
</ul>
</html>"));
end Geometry;
