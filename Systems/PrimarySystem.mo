within MSRE.Systems;
model PrimarySystem
  "MSRE primary system with the secondary side of the heat exchanger imposed as a boundary condition"

  import TRANSFORM;

  /* ================================================================
     Configuration
     ================================================================ */
  replaceable package Medium_fuel = MSRE.Media.FuelSalt_U235 constrainedby
    Modelica.Media.Interfaces.PartialMedium
    "Fuel salt medium; its trace substances are the delayed neutron precursor groups"
    annotation (choicesAllMatching=true);
  replaceable package Medium_coolant = MSRE.Media.CoolantSalt constrainedby
    Modelica.Media.Interfaces.PartialMedium "Secondary coolant salt medium"
    annotation (choicesAllMatching=true);
  replaceable record Data_PG = MSRE.Data.PrecursorGroups.U235_6group constrainedby
    TRANSFORM.Nuclear.ReactorKinetics.Data.PrecursorGroups.PartialPrecursorGroup
    "Delayed neutron precursor data" annotation (choicesAllMatching=true);
  replaceable record Data_K = MSRE.Data.Kinetics_U235 constrainedby
    MSRE.Data.PartialKineticsData
    "Prompt generation time and reactivity coefficients"
    annotation (choicesAllMatching=true);

  Data_PG data_PG "Delayed neutron precursor data";
  Data_K data_K "Kinetics data";
  MSRE.Data.Geometry geometry "Plant geometry and nodalization";

  final parameter Integer nC=Medium_fuel.nC "# of delayed neutron precursor groups";
  final parameter Integer nV_core=geometry.nV_core "# of reactor core cells";
  final parameter Integer nCh=geometry.nRings*geometry.nAxial "# of fuel channel cells";

  /* ================================================================
     Operating point and transient control
     ================================================================ */
  parameter SI.Power Q_fission_start=100 "Fission power at the initial steady state";
  parameter SI.Temperature T_start=geometry.T_zeroPower "Initial fuel salt temperature";
  parameter SI.Time t_null=0
    "Null transient duration; the neutron balance is released and Beta_eff frozen at this time";
  parameter Boolean use_servoControl=false
    "=true: the ideal flux servo controller of the zero-power tests holds the power constant";
  parameter Real f_graphiteHeating=0
    "Fraction of the fission power deposited directly in the graphite (0 in the paper)";
  input SIadd.NonDim rho_external=0
    "Externally imposed reactivity (control rods); zero in all three benchmark tests";

  parameter Boolean use_rotorDynamics=true
    "=true: the fuel pump shaft speed is solved from the rotor angular momentum equation and N_pump is a motor torque demand; =false: N_pump is the shaft speed itself";

  parameter SI.MassFlowRate m_flow_start=0 "Initial fuel salt mass flow rate"
    annotation (Dialog(tab="Initialization"));
  parameter Real N_pump_start(unit="1/min") = 0
    "Initial fuel pump shaft speed; used only with use_rotorDynamics=true"
    annotation (Dialog(tab="Initialization"));
  parameter SIadd.ExtraProperty C_start[nC]=zeros(nC)
    "Initial precursor concentration everywhere in the loop"
    annotation (Dialog(tab="Initialization"));

  parameter SI.MassFlowRate m_flow_coolant=geometry.m_flow_coolant_nominal
    "Secondary coolant salt mass flow rate";
  parameter SI.Temperature T_coolant_start=894
    "Secondary coolant salt temperature at the heat exchanger inlet at t = 0";

  /* ================================================================
     Power and flux shapes (paper Section 3.2)
     ================================================================ */
  final parameter SI.Volume Vs_cells[nV_core]=MSRE.Functions.coreCellVolumes(
      geometry.nRings,
      geometry.nAxial,
      geometry.nChannels,
      geometry.A_channel,
      geometry.H_channels,
      geometry.V_lowerPlenum/geometry.nLP,
      geometry.V_upperPlenum/geometry.nUP) "Volume of each core cell";
  final parameter SIadd.NonDim SF_core[nV_core]=MSRE.Functions.corePowerShape(
      geometry.nRings,
      geometry.nAxial,
      geometry.nChannels,
      geometry.f_radial,
      geometry.A_channel,
      geometry.H_channels,
      geometry.L_lowerPlenum/geometry.nLP,
      geometry.L_upperPlenum/geometry.nUP,
      geometry.V_lowerPlenum/geometry.nLP,
      geometry.V_upperPlenum/geometry.nUP,
      geometry.f_axialExtrapolation) "Fission source fraction of each core cell";
  final parameter SIadd.NonDim phis_core[nV_core]={SF_core[i]*sum(Vs_cells)/Vs_cells[i] for i in
          1:nV_core} "Normalized neutron flux of each core cell";
  final parameter SIadd.NonDim phis_adjoint[nV_core]=fill(1, nV_core)
    "Neutron importance of each core cell (unity, as assumed throughout the paper)";

  /* ================================================================
     System settings
     ================================================================ */
  inner TRANSFORM.Fluid.SystemTF systemTF(
    p_start=geometry.p_system,
    T_start=T_start,
    allowFlowReversal=true,
    energyDynamics=TRANSFORM.Types.Dynamics.FixedInitial,
    momentumDynamics=TRANSFORM.Types.Dynamics.DynamicFreeInitial)
    annotation (Placement(transformation(extent={{-100,80},{-80,100}})));

  /* ================================================================
     Reactor vessel
     ================================================================ */
  MSRE.Components.ReactorCore core(
    redeclare package Medium = Medium_fuel,
    nRings=geometry.nRings,
    nAxial=geometry.nAxial,
    nLP=geometry.nLP,
    nUP=geometry.nUP,
    nR_graphite=geometry.nR_graphite,
    iLP_core=geometry.iLP_core,
    iUP_core=geometry.iUP_core,
    nChannels=geometry.nChannels,
    nChannels_total=geometry.nChannels_total,
    H_channels=geometry.H_channels,
    A_channel=geometry.A_channel,
    Dh_channel=geometry.Dh_channel,
    r_graphite_inner=geometry.r_graphite_inner,
    r_graphite_outer=geometry.r_graphite_outer,
    dz_channels=geometry.dz_channels,
    V_lowerPlenum=geometry.V_lowerPlenum,
    L_lowerPlenum=geometry.L_lowerPlenum,
    dz_lowerPlenum=geometry.dz_lowerPlenum,
    V_upperPlenum=geometry.V_upperPlenum,
    L_upperPlenum=geometry.L_upperPlenum,
    dz_upperPlenum=geometry.dz_upperPlenum,
    K_channelInlet=geometry.K_channelInlet,
    K_channelExit=geometry.K_channelExit,
    lambdas=data_PG.lambdas,
    f_graphiteHeating=f_graphiteHeating,
    Qs_core=kinetics.Qs,
    mC_sources_core=kinetics.mC_sources,
    p_start=geometry.p_system,
    T_start=T_start,
    C_start=C_start,
    m_flow_start=m_flow_start) "Reactor vessel internals"
    annotation (Placement(transformation(extent={{-20,-40},{0,-20}})));

  MSRE.Components.SaltPipe downcomer(
    redeclare package Medium = Medium_fuel,
    nV=geometry.nDC,
    V=geometry.V_downcomer,
    length=geometry.L_downcomer,
    dheight=geometry.dz_downcomer,
    dimension=geometry.Dh_downcomer,
    lambdas=data_PG.lambdas,
    p_a_start=geometry.p_system,
    T_a_start=T_start,
    C_a_start=C_start,
    m_flow_a_start=m_flow_start,
    exposeState_a=true,
    exposeState_b=false) "Flow distributor and downcomer annulus"
    annotation (Placement(transformation(extent={{-60,-40},{-40,-20}})));

  /* ================================================================
     External loop
     ================================================================ */
  MSRE.Components.SaltPipe outletPipe(
    redeclare package Medium = Medium_fuel,
    nV=geometry.nOutletPipe,
    V=pi/4*geometry.D_pipe^2*geometry.L_outletPipe,
    length=geometry.L_outletPipe,
    dheight=geometry.dz_outletPipe,
    dimension=geometry.D_pipe,
    Ks=cat(
        1,
        zeros(geometry.nOutletPipe - 1),
        {geometry.K_pumpInlet}),
    lambdas=data_PG.lambdas,
    p_a_start=geometry.p_system,
    T_a_start=T_start,
    C_a_start=C_start,
    m_flow_a_start=m_flow_start,
    exposeState_a=true,
    exposeState_b=false) "Reactor outlet riser to the fuel pump"
    annotation (Placement(transformation(extent={{20,-40},{40,-20}})));

  MSRE.Components.SaltPipe pumpBowl(
    redeclare package Medium = Medium_fuel,
    nV=geometry.nPumpBowl,
    V=geometry.V_pumpBowl,
    length=geometry.L_pumpBowl,
    dheight=geometry.dz_pumpBowl,
    lambdas=data_PG.lambdas,
    p_a_start=geometry.p_system,
    T_a_start=T_start,
    C_a_start=C_start,
    m_flow_a_start=m_flow_start,
    exposeState_a=false,
    exposeState_b=false) "Fuel pump bowl and volute"
    annotation (Placement(transformation(extent={{54,-40},{74,-20}})));

  TRANSFORM.Fluid.BoundaryConditions.Boundary_pT expansionTank(
    redeclare package Medium = Medium_fuel,
    nPorts=1,
    p=geometry.p_system,
    T=T_start,
    C=C_start)
    "Pump bowl gas space: sets the system pressure and takes up the thermal expansion"
    annotation (Placement(transformation(extent={{68,-70},{48,-50}})));

  MSRE.Components.FuelPump pump(
    redeclare package Medium = Medium_fuel,
    dp_nominal=geometry.dp_pump_nominal,
    m_flow_nominal=geometry.m_flow_nominal,
    d_nominal=density_ref,
    N_nominal=geometry.N_pump_nominal,
    headRatio_shutoff=geometry.headRatio_shutoff,
    eta_is=geometry.eta_pump,
    use_rotorDynamics=use_rotorDynamics,
    tau_shaft=geometry.tau_pump_shaft,
    N_start=N_pump_start,
    m_flow_start=m_flow_start,
    use_speedInput=true) "Fuel salt circulation pump"
    annotation (Placement(transformation(extent={{74,0},{54,20}})));

  MSRE.Components.SaltPipe pumpToHX(
    redeclare package Medium = Medium_fuel,
    nV=geometry.nPumpToHX,
    V=pi/4*geometry.D_pipe^2*geometry.L_pumpToHX,
    length=geometry.L_pumpToHX,
    dheight=geometry.dz_pumpToHX,
    dimension=geometry.D_pipe,
    Ks=cat(
        1,
        {geometry.K_pumpExit},
        zeros(geometry.nPumpToHX - 1)),
    lambdas=data_PG.lambdas,
    p_a_start=geometry.p_system,
    T_a_start=T_start,
    C_a_start=C_start,
    m_flow_a_start=m_flow_start,
    exposeState_a=true,
    exposeState_b=false) "Pump discharge pipe"
    annotation (Placement(transformation(extent={{40,0},{20,20}})));

  MSRE.Components.SaltPipe hxToVessel(
    redeclare package Medium = Medium_fuel,
    nV=geometry.nHXToVessel,
    V=pi/4*geometry.D_pipe^2*geometry.L_hxToVessel,
    length=geometry.L_hxToVessel,
    dheight=geometry.dz_hxToVessel,
    dimension=geometry.D_pipe,
    Ks=cat(
        1,
        {geometry.K_loop},
        zeros(geometry.nHXToVessel - 1)),
    lambdas=data_PG.lambdas,
    p_a_start=geometry.p_system,
    T_a_start=T_start,
    C_a_start=C_start,
    m_flow_a_start=m_flow_start,
    exposeState_a=true,
    exposeState_b=false) "Heat exchanger outlet pipe back to the reactor vessel inlet"
    annotation (Placement(transformation(extent={{-40,0},{-60,20}})));

  /* ================================================================
     Heat exchanger
     ================================================================ */
  TRANSFORM.HeatExchangers.GenericDistributed_HX hx(
    redeclare package Medium_shell = Medium_fuel,
    redeclare package Medium_tube = Medium_coolant,
    redeclare package Material_tubeWall = TRANSFORM.Media.Solids.AlloyN,
    counterCurrent=true,
    redeclare model HeatTransfer_shell = MSRE.ClosureRelations.Nus_MoltenSalt (
        f_enhance=geometry.f_shellHT,
        Nu_floor=geometry.Nu_floor_shell,
        L_char=fill(
            geometry.D_tube_outer,
            geometry.nHX,
            1)),
    redeclare model HeatTransfer_tube = MSRE.ClosureRelations.Nus_MoltenSalt,
    redeclare model InternalTraceGen_shell =
        TRANSFORM.Fluid.ClosureRelations.InternalTraceGeneration.Models.DistributedVolume_Trace_1D.GenericTraceGeneration
        (mC_gens=mC_gens_hxShell),
    redeclare model Geometry =
        TRANSFORM.Fluid.ClosureRelations.Geometry.Models.DistributedVolume_1D.HeatExchanger.StraightPipeHX
        (
        nV=geometry.nHX,
        nTubes=geometry.nTubes,
        nR=2,
        crossArea_shell=geometry.A_shell,
        dimension_shell=geometry.Dh_shell,
        length_shell=geometry.L_shell,
        dheight_shell=geometry.dz_hxShell,
        surfaceArea_shell={geometry.f_area_hx*pi*(geometry.D_tube_inner + 2*geometry.th_tube)
            *geometry.L_tube*geometry.nTubes},
        dimension_tube=geometry.D_tube_inner,
        length_tube=geometry.L_tube,
        dheight_tube=0,
        surfaceArea_tube={geometry.f_area_hx*pi*geometry.D_tube_inner*geometry.L_tube},
        th_wall=geometry.th_tube),
    p_a_start_shell=geometry.p_system,
    T_a_start_shell=T_start,
    T_b_start_shell=T_start,
    C_a_start_shell=C_start,
    m_flow_a_start_shell=m_flow_start,
    p_a_start_tube=2e5,
    T_a_start_tube=T_coolant_start,
    T_b_start_tube=T_coolant_start,
    m_flow_a_start_tube=m_flow_coolant,
    exposeState_a_shell=true,
    exposeState_b_shell=false,
    exposeState_a_tube=true,
    exposeState_b_tube=false) "Fuel to coolant salt heat exchanger, fuel on the shell side"
    annotation (Placement(transformation(extent={{-10,0},{10,20}})));

  SIadd.ExtraPropertyFlowRate mC_gens_hxShell[geometry.nHX,nC]={{-data_PG.lambdas[j]*hx.shell.mCs[
      i, j] for j in 1:nC} for i in 1:geometry.nHX}
    "Precursor decay inside the heat exchanger shell";

  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T coolantInlet(
    redeclare package Medium = Medium_coolant,
    nPorts=1,
    use_m_flow_in=false,
    m_flow=m_flow_coolant,
    use_T_in=true,
    T=T_coolant_start) "Coolant salt entering the heat exchanger tubes"
    annotation (Placement(transformation(extent={{60,40},{40,60}})));
  TRANSFORM.Fluid.BoundaryConditions.Boundary_pT coolantOutlet(
    redeclare package Medium = Medium_coolant,
    nPorts=1,
    p=2e5,
    T=T_coolant_start) "Coolant salt leaving the heat exchanger tubes"
    annotation (Placement(transformation(extent={{-60,40},{-40,60}})));

  /* ================================================================
     Reactor kinetics
     ================================================================ */
  MSRE.Nuclear.PointKinetics_DNPtransport kinetics(
    redeclare record Data = Data_PG,
    nV=nV_core,
    Lambda=data_K.Lambda,
    Q_fission_start=Q_fission_start,
    t_null=t_null,
    use_servoControl=use_servoControl,
    mCs=core.mCs_core,
    Vs=core.Vs_core,
    SF=SF_core,
    phis=phis_core,
    phis_adjoint=phis_adjoint,
    nFeedback=2,
    alphas_feedback={data_K.alpha_fuel,data_K.alpha_graphite},
    vals_feedback={T_fuel_effective,T_graphite_effective},
    use_frozenReference=true,
    vals_feedback_reference={T_start,T_start},
    rho_input=rho_external) "Modified point kinetics with precursor transport"
    annotation (Placement(transformation(extent={{-70,60},{-50,80}})));

  /* ================================================================
     Control inputs
     ================================================================ */
  Modelica.Blocks.Interfaces.RealInput N_pump(unit="1/min") "Fuel pump speed [rpm]"
    annotation (Placement(transformation(extent={{120,10},{100,30}})));
  Modelica.Blocks.Interfaces.RealInput T_coolant_in(unit="K")
    "Coolant salt temperature at the heat exchanger inlet"
    annotation (Placement(transformation(extent={{120,60},{100,80}})));

  /* ================================================================
     Reported quantities
     ================================================================ */
  final parameter SI.Density density_ref=Medium_fuel.density(Medium_fuel.setState_pTX(
      geometry.p_system,
      T_start,
      Medium_fuel.X_default)) "Fuel salt density used to report the transit times";

  SI.Temperature T_fuel_effective=sum({phis_core[i]*Vs_cells[i]*core.Ts_fuel_core[i] for i in
      1:nV_core})/sum({phis_core[i]*Vs_cells[i] for i in 1:nV_core})
    "Flux weighted average fuel salt temperature of the core";
  SI.Temperature T_graphite_effective=sum({phis_core[i]*Vs_cells[i]*core.Ts_graphite_cells[i]
      for i in 1:nCh})/sum({phis_core[i]*Vs_cells[i] for i in 1:nCh})
    "Flux weighted average graphite temperature";

  SI.Time t_rel=time - t_null "Time since the start of the transient";
  SI.MassFlowRate m_flow_fuel=core.port_a.m_flow "Fuel salt mass flow rate through the core";
  SIadd.NonDim m_flow_fuel_norm=m_flow_fuel/geometry.m_flow_nominal
    "Fuel salt mass flow rate normalized to the rated value";
  SI.Power Q_core=kinetics.Q_fission "Core fission power";
  Real rho_CR_pcm=kinetics.rho_servo_pcm
    "Control rod reactivity required to hold the reactor critical [pcm]";
  SI.Temperature T_coreInlet=core.lowerPlenum.Ts[1] "Fuel salt temperature at the core inlet";
  SI.Temperature T_coreOutlet=core.upperPlenum.Ts[geometry.nUP]
    "Fuel salt temperature at the core outlet";
  SIadd.NonDim Beta_eff=kinetics.Beta_eff "Effective delayed neutron fraction";
  SI.Time tau_core=geometry.V_core*density_ref/max(abs(m_flow_fuel), 1e-3)
    "Fuel salt transit time through the reactor core";
  SI.Time tau_loop=geometry.V_loop*density_ref/max(abs(m_flow_fuel), 1e-3)
    "Fuel salt transit time through the external loop";
  SI.Time tau_system=tau_core + tau_loop "Fuel salt transit time around the whole system";

  /* Hydraulic consistency, reported so that MSRE.Verification.Steady_LoopBalance can assert
     on it without reaching inside the component hierarchy. */
  Real N_pump_actual(unit="1/min") = pump.N "Actual fuel pump shaft speed";
  SI.MassFlowRate m_flow_pump=pump.m_flow "Mass flow rate through the fuel pump";
  SI.MassFlowRate err_loopMassBalance=m_flow_pump - m_flow_fuel
    "Difference between the pump and the core flow, zero at steady state";
  SIadd.NonDim err_flowSplit=core.err_flowSplit
    "Largest relative departure of any ring from an even flow split";
  SIadd.NonDim f_flowSplit[geometry.nRings]=core.f_flowSplit
    "Fraction of the channel flow carried by each ring";
  SI.MassFlowRate m_flows_rings[geometry.nRings]=core.m_flows_rings
    "Mass flow rate through each of the parallel fuel channel rings";
  SIadd.NonDim Re_rings[geometry.nRings]=core.Re_rings
    "Channel Reynolds number of each ring";
  SI.PressureDifference dp_pump=pump.dp "Fuel pump pressure rise";

equation
  connect(N_pump, pump.N_in)
    annotation (Line(points={{110,20},{64,20},{64,17}}, color={0,0,127}));
  connect(T_coolant_in, coolantInlet.T_in)
    annotation (Line(points={{110,70},{80,70},{80,54},{62,54}}, color={0,0,127}));

  /* Primary loop: downcomer -> core -> outlet riser -> pump bowl -> pump ->
     heat exchanger shell -> return pipe -> downcomer */
  connect(downcomer.port_b, core.port_a)
    annotation (Line(points={{-40,-30},{-20,-30}}, color={0,127,255}));
  connect(core.port_b, outletPipe.port_a)
    annotation (Line(points={{0,-30},{20,-30}}, color={0,127,255}));
  connect(outletPipe.port_b, pumpBowl.port_a)
    annotation (Line(points={{40,-30},{54,-30}}, color={0,127,255}));
  connect(expansionTank.ports[1], pumpBowl.port_a)
    annotation (Line(points={{48,-60},{48,-30},{54,-30}}, color={0,127,255}));
  connect(pumpBowl.port_b, pump.port_a)
    annotation (Line(points={{74,-30},{84,-30},{84,10},{74,10}}, color={0,127,255}));
  connect(pump.port_b, pumpToHX.port_a)
    annotation (Line(points={{54,10},{40,10}}, color={0,127,255}));
  connect(pumpToHX.port_b, hx.port_a_shell)
    annotation (Line(points={{20,10},{10,10}}, color={0,127,255}));
  connect(hx.port_b_shell, hxToVessel.port_a)
    annotation (Line(points={{-10,10},{-40,10}}, color={0,127,255}));
  connect(hxToVessel.port_b, downcomer.port_a)
    annotation (Line(points={{-60,10},{-80,10},{-80,-30},{-60,-30}}, color={0,127,255}));

  /* Secondary side boundary conditions */
  connect(coolantInlet.ports[1], hx.port_a_tube)
    annotation (Line(points={{40,50},{20,50},{20,5},{10,5}}, color={0,127,255}));
  connect(hx.port_b_tube, coolantOutlet.ports[1])
    annotation (Line(points={{-10,5},{-20,5},{-20,50},{-40,50}}, color={0,127,255}));

  annotation (
    defaultComponentName="msre",
    Icon(coordinateSystem(preserveAspectRatio=false), graphics={Rectangle(
          extent={{-100,100},{100,-100}},
          lineColor={0,0,0},
          fillColor={215,230,240},
          fillPattern=FillPattern.Solid), Text(
          extent={{-90,40},{90,-40}},
          lineColor={0,0,0},
          textString="MSRE")}),
    Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{120,100}})),
    Documentation(info="<html>
<h4>This model is not meant to be simulated on its own</h4>
<p>It is the plant, not an experiment. Two input connectors, <code>N_pump</code> and
<code>T_coolant_in</code>, are left open for an experiment model to drive. Translating this
model directly leaves them unconnected, so the fuel pump receives a demand of zero and the loop
never starts, and the flow variables of the pump are then initialized from a guess that no
longer matches any test. Simulate one of
<a href=\"modelica://MSRE.Experiments\">MSRE.Experiments</a> or
<a href=\"modelica://MSRE.Verification.Steady_LoopBalance\">Steady_LoopBalance</a> instead;
they supply both inputs and set the initialization to match the transient they run.</p>

<h4>Nodalization</h4>
<p>The loop follows paper Fig. 2:</p>
<pre>
  downcomer (10) -&gt; lower plenum (3) -&gt; 15 x 20 fuel channels -&gt; upper plenum (3)
       ^                                                                |
       |                                                                v
  return pipe (6) &lt;- HX shell (10) &lt;- discharge pipe (4) &lt;- pump &lt;- pump bowl (2) &lt;- outlet riser (4)
</pre>
<p>which gives the 300 core channel cells of the MARS input plus the plena, the piping and the
heat exchanger. The secondary side is cut at the heat exchanger exactly as in the paper: the
coolant salt flow rate and inlet temperature are imposed at the tube inlet and the pressure at
the tube outlet, so the radiator is not modelled.</p>

<h4>Delayed neutron precursor transport</h4>
<p>The six precursor groups are trace substances of <code>Medium_fuel</code>. Every fuel salt
component is a <a href=\"modelica://MSRE.Components.SaltPipe\">SaltPipe</a>, or in the core a
<a href=\"modelica://MSRE.Components.CoreChannel\">CoreChannel</a>, and each applies its local
decay term; the fission production term is supplied by the kinetics model to the core cells
only. The heat-exchanger shell gets its decay term through <code>mC_gens_hxShell</code>.
Precursors are therefore transported and decay over the whole primary system, which is what
paper Eq. 3 requires and what distinguishes this formulation from a core-plus-single-loop
model.</p>

<h4>State exposure around the loop</h4>
<p>Each junction of the loop has exactly one component that defines the thermodynamic state,
which is what makes the closed loop well posed:</p>
<ul>
<li>the plena expose their state at the core junctions and the parallel channel groups do not;</li>
<li>the pump and the pump bowl expose no state at the pump suction node, where the expansion
tank sets the pressure instead. This is the model of the paper, in which the expansion tank is
a time-dependent volume that defines the system pressure;</li>
<li>everywhere else a pipe exposes its state at <code>port_a</code> and not at
<code>port_b</code>.</li>
</ul>

<h4>Reported variables</h4>
<ul>
<li><code>rho_CR_pcm</code> - control rod reactivity in pcm, the measured quantity of the two
pump tests (paper Figs. 5, 6 and 8).</li>
<li><code>m_flow_fuel_norm</code> - normalized fuel salt flow rate (paper Figs. 4 and 7).</li>
<li><code>Q_core</code>, <code>T_coreOutlet</code> - core power and outlet temperature
(paper Figs. 9 and 11).</li>
<li><code>tau_core</code>, <code>tau_loop</code> - fuel salt transit times, to be compared with
the 9.56 s and 16.14 s of the paper and to be fed into
<a href=\"modelica://MSRE.Functions.driftReactivity\">driftReactivity</a>.</li>
<li><code>Beta_eff</code> - effective delayed neutron fraction from paper Eq. 6.</li>
</ul>
</html>"));
end PrimarySystem;
