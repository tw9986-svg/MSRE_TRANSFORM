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
  parameter SI.Density d_fuel_ref=2249.3
    "Fuel salt density at T_zeroPower, from ORNL-TM-4865. Only used for the derived quantities reported by this record; the system model evaluates the density from the medium itself";

  /* ------------------------------------------------------------------
     Fuel channels (graphite-moderated core region)
     ------------------------------------------------------------------ */
  /* Primary hardware dimensions. Everything below them is a consequence: no flow area, no
     hydraulic diameter and no volume in this block is entered by hand or fitted to a reported
     transit time or inventory. See the record documentation for the provenance and for the
     Mao geometry this replaced. */
  parameter Real nChannels_total=1140 "Total # of vertical fuel channels";
  parameter Real nChannels[nRings]=fill(nChannels_total/nRings, nRings)
    "# of channels per radial ring (equal-area rings)";
  parameter SI.Length H_channels=1.6256
    "Active height of the fuel channels (64 in, ORNL/INL MSRE hardware)";
  parameter SI.Length w_channel=0.03048
    "Width of a single fuel channel (1.2 in, ORNL/INL MSRE hardware)";
  parameter SI.Length h_channel=0.01016
    "Depth of a single fuel channel (0.4 in, ORNL/INL MSRE hardware)";
  parameter SI.Length r_channelCorner=0.00508
    "Rounded corner radius of a single fuel channel (0.2 in, ORNL/INL MSRE hardware)";

  /* A fuel channel is a 1.2 x 0.4 in rectangle with all four corners rounded at 0.2 in. Each
     rounded corner removes (1 - pi/4)*r^2 of area and replaces 2r of straight wall with a
     quarter arc of length pi*r/2. */
  final parameter SI.Area A_channel=w_channel*h_channel - (4 - pi)*r_channelCorner^2
    "Flow area of a single fuel channel (2.87524e-4 m2)";
  final parameter SI.Length perimeter_channel=2*(w_channel + h_channel) - 4*(2 - pi/2)*
      r_channelCorner "Wetted perimeter of a single fuel channel (0.072559 m)";
  final parameter SI.Length Dh_channel=4*A_channel/perimeter_channel
    "Hydraulic diameter of a single fuel channel (0.015851 m)";
  final parameter SI.Area A_core_total=nChannels_total*A_channel
    "Total core flow area (0.327778 m2)";
  final parameter SI.Volume V_channels=A_core_total*H_channels
    "Total fuel salt volume inside the graphite channels (0.532836 m3)";

  /* Graphite: each channel is represented by an equivalent annulus of graphite. Its inner
     radius reproduces the wetted perimeter of the real (grooved) channel and its outer radius
     reproduces the per-channel share of the graphite stack, so that both the convective area
     and the graphite heat capacity are preserved. */
  parameter SI.Length D_graphiteStack=1.40335
    "Diameter of the graphite stack, taken as the core container inner diameter (55.25 in, ORNL/INL MSRE hardware)";
  final parameter SI.Area A_graphite_perChannel=(pi/4*D_graphiteStack^2 - A_core_total)/
      nChannels_total
    "Graphite cross-section per fuel channel: the stack area not taken by the channels, shared out";
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

  /* Per-ring form losses at the two plenum junctions. These are the only parameters in the
     whole record that can make one ring carry a different flow from another; everything else
     about the 1140 channels is identical by construction. They are left at zero because the
     coefficients that would reproduce the measured MSRE channel flow distribution have not
     been extracted from Kedl (ORNL-TM-3229) yet. See MSRE.Components.ReactorCore. */
  parameter Real K_channelInlet[nRings]=zeros(nRings)
    "Form loss coefficient where each ring leaves the lower plenum, per channel";
  parameter Real K_channelExit[nRings]=zeros(nRings)
    "Form loss coefficient where each ring enters the upper plenum, per channel";

  /* ------------------------------------------------------------------
     Reactor vessel plena and downcomer
     ------------------------------------------------------------------ */
  parameter SI.Volume V_lowerPlenum=0.0777 "Fuel salt volume of the lower plenum";
  parameter SI.Length L_lowerPlenum=0.30 "Height of the lower plenum";
  parameter SI.Volume V_upperPlenum=0.0777 "Fuel salt volume of the upper plenum";
  parameter SI.Length L_upperPlenum=0.30 "Height of the upper plenum";

  /* The plenum node the kinetics counts as part of the reactor core (120-03 and 190-01 of the
     MARS input) is a thin slice at the core boundary, not a third of the plenum. Its volume is
     what is left of the core inventory once the channel volume is taken out, and that is only
     0.86 % of the core: 1606 kg at 2249 kg/m3 is 0.71403 m3 against 0.70792 m3 of channels. */
  parameter SI.Volume V_lowerPlenum_core=0.003055
    "Fuel salt volume of the lower plenum node that belongs to the reactor core";
  parameter SI.Volume V_upperPlenum_core=0.003055
    "Fuel salt volume of the upper plenum node that belongs to the reactor core";

  /* The plena are given a uniform bore and non-uniform node lengths, so the core node's length
     is its share of the volume. See the open item in the documentation: the paper's own
     sensitivity study implies a longer node than this, and the two have not been reconciled. */
  final parameter SI.Length L_lowerPlenum_core=V_lowerPlenum_core*L_lowerPlenum/V_lowerPlenum
    "Axial length of the lower plenum node that belongs to the reactor core";
  final parameter SI.Length L_upperPlenum_core=V_upperPlenum_core*L_upperPlenum/V_upperPlenum
    "Axial length of the upper plenum node that belongs to the reactor core";

  parameter SI.Volume V_downcomer=0.432371
    "Fuel salt volume of the flow distributor + downcomer annulus; the item that absorbs the balance of the loop inventory";
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
  parameter SI.Efficiency eta_pump=0.8 "Fuel pump isentropic efficiency";

  /* Fuel pump rotor. Used by MSRE.Components.FuelPump_Dynamics, which integrates
     J*der(omega) = tau_motor - tau_hyd - tau_fric. The rated hydraulic torque follows from the
     rated duty and is not free. The one fitted number is tau_pump_shaft, from which J_pump
     follows; the two are the same degree of freedom, and it is the counterpart of the moment
     of inertia the paper tunes. */
  final parameter SI.VolumeFlowRate V_flow_pump_nominal=m_flow_nominal/d_fuel_ref
    "Rated fuel pump volumetric flow rate";
  final parameter SI.AngularVelocity omega_pump_nominal=2*pi*N_pump_nominal/60
    "Rated fuel pump angular velocity";
  final parameter SI.Power P_pump_hydraulic=dp_pump_nominal*V_flow_pump_nominal
    "Rated fuel pump hydraulic power (24.4 kW, 32.8 hp)";
  final parameter SI.Torque tau_pump_hyd_nominal=P_pump_hydraulic/(omega_pump_nominal*
      eta_pump) "Rated fuel pump hydraulic torque (251 N.m)";
  parameter SI.Time tau_pump_shaft=4.0
    "Fuel pump shaft time constant; sets the startup and the coastdown transient together";
  final parameter SI.MomentOfInertia J_pump=tau_pump_shaft*tau_pump_hyd_nominal/
      omega_pump_nominal "Fuel pump rotor moment of inertia (8.28 kg.m2)";

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
  final parameter SI.Volume V_core=V_channels + V_lowerPlenum_core + V_upperPlenum_core
    "Fuel salt volume of the reactor core as defined in the paper";
  final parameter SI.Volume V_loop=(V_lowerPlenum - V_lowerPlenum_core) + (V_upperPlenum -
      V_upperPlenum_core) + pi/4*D_pipe^2*(L_outletPipe + L_pumpToHX + L_hxToVessel) +
      V_pumpBowl + V_hxShell + V_downcomer "Fuel salt volume of the external loop";
  final parameter SI.Volume V_total=V_core + V_loop "Circulating fuel salt volume";

  final parameter SI.Time tau_core_nominal=V_core*d_fuel_ref/m_flow_nominal
    "Core transit time at rated flow (paper: 9.56 s)";
  final parameter SI.Time tau_loop_nominal=V_loop*d_fuel_ref/m_flow_nominal
    "External loop transit time at rated flow (paper: 16.14 s)";
  final parameter SI.Time tau_system_nominal=tau_core_nominal + tau_loop_nominal
    "System transit time at rated flow (paper: 25.63 s, measured 25.2 s)";

  /* The circulating inventory the reported transit times actually pin down. tau*m_flow is a
     mass and does not involve the density at all, so these are the density independent content
     of the benchmark, and any set of volumes is only their consequence once a density
     correlation has been chosen. Reported alongside what this record's own volumes hold, so
     that the gap left open by Phase 2 is a computed number rather than a remark. */
  parameter SI.Time tau_core_paper=9.56 "Core transit time reported by the paper";
  parameter SI.Time tau_loop_paper=16.14 "External loop transit time reported by the paper";

  final parameter SI.Mass m_fuel_core_paper=tau_core_paper*m_flow_nominal
    "Fuel salt mass in the reactor core, from the reported transit time (1606 kg)";
  final parameter SI.Mass m_fuel_loop_paper=tau_loop_paper*m_flow_nominal
    "Fuel salt mass in the external loop, from the reported transit time (2712 kg)";
  final parameter SI.Mass m_fuel_total_paper=m_fuel_core_paper + m_fuel_loop_paper
    "Circulating fuel salt mass implied by the paper (4306 kg)";

  final parameter SI.Mass m_fuel_core_model=V_core*d_fuel_ref
    "Fuel salt mass this record's core volume holds at d_fuel_ref";
  final parameter SI.Mass m_fuel_loop_model=V_loop*d_fuel_ref
    "Fuel salt mass this record's loop volume holds at d_fuel_ref";
  final parameter SIadd.NonDim err_m_core=m_fuel_core_model/m_fuel_core_paper - 1
    "Relative core inventory error against the paper; zero until Phase 2 changed the density";
  final parameter SIadd.NonDim err_m_loop=m_fuel_loop_model/m_fuel_loop_paper - 1
    "Relative loop inventory error against the paper";

  /* ------------------------------------------------------------------
     Legacy core geometry: Mao et al. reference geometry - not active

     The values this record used before the core geometry was taken from the ORNL/INL hardware
     dimensions. Nothing references them; they are kept so that the provenance change is a
     computable comparison rather than a remark in a commit message. Do not use them for
     results.
     ------------------------------------------------------------------ */
  final parameter SI.Length H_channels_Mao=1.6406
    "Mao et al. reference geometry - not active: active channel height (Energies 2026, Table 2)";
  final parameter SI.Area A_core_total_Mao=0.4315
    "Mao et al. reference geometry - not active: total core flow area (Energies 2026, Table 2)";
  final parameter SI.Area A_channel_Mao=A_core_total_Mao/nChannels_total
    "Mao et al. reference geometry - not active: flow area of a single fuel channel (3.785088e-4 m2)";
  final parameter SI.Length Dh_channel_Mao=0.01778
    "Mao et al. reference geometry - not active: channel hydraulic diameter, entered by hand as 0.7 in";
  final parameter SI.Length D_graphiteStack_Mao=1.26
    "Mao et al. reference geometry - not active: graphite stack diameter";
  final parameter SI.Volume V_channels_Mao=A_core_total_Mao*H_channels_Mao
    "Mao et al. reference geometry - not active: channel volume (0.707919 m3)";
  final parameter SIadd.NonDim err_V_channels_Mao=V_channels/V_channels_Mao - 1
    "Change in channel volume caused by moving from the Mao geometry to the hardware geometry (-24.73 %)";

  final parameter SI.Length dz_closure=dz_lowerPlenum + dz_channels + dz_upperPlenum +
      dz_outletPipe + dz_pumpBowl + dz_pumpToHX + dz_hxShell + dz_hxToVessel + dz_downcomer
    "Sum of all elevation rises around the loop, which must be zero";

  annotation (defaultComponentName="geometry", Documentation(info="<html>
<h4>Where the numbers come from</h4>
<p>Documented MSRE hardware dimensions are used wherever they are available:
1140 fuel channels of 1.2 x 0.4 in with 0.2 in rounded corners, 1.6256 m active height,
5 in sch 40 loop piping, a 16 in heat-exchanger
shell with 163 tubes of 0.5 in OD giving 24.1 m2 of heat transfer area, a rated fuel flow of
168 kg/s and a rated coolant flow of about 850 gpm.</p>

<p>The node-by-node fuel-salt volume breakdown of the MARS input is not published, so the
volumes here are built from documented hardware wherever that exists and from the reported
inventory where it does not. The distinction matters when reading the agreement below.</p>
<table border=\"1\">
<tr><th></th><th>this model</th><th>paper (MARS)</th><th>fitted?</th></tr>
<tr><td>core volume</td><td>0.53895 m3</td><td>-</td><td>no</td></tr>
<tr><td>core transit time at 168 kg/s</td><td>7.22 s</td><td>9.56 s</td><td>no</td></tr>
<tr><td>loop transit time at 168 kg/s</td><td>16.14 s</td><td>16.14 s</td><td>yes</td></tr>
<tr><td>system transit time</td><td>23.36 s</td><td>25.63 s (measured 25.2 s)</td><td>-</td></tr>
</table>

<h4>The core transit time is a prediction, and it now disagrees with the paper</h4>
<p>The core volume is the ORNL/INL hardware channel geometry (1140 channels of
1.2 x 0.4 in with 0.2 in rounded corners, 1.6256 m tall) plus two small plenum nodes, and the
density is the ORNL-TM-4865 correlation at 908 K. Nothing in it was adjusted to hit a reported
number, and it does not hit one: <code>tau_core_nominal</code> comes out at 7.22 s against the
9.56 s the paper reports, which is <b>-24.5 %</b>.</p>

<p>This gap is the deliverable of the geometry change, not a defect in it. The core geometry
previously came from the flow area of Mao et al. (0.4315 m2), which is 32 % larger than the
1140 channels of documented cross-section actually add up to (0.32778 m2), and it was that
larger area which made <code>tau_core_nominal</code> land on 9.56 s. The two cannot both be
right. Re-deriving the volumes from the density to close the gap was considered and rejected:
it would make the geometry a function of the property correlation and would destroy the
diagnostic value of <code>err_m_core</code>. See the legacy block above for the Mao values,
which are retained for comparison.</p>

<p><b>Open: what the MARS core node contains.</b> 1606 kg of salt cannot fit in 1140 channels
of published cross-section at any plausible MSRE fuel-salt density - it would need
3014 kg/m3. Either the MARS core node includes plenum, bypass or annulus salt that this
record counts as loop, or the flow area in use is not the channel cross-section. Until that is
settled the -24.5 % is an honest statement of a real disagreement between the hardware
dimensions and the reported transit time, and it should not be closed by adjusting a
volume.</p>

<p><b>The loop transit time is not.</b> <code>V_downcomer</code> is the item that absorbs the
balance of the loop inventory and it was re-derived from <code>m_fuel_loop_paper</code>, so
16.14 s is arithmetic rather than evidence. There is no published downcomer volume to check it
against.</p>

<p>One thing does not reconcile. The core plenum nodes come out at about 3 litres each, which
at this plenum bore is an axial length of 12 mm, against the 63.5 mm the paper states for
Volume 190-01 in its core-boundary sensitivity study. The transit times depend on the volume
and not the length, so nothing above is affected, but the plenum bore assumed here is evidently
not the one the MARS input used.</p>

<p>The individual volumes that carry the largest uncertainty are
<code>V_downcomer</code> (which absorbs the balance of the loop inventory) and
<code>V_pumpBowl</code>. Form losses and the heat exchanger area were, as in the paper,
adjusted to give a sensible full-power steady state; both are exposed here so that the
paper's sensitivity cases can be run directly:</p>
<ul>
<li>case C1: <code>f_area_hx = 1.10</code></li>
<li>case C2: <code>K_pumpInlet = K_pumpExit = 0.5</code></li>
</ul>

<h4>Fuel pump rotor</h4>
<p><code>MSRE.Components.FuelPump_Dynamics</code> integrates the rotor angular momentum
equation, and the parameters it needs are collected here. Only one of them is free:</p>
<table border=\"1\">
<tr><th>Parameter</th><th>Value</th><th>Fixed by</th></tr>
<tr><td><code>P_pump_hydraulic</code></td><td>22.4 kW</td>
    <td>the rated duty, 3.0 bar at 168 kg/s</td></tr>
<tr><td><code>tau_pump_hyd_nominal</code></td><td>231 N.m</td>
    <td>that power, <code>N_pump_nominal</code> and <code>eta_pump</code></td></tr>
<tr><td><code>tau_pump_shaft</code></td><td>4.0 s</td><td><b>fitted</b></td></tr>
<tr><td><code>J_pump</code></td><td>7.59 kg.m2</td><td>follows from the two above</td></tr>
</table>
<p>These three moved with the density in Phase 2, because the rated duty is stated as a mass
flow rate and the hydraulic power needs a volumetric one. At 2063 kg/m3 they were 24.4 kW,
251 N.m and 8.28 kg.m2. Nothing about the pump transients changes: <code>tau_pump_shaft</code>
is the fitted quantity and it is unchanged, so the speed histories are identical.</p>
<p>The same <code>tau_pump_shaft</code> produces the startup and the coastdown, because with a
hydraulic torque proportional to the square of the speed the rotor equation gives
<code>tanh(t/tau)</code> when the motor is switched on and <code>1/(1+t/tau)</code> when it is
switched off. At 4.0 s the startup reaches 98.7 % of rated flow in 10 s. The paper's
sensitivity case with the moment of inertia halved is <code>tau_pump_shaft = 2.0</code>.</p>

<h4>What the reported transit times do and do not constrain</h4>
<p><code>tau_core_nominal</code> and <code>tau_loop_nominal</code> are calibration targets, but
what they actually fix is a <b>mass</b>: <code>tau*m_flow</code> contains no density. The
benchmark therefore pins the circulating inventory at</p>
<table border=\"1\">
<tr><th></th><th>paper implies</th><th>this record holds</th><th>error</th></tr>
<tr><td>core</td><td><code>m_fuel_core_paper</code> 1606 kg</td>
    <td><code>m_fuel_core_model</code> 1212 kg</td><td><code>err_m_core</code> -24.5 %</td></tr>
<tr><td>external loop</td><td><code>m_fuel_loop_paper</code> 2712 kg</td>
    <td><code>m_fuel_loop_model</code> 2712 kg</td><td><code>err_m_loop</code> 0.0 %</td></tr>
</table>
<p>and leaves the volume/density split of that mass undetermined. The loop error is zero
because <code>V_downcomer</code> was obtained by dividing <code>m_fuel_loop_paper</code> by
<code>d_fuel_ref</code>, which is circular and is the reason the loop side proves nothing. The
core error is not zero because the core volume is now hardware and is allowed to disagree.</p>

<p>The core side is now settled on the hardware and is <i>not</i> free:
<code>V_channels = 0.53284 m3</code> follows from 1140 channels of 2.87524e-4 m2 over
1.6256 m, with nothing left to adjust. Dividing 1606 kg by that volume gives an implied
density of 3014 kg/m3, which no MSRE fuel-salt correlation comes near - Cantor gives
2196.5 kg/m3 at 908 K and ORNL-TM-4865 gives 2249.3. Earlier revisions of this record read
the same comparison the other way round, using a channel volume of 0.7266 m3 that was never
traced to a hardware dimension and the Mao flow area of 0.4315 m2, and concluded that the
density was the quantity in error. With the channel geometry now built from the ORNL/INL
dimensions, that conclusion no longer follows: the implied density is 34 % above the traced
correlations, which points at the definition of the core node rather than at any property
correlation.</p>

<p>The loop side cannot be settled the same way: <code>V_downcomer</code> was always the item
that absorbed the balance of the inventory, so it has no independent value to check against and
would simply be re-derived from <code>m_fuel_loop_paper</code>.</p>
</html>"));
end Geometry;
