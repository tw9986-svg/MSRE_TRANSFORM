within MSRE.Data;
record Geometry "MSRE nodalization and geometry (Modelica counterpart of the MARS input of paper Fig. 2)"
  extends Modelica.Icons.Record;

  /* ------------------------------------------------------------------
     Nodalization
     ------------------------------------------------------------------ */
  /* NODALIZATION, not physical geometry. These describe how the hardware is discretized and
     are the 2-D default; the 1-D benchmark uses MSRE.Data.Nodalization.Core1D instead. They
     remain here because Systems.PrimarySystem and Components.ReactorCore still read them from
     this record. Moving the system model onto a nodalization record is open item O-21. */
  parameter Integer nRings=15
    "NODALIZATION (2-D default) | # of concentric radial rings the 1140 fuel channels are grouped into; see Data.Nodalization";
  parameter Integer nAxial=20
    "NODALIZATION | # of axial nodes per fuel channel; the same in 1-D and 2-D";
  parameter Integer nLP=3 "# of axial nodes in the lower plenum";
  parameter Integer nUP=3 "# of axial nodes in the upper plenum";
  parameter Integer nDC=10 "# of nodes in the downcomer";
  parameter Integer nHX=10 "# of nodes on each side of the heat exchanger";
  parameter Integer nOutletPipe=4 "# of nodes in the reactor outlet pipe";
  parameter Integer nPumpBowl=2 "# of nodes in the fuel pump bowl / volute";
  parameter Integer nPumpToHX=4 "# of nodes in the pump discharge pipe";
  parameter Integer nHXToVessel=6 "# of nodes in the heat exchanger outlet pipe";

  /* Core boundary, from Jeong et al., Nuclear Engineering and Technology 58 (2026) 104438:
     the reactor core is MARS Volume 120-03 (the last lower-plenum node), the 15 x 20 channel
     cells, and MARS Volume 190-01 (the first upper-plenum node). This is a control-volume
     DEFINITION and it is confirmed by the paper, so it is kept exactly. The VOLUMES of the two
     boundary nodes are a separate question and are not confirmed by anything - see
     V_lowerPlenum_core and V_upperPlenum_core below, and the JeongEq diagnostics. */
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
  /* Reference density for INVENTORY AND TRANSIT-TIME REPORTING ONLY. It is evaluated from the
     active fuel salt property model rather than restated, so it cannot drift away from the
     medium the way the ORNL-TM-4865 value it replaced had. The system model does not use it:
     MSRE.Systems.PrimarySystem evaluates the density from Medium_fuel directly. It is also NOT
     the pump reference density - see d_pump_ref in the pump block, which is a separate
     parameter precisely so that the two roles cannot move together by accident. */
  final parameter SI.Density d_fuel_ref=MSRE.Media.FuelSalt.Utilities.d_T(T_zeroPower)
    "PROPERTY-DERIVED | Cantor ORNL-TM-2316 at T_zeroPower = 908 K (2196.5143 kg/m3): reference density for inventory and transit-time reporting";
  final parameter SI.Density d_fuel_ref_legacy_Compere=2249.3
    "LEGACY REFERENCE ONLY | former geometry/inventory reference density, ORNL-TM-4865 at 908 K. Never connect it to an active calculation";

  /* ------------------------------------------------------------------
     Fuel channels (graphite-moderated core region)
     ------------------------------------------------------------------ */
  /* Primary hardware dimensions. Everything below them is a consequence: no flow area, no
     hydraulic diameter and no volume in this block is entered by hand or fitted to a reported
     transit time or inventory. See the record documentation for the provenance and for the
     Mao geometry this replaced. */
  parameter Real nChannels_total=1140
    "PHYSICAL | ORNL/INL hardware, and confirmed by Jeong et al. (2026): total # of vertical fuel channels";
  parameter Real nChannels[nRings]=fill(nChannels_total/nRings, nRings)
    "NODALIZATION (2-D default) | # of channels per radial ring (equal-area rings)";
  parameter SI.Length H_channels=1.6256
    "PHYSICAL | ORNL/INL hardware: active height of the fuel channels (64 in)";
  parameter SI.Length w_channel=0.03048
    "PHYSICAL | ORNL/INL hardware: width of a single fuel channel (1.2 in)";
  parameter SI.Length h_channel=0.01016
    "PHYSICAL | ORNL/INL hardware: depth of a single fuel channel (0.4 in)";
  parameter SI.Length r_channelCorner=0.00508
    "PHYSICAL | ORNL/INL hardware: rounded corner radius of a single fuel channel (0.2 in)";

  /* A fuel channel is a 1.2 x 0.4 in rectangle with all four corners rounded at 0.2 in. Each
     rounded corner removes (1 - pi/4)*r^2 of area and replaces 2r of straight wall with a
     quarter arc of length pi*r/2. */
  final parameter SI.Area A_channel=w_channel*h_channel - (4 - pi)*r_channelCorner^2
    "DERIVED | from the channel cross-section: flow area of a single fuel channel (2.87524e-4 m2)";
  final parameter SI.Length perimeter_channel=2*(w_channel + h_channel) - 4*(2 - pi/2)*
      r_channelCorner "DERIVED | from the channel cross-section: wetted perimeter of a single fuel channel (0.072559 m)";
  final parameter SI.Length Dh_channel=4*A_channel/perimeter_channel
    "DERIVED | 4*A/P: hydraulic diameter of a single fuel channel (0.015851 m)";
  final parameter SI.Area A_core_total=nChannels_total*A_channel
    "DERIVED | nChannels_total*A_channel: total core flow area (0.327778 m2)";
  final parameter SI.Volume V_channels=A_core_total*H_channels
    "DERIVED | A_core_total*H_channels: total fuel salt volume inside the graphite channels (0.532836 m3)";

  /* Graphite: each channel is represented by an equivalent annulus of graphite. Its inner
     radius reproduces the wetted perimeter of the real (grooved) channel and its outer radius
     reproduces the per-channel share of the graphite stack, so that both the convective area
     and the graphite heat capacity are preserved. */
  parameter SI.Length D_graphiteStack=1.40335
    "PHYSICAL | ORNL/INL hardware: diameter of the graphite stack (55.25 in)";
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
    "ASSUMPTION | radial peaking factor of each ring, channel-weighted average 1. A J0 shape with a 25 % reflector saving, NOT the paper's Serpent tabulation, which is not public";

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
  /* Vessel and core container hardware. The downcomer is the annulus between them, so its flow
     area and hydraulic diameter follow from these four dimensions and are not entered. */
  parameter SI.Length D_vessel_inner=1.4732
    "PHYSICAL | ORNL/INL hardware: reactor vessel inner diameter (58 in)";
  parameter SI.Length th_vessel=0.0254
    "PHYSICAL | ORNL/INL hardware: reactor vessel wall thickness (1 in)";
  parameter SI.Length D_coreContainer_inner=1.4097
    "PHYSICAL | ORNL/INL hardware: core container inner diameter (55.5 in)";
  parameter SI.Length th_coreContainer=0.00635
    "PHYSICAL | ORNL/INL hardware: core container wall thickness (0.25 in)";
  final parameter SI.Length D_coreContainer_outer=D_coreContainer_inner + 2*th_coreContainer
    "DERIVED | core container outer diameter (56 in)";

  /* Plenum totals (O-17). The two VOLUMES are now the MSRE fuel-salt fluid volumes reported in
     ORNL/TM-2019/1359, which attributes the MSRE volume information to ORNL-4865: 12.24 ft3 for
     the lower plenum and 11.34 ft3 for the upper. The conversion is exact,
     1 ft3 = 0.028316846592 m3. The two axial HEIGHTS have no confirmed source and stay
     assumptions; they are not to be adjusted to close an inventory or a transit time.

     Note that a plenum TOTAL volume and a Jeong core-boundary NODE volume are different
     things: V_upperPlenum is the whole upper plenum, while MARS Volume 190-01 is one node
     inside it. Nothing about 120-03 or 190-01 may be inferred from these totals; they stay
     O-12B OPEN. */
  parameter SI.Volume V_lowerPlenum=0.346598
    "REFERENCE | ORNL/TM-2019/1359 citing ORNL-4865: total lower-plenum fuel-salt fluid volume, 12.24 ft3";
  parameter SI.Length L_lowerPlenum=0.30
    "ASSUMPTION/OPEN | no independently confirmed axial height for the whole lower plenum";
  parameter SI.Volume V_upperPlenum=0.321113
    "REFERENCE | ORNL/TM-2019/1359 citing ORNL-4865: total upper-plenum fuel-salt fluid volume, 11.34 ft3";
  parameter SI.Length L_upperPlenum=0.30
    "ASSUMPTION/OPEN | no independently confirmed axial height for the whole upper plenum";

  /* Core boundary nodes: MARS Volume 120-03 (lower) and 190-01 (upper) of Jeong et al. (2026).
     The control-volume DEFINITION is confirmed by the paper and is kept - each is one node, each
     is counted as part of the reactor core, and together with the 15 x 20 channel cells they are
     the nV_core cells the kinetics sees.

     Each is now one third of the referenced whole-plenum volume. That is a MODELLING
     ASSUMPTION, not a measurement:

       ASSUMPTION / DERIVED FROM REFERENCE
       Equal-volume subdivision of the referenced whole-plenum volume.
       The physical volume of individual MARS node 120-03 / 190-01 is not
       independently confirmed.

     Nothing published states that the three nodes of either plenum are equal in volume, and
     Jeong's own 0.0635 m length for 190-01 is not one third of any plenum height in this
     record. They are therefore NOT tagged PHYSICAL, and O-12B stays OPEN. What this does buy
     is that the numerator is now a referenced fluid volume rather than the residue of an
     inventory balance: the previous 0.003055 m3 came from the reported 1606 kg core inventory
     with the old density and old channel volume subtracted, which is benchmark fitting, and it
     is retired to a diagnostic below. */
  final parameter SI.Volume V_lowerPlenum_core=V_lowerPlenum/nLP
    "ASSUMPTION/DERIVED FROM REFERENCE | equal-volume third of the referenced lower-plenum volume, standing in for MARS Volume 120-03 (0.1155327 m3). The physical node volume is not independently confirmed";
  final parameter SI.Volume V_upperPlenum_core=V_upperPlenum/nUP
    "ASSUMPTION/DERIVED FROM REFERENCE | equal-volume third of the referenced upper-plenum volume, standing in for MARS Volume 190-01 (0.1070377 m3). The physical node volume is not independently confirmed";

  final parameter SI.Volume V_plenumCore_legacy=0.003055
    "LEGACY | the inventory-balance value both core-boundary nodes carried before the equal-volume subdivision. Diagnostic only, connected to nothing";
  final parameter SIadd.NonDim err_V_lowerPlenum_core_legacy=V_lowerPlenum_core/
      V_plenumCore_legacy - 1
    "LEGACY DIAGNOSTIC | how far the equal-volume third is from the retired inventory-balance value (37.8x)";

  /* Node lengths under the same uniform-bore, equal-volume assumption as the volumes above.
     With an equal-volume subdivision each is simply one third of the plenum height, so both
     inherit the ASSUMPTION/OPEN status of L_lowerPlenum and L_upperPlenum. They are 0.1 m
     against the 0.0635 m Jeong states for 190-01; that gap is a statement about the assumed
     plenum height, not evidence about the node. */
  final parameter SI.Length L_lowerPlenum_core=V_lowerPlenum_core*L_lowerPlenum/V_lowerPlenum
    "ASSUMPTION/DERIVED | one third of the assumed lower-plenum height, not a physical MARS-node length (0.1 m)";
  final parameter SI.Length L_upperPlenum_core=V_upperPlenum_core*L_upperPlenum/V_upperPlenum
    "ASSUMPTION/DERIVED | one third of the assumed upper-plenum height, not a physical MARS-node length (0.1 m; the paper states 0.0635 m for 190-01)";

  /* ------------------------------------------------------------------
     Jeong core boundary: reference values and benchmark-equivalent diagnostics

     REFERENCE values are quoted directly from Jeong et al. (2026). JEONG-EQUIVALENT values are
     what the paper's reported sensitivity implies about the MARS nodalization; they are
     BENCHMARK-EQUIVALENT, NOT PHYSICAL, and nothing in this record is allowed to depend on
     them. They exist so that the gap between the benchmark and the hardware is a computed
     number rather than an argument.
     ------------------------------------------------------------------ */
  final parameter SI.Length L_190_01_Jeong=0.0635
    "REFERENCE | Jeong et al. (2026): baseline axial length of MARS Volume 190-01";
  final parameter SI.Length dL_190_01_Jeong=0.0800
    "REFERENCE | Jeong et al. (2026): axial length added to 190-01 in the core-boundary sensitivity case (0.0635 -> 0.1435 m)";
  final parameter SI.Time dtau_core_Jeong=1.11
    "REFERENCE | Jeong et al. (2026): core transit time increase reported for that case (the loop time falls by the same amount)";

  final parameter SI.VolumeFlowRate V_flow_ref=m_flow_nominal/d_fuel_ref
    "DERIVED | rated volumetric flow at the inventory reporting density (0.076485 m3/s)";
  final parameter SI.Area A_190_01_JeongEq=V_flow_ref*dtau_core_Jeong/dL_190_01_Jeong
    "BENCHMARK-EQUIVALENT, NOT PHYSICAL | flow area 190-01 must have in MARS for the reported sensitivity to hold (1.0612 m2)";
  final parameter SI.Volume V_190_01_JeongEq=A_190_01_JeongEq*L_190_01_Jeong
    "BENCHMARK-EQUIVALENT, NOT PHYSICAL | volume of MARS Volume 190-01 implied by the sensitivity (0.067388 m3, 22.1x the legacy value)";

  final parameter SI.Volume V_core_JeongEq=tau_core_paper*m_flow_nominal/d_fuel_ref
    "BENCHMARK-EQUIVALENT, NOT PHYSICAL | core volume the reported core transit time implies at the reporting density (0.731195 m3)";
  final parameter SI.Volume V_120_03_JeongEq=V_core_JeongEq - V_channels - V_190_01_JeongEq
    "BENCHMARK-EQUIVALENT, NOT PHYSICAL | residual left for MARS Volume 120-03; 37.8 % of this record's whole lower plenum since O-17, against 169 % before it (0.130971 m3)";

  final parameter SI.Area A_downcomer=pi/4*(D_vessel_inner^2 - D_coreContainer_outer^2)
    "DERIVED | ORNL/INL hardware: flow area of the downcomer annulus (0.115529 m2)";
  final parameter SI.Length Dh_downcomer=D_vessel_inner - D_coreContainer_outer
    "DERIVED | ORNL/INL hardware: hydraulic diameter of the downcomer annulus, twice the annular gap (0.0508 m)";
  parameter SI.Length L_downcomer=2.40
    "ASSUMPTION | no published source: flow length of the downcomer. Never adjust it to reproduce a transit time";
  final parameter SI.Volume V_downcomer=A_downcomer*L_downcomer
    "DERIVED | hardware area times an assumed length: fuel salt volume of the downcomer annulus (0.277270 m3)";

  /* ------------------------------------------------------------------
     External loop piping and pump
     ------------------------------------------------------------------ */
  parameter SI.Length D_pipe=0.127
    "REFERENCE | INL MSRE description: inner diameter of the main connecting piping (5 in)";
  parameter SI.Length L_outletPipe=4.00
    "ASSUMPTION | no published source confirmed: reactor outlet pipe length (vessel to pump)";
  parameter SI.Length L_pumpToHX=5.00
    "ASSUMPTION | no published source confirmed: pump discharge pipe length (pump to heat exchanger)";
  parameter SI.Length L_hxToVessel=7.00
    "ASSUMPTION | no published source confirmed: heat exchanger outlet pipe length (to the vessel inlet)";
  parameter SI.Volume V_pumpBowl=0.150
    "ASSUMPTION | no published source: fuel salt volume of the pump bowl and volute. Never enlarge it to close the loop inventory";
  parameter SI.Length L_pumpBowl=0.60
    "ASSUMPTION | no published source: effective flow length of the pump bowl";

  parameter SI.PressureDifference dp_pump_nominal=3.0e5
    "Fuel pump pressure rise at rated speed and rated flow (48.5 ft of salt)";
  parameter Real N_pump_nominal(unit="1/min") = 1160 "Rated fuel pump speed";
  parameter Real headRatio_shutoff=1.25
    "Ratio of shut-off head to rated head of the fuel pump";
  parameter SI.Efficiency eta_pump=0.8 "Fuel pump isentropic efficiency";

  /* Fuel pump rotor, REPORTED HERE AND USED NOWHERE. MSRE.Components.FuelPump_Dynamics
     computes its own tau_hyd_nominal and J from the d_nominal it is given, and
     MSRE.Systems.PrimarySystem sets that d_nominal from Medium_fuel, not from this record.
     The four quantities below are therefore diagnostics that mirror what the pump does; they
     are not inputs to it.

     They take their density from d_pump_ref, which is a separate parameter from d_fuel_ref
     even though the two evaluate to the same number today. Keeping them separate is the point:
     the geometry/inventory reference and the pump reference answer different questions, and a
     future change to one must not silently move the other. */
  final parameter SI.Density d_pump_ref=MSRE.Media.FuelSalt.Utilities.d_T(T_zeroPower)
    "PROPERTY-DERIVED | Cantor ORNL-TM-2316 at T_zeroPower: density the pump diagnostics below use, mirroring PrimarySystem.density_ref. Deliberately not an alias of d_fuel_ref";
  final parameter SI.VolumeFlowRate V_flow_pump_nominal=m_flow_nominal/d_pump_ref
    "DIAGNOSTIC | rated fuel pump volumetric flow rate (0.076485 m3/s)";
  final parameter SI.AngularVelocity omega_pump_nominal=2*pi*N_pump_nominal/60
    "Rated fuel pump angular velocity";
  final parameter SI.Power P_pump_hydraulic=dp_pump_nominal*V_flow_pump_nominal
    "DIAGNOSTIC | rated fuel pump hydraulic power (22.945 kW)";
  final parameter SI.Torque tau_pump_hyd_nominal=P_pump_hydraulic/(omega_pump_nominal*
      eta_pump) "DIAGNOSTIC | rated fuel pump hydraulic torque (236.1 N.m)";
  parameter SI.Time tau_pump_shaft=4.0
    "Fuel pump shaft time constant; sets the startup and the coastdown transient together";
  final parameter SI.MomentOfInertia J_pump=tau_pump_shaft*tau_pump_hyd_nominal/
      omega_pump_nominal "DIAGNOSTIC | fuel pump rotor moment of inertia (7.775 kg.m2)";

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
  parameter SI.Volume V_hxShell=0.266
    "ASSUMPTION | no published source; frozen with the rest of the heat exchanger, see open item O-16";
  final parameter SI.Area A_shell=V_hxShell/L_shell "Shell side flow area";
  parameter SI.Length Dh_shell=0.05606
    "OPEN / TO BE REVIEWED | shell-side hydraulic diameter. The INL MSRE description gives 0.0209 m for the same quantity; not changed here because it is coupled to the shell-side heat transfer. See open item O-16";
  final parameter SI.Length D_tube_outer=D_tube_inner + 2*th_tube "Tube outer diameter";
  parameter Real f_shellHT=3.0
    "LEGACY/DEPRECATED | shell-side turbulent Nusselt multiplier of the retired Dittus-Boelter-with-floor closure. Connected to nothing";
  parameter Real Nu_floor_shell=10.0
    "LEGACY/DEPRECATED | shell-side low-flow Nusselt floor of the retired closure. Connected to nothing";
  parameter Real f_area_hx=1.0
    "Multiplier on the heat transfer area (sensitivity case C1 of the paper uses 1.10)";

  /* ------------------------------------------------------------------
     Elevations (closed loop: the sum of all dheights is zero)
     ------------------------------------------------------------------ */
  parameter SI.Length dz_lowerPlenum=0.30 "Elevation rise across the lower plenum";
  final parameter SI.Length dz_channels=H_channels
    "DERIVED | elevation rise across the fuel channels, which is their active height (was 1.626 m, 0.4 mm adrift of H_channels; O-15)";
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
  /* PARTIAL_GEOMETRY_BASELINE. The channel term is hardware; the two boundary-node terms are
     equal-volume thirds of referenced plenum totals, which is an assumption. V_core is
     therefore only as good as that assumption, and it is not adjusted to reproduce
     tau_core_paper. */
  final parameter SI.Volume V_core=V_channels + V_lowerPlenum_core + V_upperPlenum_core
    "PARTIAL_GEOMETRY_BASELINE | fuel salt volume of the reactor core as Jeong et al. define it: channels + MARS 120-03 + MARS 190-01 (0.755406 m3)";
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

  /* Loop side, retired at the same time as the Mao core geometry. V_downcomer was never a
     measurement: it was set to whatever made the loop inventory match the reported loop transit
     time, and Dh_downcomer and D_pipe went with it. */
  final parameter SI.Volume V_downcomer_fitted=0.432371
    "Fitted downcomer volume - not active: the value that absorbed the balance of the reported loop inventory";
  final parameter SI.Length Dh_downcomer_fitted=0.1163
    "Fitted downcomer hydraulic diameter - not active; inconsistent with the vessel/container annulus";
  final parameter SI.Length D_pipe_sch40=0.1286
    "5 in schedule 40 inner diameter - not active; superseded by the 5 in nominal figure the INL MSRE description gives";
  final parameter SIadd.NonDim err_V_downcomer_fitted=V_downcomer/V_downcomer_fitted - 1
    "Change in downcomer volume caused by deriving it from the vessel annulus (-35.9 %)";

  final parameter SI.Length dz_closure=dz_lowerPlenum + dz_channels + dz_upperPlenum +
      dz_outletPipe + dz_pumpBowl + dz_pumpToHX + dz_hxShell + dz_hxToVessel + dz_downcomer
    "Sum of all elevation rises around the loop, which must be zero";

  annotation (defaultComponentName="geometry", Documentation(info="<html>
<h4>Provenance classification</h4>
<p>Every geometric input carries one of six tags, repeated in its own description string so
that it travels with the parameter:</p>
<table border=\"1\">
<tr><th>Tag</th><th>Meaning</th></tr>
<tr><td><b>PHYSICAL</b></td><td>a published ORNL/INL hardware dimension</td></tr>
<tr><td><b>DERIVED</b></td><td>computed from PHYSICAL inputs, no freedom of its own</td></tr>
<tr><td><b>REFERENCE</b></td><td>quoted from a publication, used as a comparison and not as an input</td></tr>
<tr><td><b>ASSUMPTION</b></td><td>no published source found; the value is an estimate and is <i>never</i> to be tuned to close an inventory or a transit time</td></tr>
<tr><td><b>LEGACY</b></td><td>a value produced by an earlier fit, kept for comparison</td></tr>
<tr><td><b>BENCHMARK-EQUIVALENT</b></td><td>what a reported benchmark result implies about the MARS nodalization; <i>not physical</i>, and nothing active depends on it</td></tr>
</table>

<table border=\"1\">
<tr><th>Parameter</th><th>Value</th><th>Class</th><th>Provenance</th></tr>
<tr><td><code>nChannels_total</code>, <code>H_channels</code>, <code>w_channel</code>,
        <code>h_channel</code>, <code>r_channelCorner</code></td>
    <td>1140, 1.6256 m, 30.48/10.16/5.08 mm</td><td>PHYSICAL</td><td>ORNL/INL hardware</td></tr>
<tr><td><code>A_channel</code>, <code>perimeter_channel</code>, <code>Dh_channel</code>,
        <code>A_core_total</code>, <code>V_channels</code></td>
    <td>2.87524e-4 m2, 0.072559 m, 0.015851 m, 0.327778 m2, 0.532836 m3</td>
    <td>DERIVED</td><td>the five above</td></tr>
<tr><td><code>D_graphiteStack</code></td><td>1.40335 m</td><td>PHYSICAL</td><td>ORNL/INL hardware</td></tr>
<tr><td><code>V_lowerPlenum_core</code> (MARS 120-03)</td><td>0.1155327 m3</td>
    <td><b>ASSUMPTION / DERIVED FROM REFERENCE</b></td>
    <td>equal-volume third of the referenced lower-plenum volume; physical node volume unresolved</td></tr>
<tr><td><code>V_upperPlenum_core</code> (MARS 190-01)</td><td>0.1070377 m3</td>
    <td><b>ASSUMPTION / DERIVED FROM REFERENCE</b></td><td>as above, upper plenum</td></tr>
<tr><td><code>V_plenumCore_legacy</code></td><td>0.003055 m3</td><td>LEGACY</td>
    <td>the retired inventory-balance value, diagnostic only</td></tr>
<tr><td><code>L_190_01_Jeong</code></td><td>0.0635 m</td><td>REFERENCE</td><td>Jeong et al. (2026)</td></tr>
<tr><td><code>dL_190_01_Jeong</code>, <code>dtau_core_Jeong</code></td><td>0.0800 m, 1.11 s</td>
    <td>REFERENCE</td><td>Jeong et al. (2026) core-boundary sensitivity</td></tr>
<tr><td><code>A_190_01_JeongEq</code></td><td>1.0612 m2</td>
    <td>BENCHMARK-EQUIVALENT</td><td>the two above</td></tr>
<tr><td><code>V_190_01_JeongEq</code></td><td>0.067388 m3</td>
    <td>BENCHMARK-EQUIVALENT</td><td>as above</td></tr>
<tr><td><code>V_core_JeongEq</code>, <code>V_120_03_JeongEq</code></td><td>0.731195, 0.130971 m3</td>
    <td>BENCHMARK-EQUIVALENT</td><td>reported tau_C, as a residual</td></tr>
<tr><td><code>V_lowerPlenum</code>, <code>V_upperPlenum</code></td>
    <td>0.346598 m3, 0.321113 m3</td><td><b>REFERENCE</b></td>
    <td>ORNL/TM-2019/1359 citing ORNL-4865, 12.24 and 11.34 ft3 (O-17)</td></tr>
<tr><td><code>L_lowerPlenum</code>, <code>L_upperPlenum</code></td><td>0.30 m each</td>
    <td>ASSUMPTION / OPEN</td><td>no published source; not fixed by O-17</td></tr>
<tr><td><code>D_vessel_inner</code>, <code>th_vessel</code>,
        <code>D_coreContainer_inner</code>, <code>th_coreContainer</code></td>
    <td>1.4732, 0.0254, 1.4097, 0.00635 m</td><td>PHYSICAL</td><td>ORNL/INL hardware</td></tr>
<tr><td><code>A_downcomer</code>, <code>Dh_downcomer</code></td><td>0.115529 m2, 0.0508 m</td>
    <td>DERIVED</td><td>the vessel/container annulus</td></tr>
<tr><td><code>L_downcomer</code></td><td>2.40 m</td><td>ASSUMPTION</td><td>no published source</td></tr>
<tr><td><code>V_downcomer</code></td><td>0.277270 m3</td><td>DERIVED</td>
    <td>hardware area x assumed length</td></tr>
<tr><td><code>D_pipe</code></td><td>0.127 m</td><td>REFERENCE</td><td>INL MSRE description, 5 in</td></tr>
<tr><td><code>d_fuel_ref</code></td><td>2196.5143 kg/m3</td><td>PROPERTY-DERIVED</td>
    <td>Cantor ORNL-TM-2316 at <code>T_zeroPower</code> = 908 K; inventory and transit-time
        reporting only</td></tr>
<tr><td><code>d_pump_ref</code></td><td>2196.5143 kg/m3</td><td>PROPERTY-DERIVED</td>
    <td>the same correlation, evaluated separately for the pump diagnostics</td></tr>
<tr><td><code>d_fuel_ref_legacy_Compere</code></td><td>2249.3 kg/m3</td><td>LEGACY</td>
    <td>ORNL-TM-4865 at 908 K, inert</td></tr>
<tr><td><code>L_outletPipe</code>, <code>L_pumpToHX</code>, <code>L_hxToVessel</code></td>
    <td>4.00, 5.00, 7.00 m</td><td>ASSUMPTION</td><td>no published source confirmed</td></tr>
<tr><td><code>V_pumpBowl</code>, <code>L_pumpBowl</code></td><td>0.150 m3, 0.60 m</td>
    <td>ASSUMPTION</td><td>no published source</td></tr>
<tr><td><code>V_hxShell</code></td><td>0.266 m3</td><td>ASSUMPTION</td>
    <td>no published source; frozen with the rest of the heat exchanger (O-16)</td></tr>
<tr><td><code>V_downcomer_fitted</code>, <code>Dh_downcomer_fitted</code>,
        <code>D_pipe_sch40</code>, the <code>*_Mao</code> set</td><td>-</td>
    <td>LEGACY</td><td>retired fits, inert</td></tr>
</table>

<h4>O-12B: what the public sources say about the two boundary nodes</h4>
<p>A source review was carried out to try to give 120-03 and 190-01 physical volumes instead of
the legacy inventory-derived 3.055 litres. <b>The outcome was to keep them OPEN.</b> The
findings are recorded here because they are decision-relevant, not because they were adopted.</p>

<p><b>Provenance warning.</b> None of the figures in this section could be read from its
original document: every PDF host (info.ornl.gov, publications.anl.gov, osti.gov,
mooseframework.inl.gov, moltensalt.org) is unreachable from the environment this review was run
in. They are as rendered by a search index from the ANL SAM MSRE model report and the ORNL MSRE
TRANSFORM status report, so they are <b>secondary and unverified</b>, and no table, figure or
page number could be attached to any of them. They must not be promoted to REFERENCE parameters
until someone reads them in the source.</p>

<table border=\"1\">
<tr><th>Quantity</th><th>Value as reported</th><th>Attributed to</th><th>Definition class</th></tr>
<tr><td>core height</td><td>1.6637 m (65.5 in)</td><td>ANL SAM MSRE model</td>
    <td>code-model 1-D geometry</td></tr>
<tr><td>lower plenum height</td><td>0.12954 m (5.1 in)</td><td>ANL SAM MSRE model</td>
    <td>code-model 1-D geometry</td></tr>
<tr><td>upper plenum height</td><td>0.21336 m (8.4 in)</td><td>ANL SAM MSRE model</td>
    <td>code-model 1-D geometry</td></tr>
<tr><td>lower plenum flow area / Dh</td><td>1.71 m2 / 1.47 m</td><td>ANL SAM MSRE model</td>
    <td>code-model, <b>porosity set to 1.0</b></td></tr>
<tr><td>upper plenum fluid volume</td><td>11.34 ft3 = 0.32111 m3</td>
    <td>ORNL MSRE TRANSFORM status report</td><td>unclear</td></tr>
<tr><td>core region radius / porosity</td><td>0.70485 m / 0.225</td><td>ANL SAM MSRE model</td>
    <td>R-Z porous-medium equivalent</td></tr>
</table>

<h4>Physical mapping, as far as it goes</h4>
<p><b>120-03</b> is the top slice of the lower plenum, immediately below the fuel channel
entrance. The physical region is the lower vessel head together with 48 anti-swirl vanes, the
main support grid, and the horizontal graphite lattice bars that the vertical stringers dowel
into - and the salt reaches the channels through the small gaps between those bars, which carry
most of the core pressure drop. The central part of the lattice has no horizontal bars at all.
No axial height, open flow area or fluid volume for this region was found in any accessible
source. The one area figure available, the SAM 1.71 m2, is the full vessel bore with
<b>porosity 1.0, structures ignored</b>, so it is an upper bound on an open area and not a
fluid volume of the real region. <b>120-03 stays OPEN.</b></p>

<p><b>190-01</b> is the bottom slice of the upper plenum, immediately above the channel exit,
and Jeong states its baseline axial length as 0.0635 m (2.5 in). That length is solid; what is
missing is an independent flow area to multiply it by. Four candidates were evaluated:</p>
<table border=\"1\">
<tr><th>Candidate area</th><th>Value</th><th>V at L = 0.0635 m</th><th>Verdict</th></tr>
<tr><td>reactor vessel bore (58 in)</td><td>1.70456 m2</td><td>0.108240 m3</td>
    <td>ignores the core container wall</td></tr>
<tr><td>core container bore (55.5 in)</td><td>1.56079 m2</td><td>0.099110 m3</td>
    <td>ignores displaced structure</td></tr>
<tr><td>SAM upper plenum mean area (0.32111/0.21336)</td><td>1.50503 m2</td>
    <td>0.095569 m3</td><td>unverified, and the plenum is domed rather than prismatic</td></tr>
<tr><td><i>A_190_01_JeongEq</i></td><td><i>1.06123 m2</i></td><td><i>0.067388 m3</i></td>
    <td><b>excluded</b> - it is derived from a MARS result</td></tr>
</table>
<p>The three physical candidates span 0.0956 to 0.1082 m3 and none of them was traceable to a
statement of what the region actually contains. They also disagree with the Jeong-equivalent
figure by 42 to 61 %, which is far too wide to call a reconstruction. Choosing whichever came
closest to 1.06123 m2 would be benchmark fitting with extra steps. <b>190-01 stays OPEN.</b></p>

<h4>The collateral finding, which is the useful part</h4>
<p>The two <i>plenum totals</i> were assumptions of 0.0777 m3 each when this review was
written. The figures above put the lower plenum near 0.2215 m3 and the upper plenum near
0.3211 m3 - <b>2.9 and 4.1 times larger</b> - which pointed at <code>V_lowerPlenum</code> and
<code>V_upperPlenum</code> rather than at the channel geometry as the place the missing
circulating inventory was hiding. That lead was followed up in O-17 below, and the totals are
now REFERENCE values. <b>The ~0.2215 m3 lower-plenum figure was a secondary SAM porous-medium
estimate</b> (1.71 m2 at porosity 1.0 over the SAM 0.12954 m height) and is neither active nor
a reference value; O-17 supersedes it with the ORNL MSRE fluid-volume figure of 12.24 ft3 =
0.346598 m3. The upper-plenum figure in that row is the same 11.34 ft3 O-17 adopts.</p>

<p>Two definition mismatches are worth recording alongside. The SAM core height of 1.6637 m
(65.5 in) is 2.34 % longer than the 1.6256 m (64 in) active height used here, and the SAM core
salt flow area of 0.3512 m2 (1.5608 m2 at porosity 0.225) is 7 % larger than the 0.32778 m2 that
1140 channels of documented cross-section give. Neither was adopted: they are R-Z porous-medium
equivalents, which this 1-D channel baseline deliberately does not use.</p>

<h4>The Jeong core boundary, and what its own sensitivity implies</h4>
<p>Jeong et al. (2026) define the reactor core as MARS Volume 120-03, the 15 x 20 channel
cells, and MARS Volume 190-01. That <i>definition</i> is confirmed and is what this record
implements: <code>iLP_core = nLP</code>, <code>iUP_core = 1</code>,
<code>nV_core = nRings*nAxial + 2</code>. The <i>volumes</i> of those two nodes are not
published, and the 3.055 litre value this record carries is not a measurement of them - it is
what was left of the reported 1606 kg core inventory after the old density and the old channel
volume were taken out, halved. Every input to that derivation has since been replaced.</p>

<p>The paper does report one thing that constrains 190-01. Lengthening it by 0.0800 m moves
<code>tau_core</code> by +1.11 s and <code>tau_loop</code> by -1.11 s, and a transit time is a
volume divided by a volumetric flow, so the node's flow area follows:</p>
<p><code>A = V_flow*dtau/dL = 0.076485*1.11/0.0800 = 1.0612 m2</code></p>
<p>which over the stated 0.0635 m baseline length is <b>0.067388 m3</b> - twenty-two times the
3.055 litres this record uses, and 21.0 % of the whole upper plenum (it was 87 % of the
0.0777 m3 assumed before O-17). The same arithmetic applied to the reported core transit time
leaves <b>0.130971 m3</b> for 120-03, which is 37.8 % of the whole lower plenum, against 169 %
of the assumed figure before O-17. Both figures scale inversely with the
reporting density, so they moved by +2.40 % when it became the Cantor value; the residual for
120-03 moved by +13.5 % because it is a difference of two larger numbers.</p>

<p>Two readings survived that when the plena were assumed at 0.0777 m3: either the MARS plena
are much larger than assumed, or MARS counts as core-boundary nodes a region this record counts
as plenum and downcomer. O-17 has since settled the first of them - the plena really are about
four times larger - and the residual disagreement is now a loop-side <i>excess</i> rather than
a shortfall, so the second reading is what is left to test. What is <i>not</i> a legitimate response is
setting <code>V_upperPlenum_core := V_190_01_JeongEq</code>: that number is
BENCHMARK-EQUIVALENT, it is derived from a MARS result rather than from hardware, and adopting
it would put the transit-time fitting straight back in. It is reported and left disconnected on
purpose.</p>

<h4>O-17: the whole-plenum fluid volumes</h4>
<p><b>Status: CLOSED / REFERENCE for the two volumes. The two plenum heights stay OPEN.</b></p>

<table border=\"1\">
<tr><th></th><th>lower plenum</th><th>upper plenum</th></tr>
<tr><td>previous active value</td><td>0.0777 m3</td><td>0.0777 m3</td></tr>
<tr><td>previous status</td><td colspan=\"2\">unsupported assumption, no published source</td></tr>
<tr><td>reported fluid volume</td><td>12.24 ft3</td><td>11.34 ft3</td></tr>
<tr><td>new active value</td><td><b>0.346598 m3</b></td><td><b>0.321113 m3</b></td></tr>
<tr><td>ratio to the old assumption</td><td>4.46x</td><td>4.13x</td></tr>
</table>

<p>Source: <i>Status Report on the MSRE TRANSFORM Model for Thermal-Hydraulic Benchmarking</i>,
ORNL/TM-2019/1359, which attributes its MSRE volume information to ORNL-4865. The conversion
uses the exact factor 1 ft3 = 0.028316846592 m3, so 12.24 ft3 = 0.346598 m3 and
11.34 ft3 = 0.321113 m3.</p>

<p><b>What this does not settle.</b> These are whole-plenum <i>totals</i>. They say nothing
about the volume of MARS Volume 120-03 or 190-01, which are single nodes inside those plena and
are a different quantity: <code>V_lowerPlenum_core</code> and <code>V_upperPlenum_core</code>
were later given equal-volume thirds of the referenced plenum totals, which is an assumption
rather than a reconstruction, so <b>O-12B stays OPEN</b>. The axial heights
<code>L_lowerPlenum</code> and <code>L_upperPlenum</code> also stay at 0.30 m as OPEN
assumptions - the report gives fluid volumes, not a nodalization - so the uniform-bore node
lengths derived from them remain diagnostics and not reconstructions. Nothing else was
adjusted: no pipe length, no pump or heat exchanger volume, no density, no mass flow, no
channel or downcomer geometry, and no assertion tolerance.</p>

<h4>What O-17 changes, and what it does to the disagreement</h4>
<table border=\"1\">
<tr><th>Quantity</th><th>before O-17</th><th>after O-17</th></tr>
<tr><td><code>V_core</code></td><td>0.538946 m3</td><td><b>0.755406 m3</b> after the equal-volume subdivision</td></tr>
<tr><td><code>V_loop</code></td><td>1.045243 m3</td><td><b>1.557554 m3</b> (+49.0 %)</td></tr>
<tr><td><code>V_total</code></td><td>1.584189 m3</td><td><b>2.096500 m3</b> (+32.3 %)</td></tr>
<tr><td><code>tau_core_nominal</code></td><td>7.046 s</td><td><b>9.877 s</b> (paper 9.56 s)</td></tr>
<tr><td><code>tau_loop_nominal</code></td><td>13.666 s</td><td><b>17.534 s</b> (paper 16.14 s)</td></tr>
<tr><td><code>tau_system_nominal</code></td><td>20.713 s</td><td><b>27.411 s</b> (paper 25.63 s)</td></tr>
<tr><td><code>m_fuel_loop_model</code></td><td>2296 kg</td><td><b>2946 kg</b></td></tr>
<tr><td><code>err_m_loop</code></td><td>-15.33 %</td><td><b>+8.64 %</b></td></tr>
<tr><td>circulating inventory</td><td>3480 kg, -19.41 %</td><td><b>4605 kg, +6.66 %</b></td></tr>
<tr><td><code>L_lowerPlenum_core</code></td><td>0.011795 m</td><td>0.002644 m (diagnostic)</td></tr>
<tr><td><code>L_upperPlenum_core</code></td><td>0.011795 m</td><td>0.002854 m (diagnostic)</td></tr>
</table>

<p>The loop side has gone from holding 15.3 % less salt than the reported loop transit time
implies to holding 26.2 % more, and the total circulating inventory from 19.4 % short to 6.7 %
long. That is not a worse result: the old agreement on the total was the sum of an unsourced
plenum assumption and an unexplained shortfall, and what is left now is a single, sharper
statement - <b>the core side is 26.3 % short and the loop side is 26.2 % long, at almost
exactly the same magnitude</b>. That is consistent with the second reading recorded under
O-12: MARS counts as core-boundary salt a region this record counts as loop. It is recorded,
not acted on; assigning that salt would require the MARS node volumes, which is O-12B and
still OPEN.</p>

<p>The natural-circulation drift barely moves, because at 1.46 and 4.45 kg/s both transit
times are already long compared with every precursor half-life: 1.5619 and 10.4928 pcm become
1.5619 and 10.5004 pcm. The forced-circulation drift computed at this record's own transit
times moves from 269.9 to 287.7 pcm against the paper's 228.4 pcm, which is the same
disagreement seen from the other side. <b>No assertion tolerance was changed and no assertion
was removed</b> - the three that fail are O-14 and are left exactly as they were.</p>

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
<tr><td>core volume</td><td>0.75541 m3</td><td>-</td><td>no</td></tr>
<tr><td>core transit time at 168 kg/s</td><td>9.88 s</td><td>9.56 s</td><td>no</td></tr>
<tr><td>loop transit time at 168 kg/s</td><td>17.53 s</td><td>16.14 s</td><td>no</td></tr>
<tr><td>system transit time</td><td>27.41 s</td><td>25.63 s (measured 25.2 s)</td><td>-</td></tr>
</table>
<p>Nothing in that table is fitted any more. Before Phase 5 the loop row read 16.14 s against
16.14 s, and it read that way because <code>V_downcomer</code> had been set to whatever made it
so. The loop row moved from 13.67 s to 20.36 s in O-17, when the two plenum totals became the
ORNL fluid volumes, and back to 17.53 s once a third of each plenum was counted as a
core-boundary node. Both are inputs changing, not fits.</p>

<h4>The core transit time is a prediction, and it now disagrees with the paper</h4>
<p>The core volume is the ORNL/INL hardware channel geometry (1140 channels of
1.2 x 0.4 in with 0.2 in rounded corners, 1.6256 m tall) plus two small plenum nodes, and the
density is the active Cantor correlation at 908 K. Nothing in it was adjusted to hit a reported
number. With the core-boundary nodes taken as equal-volume thirds of the referenced plenum
totals, <code>tau_core_nominal</code> comes out at 9.88 s against the 9.56 s the paper reports,
which is <b>+3.3 %</b>. That closeness is the coincidence of two assumptions meeting, not a
demonstration that the core geometry is confirmed, and it must not be read as one.</p>

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
settled the +3.3 % rests on the equal-volume subdivision being right, which nothing shows, and it should not be closed by adjusting a
volume.</p>

<h4>The loop side, and what is left unsourced there</h4>
<p><code>V_downcomer</code> used to be the item that absorbed the balance of the loop
inventory: it was set from <code>m_fuel_loop_paper</code>, so the 16.14 s it produced was
arithmetic rather than evidence. It is now the vessel annulus. The reactor vessel inner
diameter (58 in) and the core container outer diameter (55.5 in bore plus two 0.25 in walls,
so 56 in) give an annular gap of 25.4 mm, hence</p>
<table border=\"1\">
<tr><th></th><th>fitted (retired)</th><th>vessel annulus (active)</th></tr>
<tr><td><code>A_downcomer</code></td><td>0.18016 m2</td><td>0.115529 m2</td></tr>
<tr><td><code>Dh_downcomer</code></td><td>0.1163 m</td><td>0.0508 m</td></tr>
<tr><td><code>V_downcomer</code></td><td>0.432371 m3</td><td>0.277270 m3 (-35.9 %)</td></tr>
</table>
<p>The old hydraulic diameter of 0.1163 m was not the annulus of any vessel in the record; it
was carried alongside the fitted volume. The area is now hardware and only
<code>L_downcomer = 2.40 m</code> is still an estimate, so the fit has been reduced from a
volume to a length rather than removed.</p>

<p><b>What remains unsourced on the loop side.</b> No published value was found for any of
these and none was invented; they keep the values they had and are marked as estimates in the
record: the two plenum <i>heights</i> (0.30 m each), the core-boundary plenum nodes
(equal-volume thirds), <code>V_pumpBowl</code> (0.150 m3), <code>L_downcomer</code>, the three
pipe lengths and the whole elevation set. The two plenum <i>volumes</i> have left this list:
O-17 replaced the 0.0777 m3 assumptions with the ORNL fluid volumes, 0.346598 and
0.321113 m3. <code>D_pipe</code> moved from the 5 in schedule 40
bore of 0.1286 m to the 5 in figure the INL MSRE description gives, 0.127 m, which is a 2.5 %
reduction in pipe volume and is the only piping quantity with a published counterpart.</p>

<p>One thing does not reconcile. The core plenum nodes come out at about 3 litres each, which
under the uniform-bore assumption and the 0.30 m plenum heights is an axial length of 2.6 and
2.9 mm, against the 63.5 mm the paper states for Volume 190-01 in its core-boundary sensitivity
study. Those two lengths are diagnostics built on an OPEN height and a LEGACY/OPEN node volume,
so the gap measures the node volumes rather than the plenum bore; the transit times depend on
the volume and not the length, so nothing above is affected. O-17 widened the gap by enlarging
the denominators, which is what a larger plenum holding the same 3 litre node must do.</p>

<p>The individual volumes that carry the largest uncertainty are now <code>V_pumpBowl</code>
and the two core-boundary plenum nodes, neither of which has a published counterpart. Form losses and the heat exchanger area were, as in the paper,
adjusted to give a sensible full-power steady state; both are exposed here so that the
paper's sensitivity cases can be run directly:</p>
<ul>
<li>case C1: <code>f_area_hx = 1.10</code></li>
<li>case C2: <code>K_pumpInlet = K_pumpExit = 0.5</code></li>
</ul>

<h4>Reference density, and why there are two of them</h4>
<p>One number used to serve every purpose in this record. <code>d_fuel_ref = 2249.3 kg/m3</code>
was the ORNL-TM-4865 value, and it fed the reported inventories, the reported transit times,
the JeongEq diagnostics and the four pump quantities below at once - so it disagreed with the
Cantor medium the library actually runs on, and any correction to it would have moved the pump
figures as a side effect. It is now split:</p>
<table border=\"1\">
<tr><th></th><th>question it answers</th><th>value</th><th>who uses it</th></tr>
<tr><td><code>d_fuel_ref</code></td><td>how much salt do these volumes hold, and how long does
    it take to go round</td><td>Cantor at 908 K, 2196.5143</td>
    <td>this record's inventory, transit-time and JeongEq quantities</td></tr>
<tr><td><code>d_pump_ref</code></td><td>what volumetric duty does the rated mass flow
    correspond to</td><td>Cantor at 908 K, 2196.5143</td>
    <td>the four pump diagnostics below, and nothing else</td></tr>
<tr><td><code>PrimarySystem.density_ref</code></td><td>both, at run time</td>
    <td>evaluated from <code>Medium_fuel</code></td>
    <td>the actual simulation, including the pump</td></tr>
</table>
<p>The two parameters evaluate to the same number today, because both read the same
correlation at the same temperature. <b>The separation is structural, not numerical</b>: it
means a later change to the reporting reference cannot move the pump figures, and vice versa.
Neither reaches a simulation - <code>PrimarySystem</code> sets the pump's <code>d_nominal</code>
from <code>Medium_fuel</code> and computes its own <code>density_ref</code> the same way, so
this record's densities are reporting quantities throughout.</p>
<p>The legacy value is kept as <code>d_fuel_ref_legacy_Compere</code> and is connected to
nothing.</p>

<h4>Fuel pump rotor</h4>
<p><code>MSRE.Components.FuelPump_Dynamics</code> integrates the rotor angular momentum
equation, and the parameters it needs are collected here. Only one of them is free:</p>
<table border=\"1\">
<tr><th>Parameter</th><th>Value</th><th>Fixed by</th></tr>
<tr><td><code>P_pump_hydraulic</code></td><td>22.945 kW</td>
    <td>the rated duty, 3.0 bar at 168 kg/s</td></tr>
<tr><td><code>tau_pump_hyd_nominal</code></td><td>236.1 N.m</td>
    <td>that power, <code>N_pump_nominal</code> and <code>eta_pump</code></td></tr>
<tr><td><code>tau_pump_shaft</code></td><td>4.0 s</td><td><b>fitted</b>, unchanged</td></tr>
<tr><td><code>J_pump</code></td><td>7.775 kg.m2</td><td>follows from the two above</td></tr>
</table>
<p>These four are <b>diagnostics</b>. Nothing reads them:
<code>MSRE.Components.FuelPump_Dynamics</code> computes its own
<code>tau_hyd_nominal</code> and <code>J</code> from the <code>d_nominal</code> it is handed,
and <code>PrimarySystem</code> hands it <code>density_ref</code>. The three numbers above that
moved did so only because <code>d_pump_ref</code> is now the Cantor density rather than the
ORNL-TM-4865 one, all by the same +2.403 %; no pump parameter was retuned, and
<code>tau_pump_shaft</code>, the one fitted quantity, is untouched, so every pump transient is
bit-for-bit what it was.</p>
<p>They have moved twice with the reference density, in Phase 2 and again in Phase 7, for the
same structural reason: the rated duty is stated as a mass flow rate and the hydraulic power
needs a volumetric one. At 2063 kg/m3 they were 24.4 kW, 251 N.m and 8.28 kg.m2; at the
ORNL-TM-4865 2249.3 kg/m3 they were 22.407 kW, 230.6 N.m and 7.592 kg.m2. The speed histories
are identical in every case because <code>tau_pump_shaft</code> is the fitted quantity and it
has never changed.</p>
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
    <td><code>m_fuel_core_model</code> 1659 kg</td><td><code>err_m_core</code> <b>+3.3 %</b></td></tr>
<tr><td>external loop</td><td><code>m_fuel_loop_paper</code> 2712 kg</td>
    <td><code>m_fuel_loop_model</code> 2946 kg</td><td><code>err_m_loop</code> <b>+8.6 %</b></td></tr>
</table>
<p>and leaves the volume/density split of that mass undetermined. Both errors are now real
measurements of a disagreement. The loop error used to be exactly zero, and that was not
agreement: <code>V_downcomer</code> had been obtained by dividing
<code>m_fuel_loop_paper</code> by <code>d_fuel_ref</code>, so the zero was the definition of
<code>V_downcomer</code> read back out. It then went to -15.3 % when the downcomer became the
vessel annulus, to +26.2 % when O-17 gave the two plena their ORNL fluid volumes, and to
+8.6 % once a third of each plenum moved into the core. The loop
now holds more salt than the reported loop transit time implies, by very nearly the same
fraction that the core holds less.</p>

<p>The core side is now settled on the hardware and is <i>not</i> free:
<code>V_channels = 0.53284 m3</code> follows from 1140 channels of 2.87524e-4 m2 over
1.6256 m, with nothing left to adjust. Dividing 1606 kg by that volume gives an implied
density of 3014 kg/m3, which no MSRE fuel-salt correlation comes near - the active Cantor
correlation gives 2196.5 kg/m3 at 908 K, so the implied figure is 37 % high, and ORNL-TM-4865
gives 2249.3. Earlier revisions of this record read
the same comparison the other way round, using a channel volume of 0.7266 m3 that was never
traced to a hardware dimension and the Mao flow area of 0.4315 m2, and concluded that the
density was the quantity in error. With the channel geometry now built from the ORNL/INL
dimensions, that conclusion no longer follows: the implied density is 37 % above the active
correlation, which points at the definition of the core node rather than at any property
correlation.</p>

<p>The loop side now points the other way, and that is the substantive result of O-17. 2712 kg
in the loop at 2196.5 kg/m3 needs 1.2345 m3; this record held 1.0452 m3 while the plena were
assumed at 0.0777 m3, and holds 1.5576 m3 now that they are the ORNL fluid volumes. The excess
is 0.3231 m3. It cannot be removed by shortening the downcomer, which holds only 0.2773 m3 in
total, so it is not a loop-length estimate that is wrong.</p>

<p>Taking the two sides together: the reported inventory is 4318 kg and this record holds
4605 kg of it at the same reference density, 6.7 % long, made of a core that is 53 kg over
(+3.3 %) and a loop that is 234 kg over (+8.6 %). Both sides now err in the same direction by a
similar amount, which is what a slightly over-large total inventory looks like rather than a
misplaced boundary. That is a better-behaved residual than before, but it was reached by an
assumption about how the plena subdivide, not by a measurement: confirming it still needs the
MARS node volumes, O-12B, still OPEN. No volume here was moved to make the two sides meet.</p>
</html>"));
end Geometry;
