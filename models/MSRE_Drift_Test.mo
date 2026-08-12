within TRANSFORM.Nuclear.ReactorKinetics.Examples;
model MSRE_Drift_Test
  import TRANSFORM;
  extends TRANSFORM.Icons.Example;
  replaceable package Medium =
      TRANSFORM.Media.Fluids.FLiBe.LinearFLiBe_pT (
  extraPropertiesNames=core_kinetics.summary_data.extraPropertiesNames,
  C_nominal=core_kinetics.summary_data.C_nominal);
  parameter SI.Length H = 3.4;
  parameter SI.Length L = 6.296;
  parameter SI.Volume V_core = 0.708 "Core fuel salt volume";
  parameter SI.Volume V_loop = 1.198 "External loop fuel salt volume";
  parameter SI.Velocity v=0.4772;
  parameter SI.Length Ds[core.nV] = fill(sqrt(4*(V_core/H)/Modelica.Constants.pi), core.nV);
  parameter SI.Length Ds1[loop_.nV] = fill(sqrt(4*(V_loop/L)/Modelica.Constants.pi), loop_.nV);
  parameter SI.MassFlowRate m_flow = 1;
  parameter SI.Temperature[core.nV] Tsr = linspace(300+273.15,500+273.15,core.nV);
  parameter SI.Temperature[loop_.nV] Tsr1 = linspace(500+273.15,300+273.15,loop_.nV);
  parameter SI.Pressure[core.nV] ps = 1e5*ones(core.nV);
  parameter SI.Pressure[loop_.nV] ps1 = 1e5*ones(loop_.nV);
  parameter SI.Density[core.nV] rhos = Medium.density_pT(ps,Tsr);
  parameter SI.Density[loop_.nV] rhos1 = Medium.density_pT(ps1,Tsr1);
  SI.Time tau_circulation = (sum(core.ms) + sum(loop_.ms))/m_flow
    "Tracer loop circulation time (core + external loop), = fuel salt inventory / mass flow rate";
  SIadd.ExtraPropertyFlowRate[loop_.nV,core_kinetics.summary_data.nC] mC_gens_pipe1={{
      -core_kinetics.summary_data.lambdas[j]*loop_.mCs[i, j]*loop_.nParallel +
      mC_gens_pipe1_PtoD[i, j] for j in 1:core_kinetics.summary_data.nC} for i in 1:
      loop_.nV};
  SIadd.ExtraPropertyFlowRate[loop_.nV,core_kinetics.summary_data.nC]
    mC_gens_pipe1_PtoD={{sum({core_kinetics.summary_data.lambdas[k] .* loop_.mCs[i, k]
       .* loop_.nParallel .* core_kinetics.summary_data.parents[j, k] for k in 1:
      core_kinetics.summary_data.nC}) for j in 1:core_kinetics.summary_data.nC} for i in 1:
      loop_.nV};
  SI.Temperature[core.nV] Ts=core.mediums.T;
  SI.Temperature[loop_.nV] Ts1=loop_.mediums.T;
  SI.Power[core.nV] Q_gens=core_kinetics.Qs;
  SI.Power Power=sum(core_kinetics.Qs);
  SI.Power Power_beta=sum(core_kinetics.Qs_decay);
  SI.Power Power_gamma=sum(core_kinetics.fissionProducts.Qs_far);
  SI.Power Power_DH = Power_beta + Power_gamma;
  SI.Power Power_total = Power_DH + Power;
  TRANSFORM.Fluid.BoundaryConditions.Boundary_pT back_to_core(
    nPorts=1,
    redeclare package Medium = Medium,
    p=100000) annotation (Placement(transformation(extent={{86,-10},{66,10}})));
  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T core_inlet(
    nPorts=1,
    redeclare package Medium = Medium,
    m_flow=1,
    use_C_in=true,
    C=fill(1e-6, Medium.nC),
    T=573.15)
    annotation (Placement(transformation(extent={{-56,-10},{-36,10}})));
  TRANSFORM.Fluid.Pipes.GenericPipe_MultiTransferSurface core(
    redeclare package Medium = Medium,
    m_flow_a_start=1,
    redeclare model Geometry =
        Fluid.ClosureRelations.Geometry.Models.DistributedVolume_1D.GenericPipe (
        nV=10,
        dimensions=Ds,
        dlengths=fill(H/core.nV,core.nV)),
    redeclare model InternalTraceGen =
        TRANSFORM.Fluid.ClosureRelations.InternalTraceGeneration.Models.DistributedVolume_Trace_1D.GenericTraceGeneration (
         mC_gens=cat(
            2,
            core_kinetics.mC_gens,
            core_kinetics.fissionProducts.mC_gens,
            core_kinetics.fissionProducts.mC_gens_TR)),
    p_a_start=100000,
    T_a_start=573.15,
    T_b_start=773.15,
    redeclare model InternalHeatGen =
        TRANSFORM.Fluid.ClosureRelations.InternalVolumeHeatGeneration.Models.DistributedVolume_1D.GenericHeatGeneration (
         Q_gens=core_kinetics.Qs + core_kinetics.fissionProducts.Qs_far))
    annotation (Placement(transformation(extent={{-26,-10},{-6,10}})));
  Fluid.Pipes.GenericPipe_MultiTransferSurface           loop_(
    redeclare package Medium = Medium,
    m_flow_a_start=1,
    use_HeatTransfer=true,
    redeclare model InternalHeatGen =
        Fluid.ClosureRelations.InternalVolumeHeatGeneration.Models.DistributedVolume_1D.GenericHeatGeneration,
    redeclare model Geometry =
        Fluid.ClosureRelations.Geometry.Models.DistributedVolume_1D.GenericPipe (
        nV=10,
        dimensions=Ds1,
        dlengths=fill(L/loop_.nV,loop_.nV)),
    redeclare model InternalTraceGen =
        TRANSFORM.Fluid.ClosureRelations.InternalTraceGeneration.Models.DistributedVolume_Trace_1D.GenericTraceGeneration (
         mC_gens=mC_gens_pipe1),
    p_a_start=100000,
    T_a_start=773.15,
    T_b_start=573.15)
    annotation (Placement(transformation(extent={{6,-10},{26,10}})));
  HeatAndMassTransfer.BoundaryConditions.Heat.HeatFlow_multi heat_rejection(
      nPorts=loop_.nV, Q_flow=fill(-5e4, heat_rejection.nPorts))
    annotation (Placement(transformation(extent={{46,10},{26,30}})));
  Fluid.Sensors.TraceSubstancesTwoPort_multi Concentration_Measure(redeclare package Medium =
                       Medium)
    annotation (Placement(transformation(extent={{36,10},{56,-10}})));
  TRANSFORM.Nuclear.ReactorKinetics.PointKinetics_L1_atomBased_external
    core_kinetics(
    nV=core.nV,
    Q_nominal=5e4*core.nV,
    specifyPower=true,
    Vs=core.Vs*core.nParallel,
    SigmaF_start=26,
    mCs=core.mCs[:, core_kinetics.summary_data.iPG[1]:core_kinetics.summary_data.iPG[
        2]]*core.nParallel,
    mCs_FP=core.mCs[:, core_kinetics.summary_data.iFP[1]:core_kinetics.summary_data.iFP[
        2]]*core.nParallel,
    nFeedback=1,
    redeclare record Data =
        TRANSFORM.Nuclear.ReactorKinetics.Data.PrecursorGroups.precursorGroups_6_FLiBeFueledSalt,
    alphas_feedback={-1e-4},
    vals_feedback={core.summary.T_effective},
    vals_feedback_reference={400 + 273.15})
    annotation (Placement(transformation(extent={{-30,20},{-10,40}})));
  TRANSFORM.Utilities.ErrorAnalysis.UnitTests unitTests(n=3, x={core_kinetics.Qs[
        6],core.mCs[6, 3],sum(core_kinetics.Qs_decay[6, :])})
    annotation (Placement(transformation(extent={{80,80},{100,100}})));
equation
  connect(core_inlet.ports[1], core.port_a)
    annotation (Line(points={{-36,0},{-26,0}}, color={0,127,255}));
  connect(core.port_b,loop_. port_a)
    annotation (Line(points={{-6,0},{6,0}},  color={0,127,255}));
  connect(heat_rejection.port, loop_.heatPorts[:, 1])
    annotation (Line(points={{26,20},{16,20},{16,5}}, color={191,0,0}));
  connect(loop_.port_b, Concentration_Measure.port_a)
    annotation (Line(points={{26,0},{36,0}}, color={0,127,255}));
  connect(Concentration_Measure.port_b, back_to_core.ports[1])
    annotation (Line(points={{56,0},{66,0}}, color={0,127,255}));
  connect(Concentration_Measure.C, core_inlet.C_in) annotation (Line(points={{46,-3.6},
          {46,-20},{-60,-20},{-60,-8},{-56,-8}},         color={0,0,127}));
  annotation (
      experiment(StopTime=100000000, __Dymola_NumberOfIntervals=10000),
    Documentation(info="<html>
<p>Derived from <code>PointKinetics_Drift_Test_flat</code> (TRANSFORM-Library commit 504359d).</p>
<p>Only the fuel salt volumes were changed, plus one added output variable:</p>
<ul>
<li><code>V_core</code> = 0.708 m3 and <code>V_loop</code> = 1.198 m3 introduced as explicit parameters.</li>
<li><code>Ds</code>/<code>Ds1</code> are now derived from those volumes at the original lengths
    <code>H</code> = 3.4 m and <code>L</code> = 6.296 m, i.e. A = V/length, D = sqrt(4A/pi).
    In the source example the diameters were instead derived from <code>m_flow</code>,
    <code>rhos</code> and <code>v</code>, which produced V_core = 0.00342 m3 and V_loop = 0.00633 m3.</li>
<li><code>tau_circulation</code> added: fuel salt inventory divided by mass flow rate, i.e. the
    mean time for a tracer to complete one core + external loop circuit.</li>
</ul>
<p>Everything else is byte-identical to the source example: precursor data
(<code>precursorGroups_6_FLiBeFueledSalt</code>: Beta = 0.0065, the six lambdas and alphas),
<code>Lambda_start</code> (model default 1e-5 s), Medium (<code>LinearFLiBe_pT</code>),
mass flow rate (1 kg/s), temperatures, pressures, power, feedback coefficient and heat rejection.</p>
<p>Consequence of holding the flow rate at the example default of 1 kg/s while using MSRE-scale
volumes: the salt inventory becomes about 3970 kg and <code>tau_circulation</code> is about
3970 s (66 min) rather than the roughly 25 s of the real MSRE, which circulates a comparable
inventory at roughly 160-190 kg/s. The source example gives about 20.3 s. Reaching MSRE timing
would require raising the flow rate as well, which was deliberately left untouched here.</p>
<p>Because the diameters are now set by volume, the parameters <code>v</code>,
<code>rhos</code>, <code>rhos1</code> and the <code>Tsr</code>/<code>Tsr1</code>/<code>ps</code>/<code>ps1</code>
chain that fed them are left declared at their original values but no longer influence the geometry.
They were kept rather than deleted so the diff against the source example stays minimal.</p>
</html>"));
end MSRE_Drift_Test;
