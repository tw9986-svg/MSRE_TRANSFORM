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
  parameter SI.Length H_channels=1.626 "Active channel height";
  parameter SI.Area A_channel=3.9198e-4 "Flow area of a single fuel channel";
  parameter SI.Length Dh_channel=0.01778 "Hydraulic diameter of a single fuel channel";
  parameter SI.Length r_graphite_inner=0.014036
    "Inner radius of the equivalent graphite annulus";
  parameter SI.Length r_graphite_outer=0.020503
    "Outer radius of the equivalent graphite annulus";
  parameter SI.Length dz_channels=H_channels "Elevation rise across the fuel channels";

  parameter SI.Volume V_lowerPlenum=0.0777 "Lower plenum fuel salt volume";
  parameter SI.Length L_lowerPlenum=0.30 "Lower plenum height";
  parameter SI.Length dz_lowerPlenum=L_lowerPlenum "Elevation rise across the lower plenum";
  parameter SI.Volume V_upperPlenum=0.0777 "Upper plenum fuel salt volume";
  parameter SI.Length L_upperPlenum=0.30 "Upper plenum height";
  parameter SI.Length dz_upperPlenum=L_upperPlenum "Elevation rise across the upper plenum";

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

  /* ---------------- Components ---------------- */
  MSRE.Components.SaltPipe lowerPlenum(
    redeclare package Medium = Medium,
    nV=nLP,
    V=V_lowerPlenum,
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
<p>The core-boundary sensitivity of the paper, which lengthens Volume 190-01 and shortens the
rest of the upper plenum, is reproduced here by increasing
<code>V_upperPlenum</code> while reducing an equal loop volume, so that the core
transit time grows and the loop transit time shrinks by the same amount.</p>

<p>The channel groups are connected in parallel between the two plena. The plena expose their
state at the junctions and the channels do not, which is what makes the parallel connection
well posed.</p>
</html>"));
end ReactorCore;
