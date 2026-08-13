within MSRE.Components;
model SaltPipe
  "Fuel salt pipe that transports the delayed neutron precursors and decays them locally"

  import TRANSFORM;
  outer TRANSFORM.Fluid.SystemTF systemTF;

  replaceable package Medium = Modelica.Media.Interfaces.PartialMedium
    "Fuel salt medium, whose trace substances are the delayed neutron precursor groups"
    annotation (choicesAllMatching=true);

  /* ---------------- Geometry ---------------- */
  parameter Integer nV=1 "# of nodes";
  parameter SI.Volume V=1 "Total fluid volume";
  parameter SI.Length length=1 "Total flow length";
  parameter SI.Length dheight=0 "Elevation rise from port_a to port_b";
  final parameter SI.Area crossArea=V/length "Flow area";
  parameter SI.Length dimension=sqrt(4*crossArea/pi)
    "Hydraulic diameter (defaults to the equivalent circular pipe)";

  /* ---------------- Precursor transport ---------------- */
  parameter SIadd.InverseTime lambdas[Medium.nC]=zeros(Medium.nC)
    "Decay constant of each precursor group";
  input SIadd.ExtraPropertyFlowRate mC_sources[nV,Medium.nC]=zeros(nV, Medium.nC)
    "Precursor production by fission (non-zero only for nodes inside the reactor core)"
    annotation (Dialog(group="Inputs"));
  input SI.HeatFlowRate Q_gens[nV]=zeros(nV) "Volumetric heat source of each node"
    annotation (Dialog(group="Inputs"));

  /* ---------------- Pressure loss ---------------- */
  parameter Real Ks[nFM]=zeros(nFM) "Form loss coefficient of each flow segment";

  /* ---------------- Initialization ---------------- */
  parameter SI.AbsolutePressure p_a_start=1.5e5 "Pressure at port_a"
    annotation (Dialog(tab="Initialization"));
  parameter SI.Temperature T_a_start=908 "Temperature at port_a"
    annotation (Dialog(tab="Initialization"));
  parameter SI.Temperature T_b_start=T_a_start "Temperature at port_b"
    annotation (Dialog(tab="Initialization"));
  parameter SIadd.ExtraProperty C_a_start[Medium.nC]=zeros(Medium.nC)
    "Precursor concentration at port_a" annotation (Dialog(tab="Initialization"));
  parameter SIadd.ExtraProperty C_b_start[Medium.nC]=C_a_start
    "Precursor concentration at port_b" annotation (Dialog(tab="Initialization"));
  parameter SI.MassFlowRate m_flow_a_start=0 "Mass flow rate at port_a"
    annotation (Dialog(tab="Initialization"));

  /* ---------------- Advanced ---------------- */
  parameter Boolean exposeState_a=true "=true, p is calculated at port_a else m_flow"
    annotation (Dialog(tab="Advanced", group="Model Structure"));
  parameter Boolean exposeState_b=false "=true, p is calculated at port_b else m_flow"
    annotation (Dialog(tab="Advanced", group="Model Structure"));
  final parameter Integer nFM=if exposeState_a and exposeState_b then nV - 1 elseif not
      exposeState_a and not exposeState_b then nV + 1 else nV "# of flow segments";
  parameter Boolean use_HeatTransfer=false "=true to expose the wall heat ports"
    annotation (Dialog(tab="Advanced"));

  replaceable model HeatTransfer = MSRE.ClosureRelations.Nus_MoltenSalt constrainedby
    TRANSFORM.Fluid.ClosureRelations.HeatTransfer.Models.DistributedPipe_1D_MultiTransferSurface.PartialHeatTransfer_setT
    "Wall heat transfer" annotation (choicesAllMatching=true);

  /* ---------------- Ports ---------------- */
  TRANSFORM.Fluid.Interfaces.FluidPort_Flow port_a(redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
  TRANSFORM.Fluid.Interfaces.FluidPort_Flow port_b(redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{90,-10},{110,10}})));
  TRANSFORM.HeatAndMassTransfer.Interfaces.HeatPort_Flow heatPorts[nV] if use_HeatTransfer
    annotation (Placement(transformation(extent={{-10,40},{10,60}})));

  TRANSFORM.Fluid.Pipes.GenericPipe_MultiTransferSurface pipe(
    redeclare package Medium = Medium,
    use_HeatTransfer=use_HeatTransfer,
    redeclare model HeatTransfer = HeatTransfer,
    redeclare model Geometry =
        TRANSFORM.Fluid.ClosureRelations.Geometry.Models.DistributedVolume_1D.GenericPipe (
        nV=nV,
        dimensions=fill(dimension, nV),
        crossAreas=fill(crossArea, nV),
        perimeters=fill(4*crossArea/dimension, nV),
        dlengths=fill(length/nV, nV),
        dheights=fill(dheight/nV, nV)),
    redeclare model FlowModel =
        TRANSFORM.Fluid.ClosureRelations.PressureLoss.Models.DistributedPipe_1D.SinglePhase_Developed_2Region_NumStable
        (Ks_ab=Ks, Ks_ba=Ks),
    redeclare model InternalHeatGen =
        TRANSFORM.Fluid.ClosureRelations.InternalVolumeHeatGeneration.Models.DistributedVolume_1D.GenericHeatGeneration
        (Q_gens=Q_gens),
    redeclare model InternalTraceGen = MSRE.ClosureRelations.PrecursorDecay (
        nParallel=1,
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
    annotation (Placement(transformation(extent={{-10,-10},{10,10}})));

  /* ---------------- Summary ---------------- */
  SIadd.ExtraPropertyExtrinsic mCs[nV,Medium.nC]=pipe.mCs
    "# of precursors of each group in each node";
  SI.Volume Vs[nV]=pipe.geometry.Vs "Fluid volume of each node";
  SI.Temperature Ts[nV]=pipe.mediums.T "Temperature of each node";

equation
  connect(port_a, pipe.port_a) annotation (Line(points={{-100,0},{-10,0}}, color={0,127,255}));
  connect(port_b, pipe.port_b) annotation (Line(points={{100,0},{10,0}}, color={0,127,255}));
  connect(pipe.heatPorts[:, 1], heatPorts)
    annotation (Line(points={{0,5},{0,50}}, color={191,0,0}));

  annotation (
    defaultComponentName="pipe",
    Icon(coordinateSystem(preserveAspectRatio=false), graphics={
        Rectangle(
          extent={{-90,40},{90,-40}},
          lineColor={0,0,0},
          fillColor={0,127,255},
          fillPattern=FillPattern.HorizontalCylinder),
        Text(
          extent={{-149,-50},{151,-90}},
          lineColor={0,0,255},
          textString="%name")}),
    Diagram(coordinateSystem(preserveAspectRatio=false)),
    Documentation(info="<html>
<p>A thin wrapper around <code>TRANSFORM.Fluid.Pipes.GenericPipe_MultiTransferSurface</code>
that is parameterized by <b>volume and length</b> rather than diameter, because the MSRE
nodalization is defined by fuel-salt volumes, and that applies the decay term of the precursor
transport equation through the
<a href=\"modelica://MSRE.ClosureRelations.PrecursorDecay\">PrecursorDecay</a> closure,</p>

<p><code>mC_gens[i,j] = mC_sources[i,j] - lambda_j*mC[i,j]</code></p>

<p>Every fuel-salt component of the primary loop uses it, so that precursors decay everywhere
they are carried, which is the whole point of solving paper Eq. 3 over the entire system
rather than over a core plus a single lumped loop.</p>
</html>"));
end SaltPipe;
