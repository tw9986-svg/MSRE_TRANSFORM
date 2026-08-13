within MSRE.Components;
model CoreChannel
  "One radial ring of MSRE fuel channels together with its share of the graphite moderator"

  import TRANSFORM;
  outer TRANSFORM.Fluid.SystemTF systemTF;

  replaceable package Medium = Modelica.Media.Interfaces.PartialMedium
    "Fuel salt medium, whose trace substances are the delayed neutron precursor groups"
    annotation (choicesAllMatching=true);
  replaceable package Material = TRANSFORM.Media.Solids.Graphite.Graphite_1
    constrainedby TRANSFORM.Media.Interfaces.Solids.PartialAlloy
    "Graphite moderator material" annotation (choicesAllMatching=true);

  /* ---------------- Geometry ---------------- */
  parameter Real nParallel=76 "# of identical fuel channels represented by this ring";
  parameter Integer nV=20 "# of axial nodes";
  parameter Integer nR=3 "# of radial nodes in the graphite";
  parameter SI.Length length=1.626 "Active channel length";
  parameter SI.Length dheight=length "Elevation rise over the channel";
  parameter SI.Area crossArea=3.9198e-4 "Flow area of a single channel";
  parameter SI.Length dimension=0.01778 "Hydraulic diameter of a single channel";
  parameter SI.Length r_graphite_inner=0.014036
    "Inner radius of the equivalent graphite annulus";
  parameter SI.Length r_graphite_outer=0.020503
    "Outer radius of the equivalent graphite annulus";

  /* ---------------- Inputs ---------------- */
  input SI.HeatFlowRate Q_gens[nV]=zeros(nV)
    "Fission power deposited in the fuel salt of this ring, summed over all its channels"
    annotation (Dialog(group="Inputs"));
  input SI.HeatFlowRate Q_gens_graphite[nV]=zeros(nV)
    "Fission power deposited directly in the graphite of this ring"
    annotation (Dialog(group="Inputs"));
  input SIadd.ExtraPropertyFlowRate mC_sources[nV,Medium.nC]=zeros(nV, Medium.nC)
    "Precursor production by fission, summed over all channels of this ring"
    annotation (Dialog(group="Inputs"));
  parameter SIadd.InverseTime lambdas[Medium.nC]=zeros(Medium.nC)
    "Decay constant of each precursor group";

  /* ---------------- Initialization ---------------- */
  parameter SI.AbsolutePressure p_a_start=1.5e5 "Pressure at port_a"
    annotation (Dialog(tab="Initialization"));
  parameter SI.Temperature T_a_start=908 "Fuel salt temperature at port_a"
    annotation (Dialog(tab="Initialization"));
  parameter SI.Temperature T_b_start=T_a_start "Fuel salt temperature at port_b"
    annotation (Dialog(tab="Initialization"));
  parameter SI.Temperature T_graphite_start=0.5*(T_a_start + T_b_start)
    "Graphite temperature" annotation (Dialog(tab="Initialization"));
  parameter SIadd.ExtraProperty C_a_start[Medium.nC]=zeros(Medium.nC)
    "Precursor concentration at port_a" annotation (Dialog(tab="Initialization"));
  parameter SIadd.ExtraProperty C_b_start[Medium.nC]=C_a_start
    "Precursor concentration at port_b" annotation (Dialog(tab="Initialization"));
  parameter SI.MassFlowRate m_flow_a_start=0 "Mass flow rate of a single channel"
    annotation (Dialog(tab="Initialization"));

  /* ---------------- Advanced ---------------- */
  parameter Boolean exposeState_a=false "=true, p is calculated at port_a else m_flow"
    annotation (Dialog(tab="Advanced", group="Model Structure"));
  parameter Boolean exposeState_b=false "=true, p is calculated at port_b else m_flow"
    annotation (Dialog(tab="Advanced", group="Model Structure"));

  replaceable model HeatTransfer = MSRE.ClosureRelations.Nus_MoltenSalt constrainedby
    TRANSFORM.Fluid.ClosureRelations.HeatTransfer.Models.DistributedPipe_1D_MultiTransferSurface.PartialHeatTransfer_setT
    "Fuel salt to graphite heat transfer" annotation (choicesAllMatching=true);

  /* ---------------- Ports ---------------- */
  TRANSFORM.Fluid.Interfaces.FluidPort_Flow port_a(redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
  TRANSFORM.Fluid.Interfaces.FluidPort_Flow port_b(redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{90,-10},{110,10}})));

  /* ---------------- Components ---------------- */
  TRANSFORM.Fluid.Pipes.GenericPipe_MultiTransferSurface pipe(
    redeclare package Medium = Medium,
    nParallel=nParallel,
    use_HeatTransfer=true,
    redeclare model HeatTransfer = HeatTransfer,
    redeclare model Geometry =
        TRANSFORM.Fluid.ClosureRelations.Geometry.Models.DistributedVolume_1D.GenericPipe (
        nV=nV,
        dimensions=fill(dimension, nV),
        crossAreas=fill(crossArea, nV),
        perimeters=fill(4*crossArea/dimension, nV),
        dlengths=fill(length/nV, nV),
        dheights=fill(dheight/nV, nV)),
    redeclare model InternalHeatGen =
        TRANSFORM.Fluid.ClosureRelations.InternalVolumeHeatGeneration.Models.DistributedVolume_1D.GenericHeatGeneration
        (Q_gens=Q_gens),
    redeclare model InternalTraceGen = MSRE.ClosureRelations.PrecursorDecay (
        nParallel=nParallel,
        lambdas=lambdas,
        mC_sources=mC_sources),
    p_a_start=p_a_start,
    T_a_start=T_a_start,
    T_b_start=T_b_start,
    C_a_start=C_a_start,
    C_b_start=C_b_start,
    m_flow_a_start=m_flow_a_start,
    exposeState_a=exposeState_a,
    exposeState_b=exposeState_b)
    annotation (Placement(transformation(extent={{-10,-50},{10,-30}})));

  TRANSFORM.HeatAndMassTransfer.DiscritizedModels.Conduction_2D graphite(
    redeclare package Material = Material,
    nParallel=nParallel,
    redeclare model InternalHeatModel =
        TRANSFORM.HeatAndMassTransfer.DiscritizedModels.BaseClasses.Dimensions_2.GenericHeatGeneration
        (Q_gens={{Q_gens_graphite[j]/nR for j in 1:nV} for i in 1:nR}),
    redeclare model Geometry =
        TRANSFORM.HeatAndMassTransfer.ClosureRelations.Geometry.Models.Cylinder_2D_r_z (
        nR=nR,
        nZ=nV,
        r_inner=r_graphite_inner,
        r_outer=r_graphite_outer,
        length_z=length),
    T_a1_start=T_graphite_start,
    T_b1_start=T_graphite_start,
    T_a2_start=T_graphite_start,
    T_b2_start=T_graphite_start,
    exposeState_a1=true,
    exposeState_b1=false,
    exposeState_a2=false,
    exposeState_b2=false) annotation (Placement(transformation(
        extent={{-10,10},{10,-10}},
        rotation=90,
        origin={0,0})));

  TRANSFORM.HeatAndMassTransfer.BoundaryConditions.Heat.Adiabatic adiabatic_bottom[nR]
    annotation (Placement(transformation(extent={{-40,10},{-60,30}})));
  TRANSFORM.HeatAndMassTransfer.BoundaryConditions.Heat.Adiabatic adiabatic_top[nR]
    annotation (Placement(transformation(extent={{40,10},{60,30}})));
  TRANSFORM.HeatAndMassTransfer.BoundaryConditions.Heat.Adiabatic adiabatic_outer[nV]
    annotation (Placement(transformation(extent={{40,40},{60,60}})));

  /* ---------------- Summary quantities used by the kinetics ---------------- */
  SIadd.ExtraPropertyExtrinsic mCs[nV,Medium.nC]=pipe.mCs*nParallel
    "# of precursors of each group in each axial node of this ring";
  SI.Volume Vs[nV]=pipe.geometry.Vs*nParallel "Fuel salt volume of each axial node";
  SI.Temperature Ts_fuel[nV]=pipe.mediums.T "Fuel salt temperature of each axial node";
  SI.Temperature Ts_graphite[nV]={sum({graphite.materials[i, k].T*graphite.ms[i, k] for i in
        1:nR})/sum({graphite.ms[i, k] for i in 1:nR}) for k in 1:nV}
    "Mass averaged graphite temperature of each axial node";
  SI.Mass m_graphite=sum(graphite.ms)*nParallel "Graphite mass of this ring";

equation
  connect(port_a, pipe.port_a)
    annotation (Line(points={{-100,0},{-60,0},{-60,-40},{-10,-40}}, color={0,127,255}));
  connect(port_b, pipe.port_b)
    annotation (Line(points={{100,0},{60,0},{60,-40},{10,-40}}, color={0,127,255}));
  connect(graphite.port_a1, pipe.heatPorts[:, 1])
    annotation (Line(points={{0,-10},{0,-35}}, color={191,0,0}));
  connect(graphite.port_a2, adiabatic_bottom.port)
    annotation (Line(points={{-10,0},{-30,0},{-30,20},{-40,20}}, color={191,0,0}));
  connect(graphite.port_b2, adiabatic_top.port)
    annotation (Line(points={{10,0},{30,0},{30,20},{40,20}}, color={191,0,0}));
  connect(graphite.port_b1, adiabatic_outer.port)
    annotation (Line(points={{0,10},{0,50},{40,50}}, color={191,0,0}));

  annotation (
    defaultComponentName="coreChannel",
    Icon(coordinateSystem(preserveAspectRatio=false), graphics={
        Rectangle(
          extent={{-90,40},{90,-40}},
          lineColor={0,0,0},
          fillColor={0,127,255},
          fillPattern=FillPattern.HorizontalCylinder),
        Rectangle(
          extent={{-90,60},{90,40}},
          lineColor={0,0,0},
          fillColor={95,95,95},
          fillPattern=FillPattern.Backward),
        Rectangle(
          extent={{-90,-40},{90,-60}},
          lineColor={0,0,0},
          fillColor={95,95,95},
          fillPattern=FillPattern.Backward),
        Text(
          extent={{-149,-70},{151,-110}},
          lineColor={0,0,255},
          textString="%name")}),
    Diagram(coordinateSystem(preserveAspectRatio=false)),
    Documentation(info="<html>
<p>A single lumped fuel channel, scaled by <code>nParallel</code> to represent one of the
concentric radial rings the 1140 MSRE channels are grouped into (paper Section 3.2: 15 rings
of 20 axial nodes each, giving 300 core cells).</p>

<p>The graphite is a two-dimensional (r,z) conduction model of the equivalent annulus that
surrounds the channel. Its outer surface is adiabatic, which is the symmetry condition
between neighbouring channels, and both axial faces are adiabatic.</p>

<p>Following the paper, the whole fission power is by default deposited in the fuel salt
(<code>Q_gens</code>) and none in the graphite (<code>Q_gens_graphite = 0</code>), so that the
graphite acts as a passive heat reservoir. The paper identifies this as the main modelling
approximation to be removed in future work; here it is enough to give
<code>Q_gens_graphite</code> a non-zero value to deposit a fraction of the fission energy
directly in the moderator.</p>

<h4>Quantities exported to the kinetics model</h4>
<ul>
<li><code>mCs[nV,nC]</code> - precursor inventory of each axial node, already multiplied by
<code>nParallel</code>, that is, the total over all channels of the ring.</li>
<li><code>Vs[nV]</code> - fuel salt volume of each axial node, likewise total.</li>
<li><code>Ts_fuel</code>, <code>Ts_graphite</code> - node temperatures for the reactivity
feedback.</li>
</ul>
</html>"));
end CoreChannel;
