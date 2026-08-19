within MSRE.Components;
model ReactorCore
  "MSRE reactor core: lower plenum, nRings parallel graphite-moderated channel groups, upper plenum"

  import TRANSFORM;
  outer TRANSFORM.Fluid.SystemTF systemTF;

  replaceable package Medium = Modelica.Media.Interfaces.PartialMedium
    "Fuel salt medium" annotation (choicesAllMatching=true);
  replaceable package Material = TRANSFORM.Media.Solids.Graphite.Graphite_1
    constrainedby TRANSFORM.Media.Interfaces.Solids.PartialAlloy
    "Graphite moderator material" annotation (choicesAllMatching=true);

  /* ---------------- Nodalization and geometry ---------------- */
  parameter Integer nRings=15 "# of concentric radial rings";
  parameter Integer nAxial=20 "# of axial nodes per fuel channel";
  parameter Integer nLP=3 "# of lower plenum nodes";
  parameter Integer nUP=3 "# of upper plenum nodes";
  parameter Integer nR_graphite=3 "# of radial nodes in the graphite";
  parameter Integer iLP_core=nLP "Lower plenum node that belongs to the reactor core";
  parameter Integer iUP_core=1 "Upper plenum node that belongs to the reactor core";

  parameter Real nChannels[nRings]=fill(76, nRings) "# of fuel channels per ring";
  parameter Real nChannels_total=sum(nChannels) "Total # of fuel channels";
  parameter SI.Length H_channels=1.6256 "Active channel height";
  parameter SI.Area A_channel=2.875244e-4 "Flow area of a single fuel channel";
  parameter SI.Length Dh_channel=0.015851 "Hydraulic diameter of a single fuel channel";
  parameter SI.Length r_graphite_inner=0.011548
    "Inner radius of the equivalent graphite annulus";
  parameter SI.Length r_graphite_outer=0.021765
    "Outer radius of the equivalent graphite annulus";
  parameter SI.Length dz_channels=H_channels "Elevation rise across the fuel channels";

  parameter SI.Volume V_lowerPlenum=0.346598 "Lower plenum fuel salt volume (ORNL reference, 12.24 ft3); overridden from Data.Geometry by PrimarySystem";
  parameter SI.Length L_lowerPlenum=0.30 "Lower plenum height";
  parameter SI.Length dz_lowerPlenum=L_lowerPlenum "Elevation rise across the lower plenum";
  parameter SI.Volume V_upperPlenum=0.321113 "Upper plenum fuel salt volume (ORNL reference, 11.34 ft3); overridden from Data.Geometry by PrimarySystem";
  parameter SI.Length L_upperPlenum=0.30 "Upper plenum height";
  parameter SI.Length dz_upperPlenum=L_upperPlenum "Elevation rise across the upper plenum";

  /* The plenum node that belongs to the reactor core is a thin slice at the core boundary, so
     the plena are nodalized non-uniformly: the core node takes these volumes and the remaining
     nodes share what is left equally. */
  parameter SI.Volume V_lowerPlenum_core=V_lowerPlenum/nLP
    "Fuel salt volume of the lower plenum node that belongs to the core";
  parameter SI.Volume V_upperPlenum_core=V_upperPlenum/nUP
    "Fuel salt volume of the upper plenum node that belongs to the core";

  final parameter SI.Volume Vs_lowerPlenum[nLP]={if i == iLP_core then V_lowerPlenum_core
       else (V_lowerPlenum - V_lowerPlenum_core)/(nLP - 1) for i in 1:nLP}
    "Fuel salt volume of each lower plenum node";
  final parameter SI.Volume Vs_upperPlenum[nUP]={if i == iUP_core then V_upperPlenum_core
       else (V_upperPlenum - V_upperPlenum_core)/(nUP - 1) for i in 1:nUP}
    "Fuel salt volume of each upper plenum node";

  /* ---------------- Ring form losses ---------------- */
  parameter Real K_channelInlet[nRings]=zeros(nRings)
    "Form loss coefficient at the inlet of each ring, per channel";
  parameter Real K_channelExit[nRings]=zeros(nRings)
    "Form loss coefficient at the exit of each ring, per channel";

  final parameter Integer nCh=nRings*nAxial "# of channel cells";
  final parameter Integer nV_core=nCh + 2
    "# of core cells seen by the kinetics: channel cells plus one lower and one upper plenum cell";

  parameter SIadd.InverseTime lambdas[Medium.nC]=zeros(Medium.nC)
    "Decay constant of each precursor group";
  parameter Real f_graphiteHeating=0
    "Fraction of the fission power deposited directly in the graphite (0 in the paper)";

  /* ---------------- Inputs from the kinetics ---------------- */
  input SI.HeatFlowRate Qs_core[nV_core]=zeros(nV_core)
    "Fission power generated in each core cell" annotation (Dialog(group="Inputs"));
  input SIadd.ExtraPropertyFlowRate mC_sources_core[nV_core,Medium.nC]=zeros(nV_core,
      Medium.nC) "Precursor production by fission in each core cell"
    annotation (Dialog(group="Inputs"));

  /* ---------------- Initialization ---------------- */
  parameter SI.AbsolutePressure p_start=1.5e5 "Pressure"
    annotation (Dialog(tab="Initialization"));
  parameter SI.Temperature T_start=908 "Fuel salt and graphite temperature"
    annotation (Dialog(tab="Initialization"));
  parameter SIadd.ExtraProperty C_start[Medium.nC]=zeros(Medium.nC)
    "Precursor concentration" annotation (Dialog(tab="Initialization"));
  parameter SI.MassFlowRate m_flow_start=0 "Total core mass flow rate"
    annotation (Dialog(tab="Initialization"));

  /* ---------------- Ports ---------------- */
  TRANSFORM.Fluid.Interfaces.FluidPort_Flow port_a(redeclare package Medium = Medium)
    "Inlet, from the downcomer"
    annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
  TRANSFORM.Fluid.Interfaces.FluidPort_Flow port_b(redeclare package Medium = Medium)
    "Outlet, to the reactor outlet pipe"
    annotation (Placement(transformation(extent={{90,-10},{110,10}})));

  /* ---------------- Distribution of the kinetics inputs ---------------- */
  SI.HeatFlowRate Qs_channels[nRings,nAxial] "Fission power to the fuel salt of each channel cell";
  SI.HeatFlowRate Qs_channels_graphite[nRings,nAxial]
    "Fission power deposited directly in the graphite of each channel cell";
  SIadd.ExtraPropertyFlowRate mC_sources_channels[nRings,nAxial,Medium.nC]
    "Precursor production in each channel cell";
  SI.HeatFlowRate Qs_LP[nLP] "Fission power to each lower plenum node";
  SI.HeatFlowRate Qs_UP[nUP] "Fission power to each upper plenum node";
  SIadd.ExtraPropertyFlowRate mC_sources_LP[nLP,Medium.nC]
    "Precursor production in each lower plenum node";
  SIadd.ExtraPropertyFlowRate mC_sources_UP[nUP,Medium.nC]
    "Precursor production in each upper plenum node";

  /* ---------------- Quantities exported to the kinetics ---------------- */
  SIadd.ExtraPropertyExtrinsic mCs_core[nV_core,Medium.nC]
    "# of precursors of each group in each core cell";
  SI.Volume Vs_core[nV_core] "Fuel salt volume of each core cell";
  SI.Temperature Ts_fuel_core[nV_core] "Fuel salt temperature of each core cell";
  SI.Temperature Ts_graphite_cells[nCh] "Graphite temperature of each channel cell";
  SI.Volume Vs_channelCells[nCh] "Fuel salt volume of each channel cell";
  SI.Mass m_graphite=sum(channels.m_graphite) "Total graphite mass in the active core";

  /* ---------------- Flow split across the parallel rings ---------------- */
  SI.MassFlowRate m_flow_inlet=port_a.m_flow "Mass flow rate entering the reactor vessel";
  SI.MassFlowRate m_flows_rings[nRings]={channels[r].m_flow_ring for r in 1:nRings}
    "Mass flow rate through each ring";
  SI.MassFlowRate m_flow_channels=sum(m_flows_rings)
    "Mass flow rate through the channel region, summed over all rings";
  SIadd.NonDim f_flowSplit[nRings]={m_flows_rings[r]/max(abs(m_flow_channels), 1e-9) for r in
          1:nRings} "Fraction of the channel-region flow carried by each ring";
  final parameter SIadd.NonDim f_flowSplit_uniform=1/nRings
    "Flow fraction each ring would carry if the split were exactly even";
  SIadd.NonDim err_flowSplit=max({abs(f_flowSplit[r] - f_flowSplit_uniform) for r in 1:nRings})
      /f_flowSplit_uniform "Largest relative departure of any ring from an even flow split";
  SIadd.NonDim Re_rings[nRings]={channels[r].Re for r in 1:nRings}
    "Channel Reynolds number of each ring";

  /* ---------------- Components ---------------- */
  MSRE.Components.SaltPipe lowerPlenum(
    redeclare package Medium = Medium,
    nV=nLP,
    V=V_lowerPlenum,
    Vs_nodes=Vs_lowerPlenum,
    length=L_lowerPlenum,
    dheight=dz_lowerPlenum,
    lambdas=lambdas,
    mC_sources=mC_sources_LP,
    Q_gens=Qs_LP,
    p_a_start=p_start,
    T_a_start=T_start,
    T_b_start=T_start,
    C_a_start=C_start,
    m_flow_a_start=m_flow_start,
    exposeState_a=true,
    exposeState_b=true) "Lower plenum; its last node belongs to the reactor core"
    annotation (Placement(transformation(extent={{-70,-10},{-50,10}})));

  MSRE.Components.CoreChannel channels[nRings](
    redeclare each package Medium = Medium,
    redeclare each package Material = Material,
    nParallel=nChannels,
    each nV=nAxial,
    each nR=nR_graphite,
    each length=H_channels,
    each dheight=dz_channels,
    each crossArea=A_channel,
    each dimension=Dh_channel,
    each r_graphite_inner=r_graphite_inner,
    each r_graphite_outer=r_graphite_outer,
    Q_gens=Qs_channels,
    Q_gens_graphite=Qs_channels_graphite,
    mC_sources=mC_sources_channels,
    K_inlet=K_channelInlet,
    K_exit=K_channelExit,
    each lambdas=lambdas,
    each p_a_start=p_start,
    each T_a_start=T_start,
    each T_b_start=T_start,
    each C_a_start=C_start,
    each m_flow_a_start=m_flow_start/nChannels_total,
    each exposeState_a=false,
    each exposeState_b=false) "One group of fuel channels per radial ring"
    annotation (Placement(transformation(extent={{-10,-10},{10,10}})));

  MSRE.Components.SaltPipe upperPlenum(
    redeclare package Medium = Medium,
    nV=nUP,
    V=V_upperPlenum,
    Vs_nodes=Vs_upperPlenum,
    length=L_upperPlenum,
    dheight=dz_upperPlenum,
    lambdas=lambdas,
    mC_sources=mC_sources_UP,
    Q_gens=Qs_UP,
    p_a_start=p_start,
    T_a_start=T_start,
    T_b_start=T_start,
    C_a_start=C_start,
    m_flow_a_start=m_flow_start,
    exposeState_a=true,
    exposeState_b=false) "Upper plenum; its first node belongs to the reactor core"
    annotation (Placement(transformation(extent={{50,-10},{70,10}})));

equation
  /* Scatter the kinetics results onto the components, and gather the core cell arrays back.
     Channel cell i corresponds to ring r = div(i-1,nAxial)+1 and axial node k = i-r*nAxial. */
  for r in 1:nRings loop
    for k in 1:nAxial loop
      Qs_channels[r, k] = Qs_core[(r - 1)*nAxial + k]*(1 - f_graphiteHeating);
      Qs_channels_graphite[r, k] = Qs_core[(r - 1)*nAxial + k]*f_graphiteHeating;
      mC_sources_channels[r, k, :] = mC_sources_core[(r - 1)*nAxial + k, :];
      mCs_core[(r - 1)*nAxial + k, :] = channels[r].mCs[k, :];
      Vs_core[(r - 1)*nAxial + k] = channels[r].Vs[k];
      Ts_fuel_core[(r - 1)*nAxial + k] = channels[r].Ts_fuel[k];
      Ts_graphite_cells[(r - 1)*nAxial + k] = channels[r].Ts_graphite[k];
      Vs_channelCells[(r - 1)*nAxial + k] = channels[r].Vs[k];
    end for;
  end for;

  for i in 1:nLP loop
    Qs_LP[i] = if i == iLP_core then Qs_core[nCh + 1] else 0;
    mC_sources_LP[i, :] = if i == iLP_core then mC_sources_core[nCh + 1, :] else
      zeros(Medium.nC);
  end for;
  for i in 1:nUP loop
    Qs_UP[i] = if i == iUP_core then Qs_core[nCh + 2] else 0;
    mC_sources_UP[i, :] = if i == iUP_core then mC_sources_core[nCh + 2, :] else
      zeros(Medium.nC);
  end for;

  mCs_core[nCh + 1, :] = lowerPlenum.mCs[iLP_core, :];
  Vs_core[nCh + 1] = lowerPlenum.Vs[iLP_core];
  Ts_fuel_core[nCh + 1] = lowerPlenum.Ts[iLP_core];
  mCs_core[nCh + 2, :] = upperPlenum.mCs[iUP_core, :];
  Vs_core[nCh + 2] = upperPlenum.Vs[iUP_core];
  Ts_fuel_core[nCh + 2] = upperPlenum.Ts[iUP_core];

  connect(port_a, lowerPlenum.port_a)
    annotation (Line(points={{-100,0},{-70,0}}, color={0,127,255}));
  for r in 1:nRings loop
    connect(lowerPlenum.port_b, channels[r].port_a)
      annotation (Line(points={{-50,0},{-10,0}}, color={0,127,255}));
    connect(channels[r].port_b, upperPlenum.port_a)
      annotation (Line(points={{10,0},{50,0}}, color={0,127,255}));
  end for;
  connect(upperPlenum.port_b, port_b)
    annotation (Line(points={{70,0},{100,0}}, color={0,127,255}));

  annotation (
    defaultComponentName="core",
    Icon(coordinateSystem(preserveAspectRatio=false), graphics={
        Rectangle(
          extent={{-80,80},{80,-80}},
          lineColor={0,0,0},
          fillColor={95,95,95},
          fillPattern=FillPattern.Backward),
        Rectangle(
          extent={{-50,60},{-30,-60}},
          lineColor={0,0,0},
          fillColor={0,127,255},
          fillPattern=FillPattern.VerticalCylinder),
        Rectangle(
          extent={{-10,60},{10,-60}},
          lineColor={0,0,0},
          fillColor={0,127,255},
          fillPattern=FillPattern.VerticalCylinder),
        Rectangle(
          extent={{30,60},{50,-60}},
          lineColor={0,0,0},
          fillColor={0,127,255},
          fillPattern=FillPattern.VerticalCylinder),
        Text(
          extent={{-149,-90},{151,-130}},
          lineColor={0,0,255},
          textString="%name")}),
    Diagram(coordinateSystem(preserveAspectRatio=false)),
    Documentation(info="<html>
<p>Assembles the reactor vessel internals of paper Fig. 2: a lower plenum of
<code>nLP</code> nodes, <code>nRings</code> parallel groups of fuel channels with
<code>nAxial</code> axial nodes each, and an upper plenum of <code>nUP</code> nodes. With the
default nodalization (15 rings, 20 axial nodes) the channel region has 300 cells, exactly as
in the MARS input.</p>

<p>As in the paper, the reactor core is <b>not</b> the channel region alone: the last lower
plenum node and the first upper plenum node (Volumes 120-03 and 190-01 of the MARS input) are
counted as core cells, because thermal neutrons leaking from the graphite cause fission
there. The core cells are ordered as</p>
<ol>
<li>cells <code>1 .. nRings*nAxial</code>, the channel cells, ring by ring;</li>
<li>cell <code>nRings*nAxial+1</code>, the last lower plenum node;</li>
<li>cell <code>nRings*nAxial+2</code>, the first upper plenum node.</li>
</ol>
<p>This ordering is the paper's control-volume definition and is kept as such. The
<i>volumes</i> of the two boundary nodes are a different matter: the paper does not publish
them, and the values this library carries are legacy figures left over from an earlier
inventory balance rather than measurements of 120-03 and 190-01. The paper does state that
190-01 is 0.0635 m long in the base case, against the 0.0118 m that follows from the volume
used here. See <a href=\"modelica://MSRE.Data.Geometry\">Data.Geometry</a>, where the
provenance of each is classified and the benchmark-equivalent figures are reported without
being connected to anything.</p>

<p>The core-boundary sensitivity of the paper, which lengthens Volume 190-01 and shortens the
rest of the upper plenum, is reproduced here by increasing
<code>V_upperPlenum</code> while reducing an equal loop volume, so that the core
transit time grows and the loop transit time shrinks by the same amount.</p>

<h4>How the flow divides between the rings</h4>
<p>The channel groups are connected in parallel between the two plena. The plena expose their
state at the junctions and the channels do not, which is what makes the parallel connection
well posed: each ring sees the same two pressures and solves for its own mass flow rate, so
there are <code>nRings</code> independent flow states and no algebraic loop between them.</p>

<p>Because every ring has the same channel geometry, the split is even unless something breaks
the symmetry. Two things can:</p>
<ol>
<li><code>K_channelInlet</code> and <code>K_channelExit</code>, the form losses of the two
plenum junctions, which are the only per-ring hydraulic parameters in the model. Both default
to zero. Setting them requires the MSRE channel flow measurements (Kedl, ORNL-TM-3229); they
are not derivable from the geometry in this record.</li>
<li>The viscosity, through the fuel salt temperature. The channel flow is laminar
(<code>Re</code> is about 855 at rated flow), so this acts on the flow split directly, and no
coefficient has to be set for it to act.</li>
</ol>

<p><code>f_flowSplit</code> reports the fraction carried by each ring and
<code>err_flowSplit</code> its largest relative departure from <code>1/nRings</code>. With zero
form losses and an isothermal core the second should be at solver tolerance; that is the check
that the parallel connection is doing what it is supposed to, and
<a href=\"modelica://MSRE.Verification.Steady_LoopBalance\">Steady_LoopBalance</a> asserts it.</p>
</html>"));
end ReactorCore;
