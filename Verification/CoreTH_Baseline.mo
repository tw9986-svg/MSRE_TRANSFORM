within MSRE.Verification;
model CoreTH_Baseline
  "Stage-1 MSRE core TH verification: one equivalent 1-D channel group, 20 axial cells, fixed flow and fixed power"
  extends Modelica.Icons.Example;

  import TRANSFORM;

  replaceable package Medium = MSRE.Media.FuelSalt_U235 constrainedby
    Modelica.Media.Interfaces.PartialMedium
    "Fuel salt property model" annotation (choicesAllMatching=true);

  MSRE.Data.Geometry geometry "MSRE hardware geometry and reference operating data";

  /* ------------------------------------------------------------------
     Test definition
     ------------------------------------------------------------------ */
  parameter Integer nAxial=geometry.nAxial
    "Axial cells; 20 keeps the same axial discretization used by the Jeong MARS core";
  parameter SI.MassFlowRate m_flow_set=geometry.m_flow_nominal
    "Imposed total core flow rate";
  parameter SI.Temperature T_in=908
    "Imposed core inlet temperature";
  parameter SI.Power Q_core=8e6
    "Fixed thermal test power. This is a TH verification condition, not a Jeong transient validation target";
  parameter SI.Power Q_energyNorm=8e6
    "Scale used to normalize the energy residual when Q_core = 0. Not a test condition and not a tolerance";
  parameter SI.AbsolutePressure p_out=geometry.p_system
    "Outlet pressure boundary condition";
  parameter SI.Time t_settle=300
    "Time allowed for the core energy inventory to reach steady state";

  /* Acceptance criteria. These test conservation, not agreement with an experiment. */
  parameter SIadd.NonDim tol_energy=1e-3
    "Allowed relative steady-state energy imbalance";
  parameter SI.MassFlowRate tol_mass=1e-6
    "Allowed inlet/outlet mass-flow mismatch";

  /* ------------------------------------------------------------------
     System and boundaries
     ------------------------------------------------------------------ */
  inner TRANSFORM.Fluid.SystemTF systemTF(
    p_start=geometry.p_system,
    T_start=T_in,
    allowFlowReversal=false,
    energyDynamics=TRANSFORM.Types.Dynamics.FixedInitial,
    momentumDynamics=TRANSFORM.Types.Dynamics.DynamicFreeInitial)
    annotation (Placement(transformation(extent={{-90,70},{-70,90}})));

  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T inlet(
    redeclare package Medium = Medium,
    nPorts=1,
    m_flow=m_flow_set,
    T=T_in)
    "Fixed total MSRE core flow and inlet temperature"
    annotation (Placement(transformation(extent={{-80,-10},{-60,10}})));

  TRANSFORM.Fluid.BoundaryConditions.Boundary_pT outlet(
    redeclare package Medium = Medium,
    nPorts=1,
    p=p_out,
    T=T_in)
    "Pressure boundary downstream of the core"
    annotation (Placement(transformation(extent={{80,-10},{60,10}})));

  /* ------------------------------------------------------------------
     Baseline core

     The 1140 physical channels are collapsed into one equivalent flow path:
       crossArea = 1140*A_channel
       hydraulic diameter = the physical single-channel Dh
       length = physical active height

     No graphite heat structure and no kinetics are present. All Q_core is deposited
     directly in the fuel salt as an evenly distributed volumetric source. This makes
     the first verification problem a pure mass/momentum/energy-balance test.
     ------------------------------------------------------------------ */
  MSRE.Components.SaltPipe core(
    redeclare package Medium = Medium,
    nV=nAxial,
    V=geometry.V_channels,
    length=geometry.H_channels,
    dheight=geometry.H_channels,
    dimension=geometry.Dh_channel,
    Q_gens=fill(Q_core/nAxial, nAxial),
    lambdas=zeros(Medium.nC),
    p_a_start=geometry.p_system,
    T_a_start=T_in,
    T_b_start=T_in,
    m_flow_a_start=m_flow_set,
    exposeState_a=true,
    exposeState_b=false,
    use_HeatTransfer=false)
    "Equivalent 1-D active core channel region"
    annotation (Placement(transformation(extent={{-20,-10},{20,10}})));

  /* ------------------------------------------------------------------
     Reported quantities
     ------------------------------------------------------------------ */
  SI.MassFlowRate m_flow_in=core.port_a.m_flow
    "Mass flow entering the equivalent core";
  SI.MassFlowRate m_flow_out=-core.port_b.m_flow
    "Mass flow leaving the equivalent core";
  SI.MassFlowRate err_mass=m_flow_in - m_flow_out
    "Steady-state mass conservation residual";

  SI.AbsolutePressure p_in_actual=core.port_a.p "Core inlet pressure";
  SI.AbsolutePressure p_out_actual=core.port_b.p "Core outlet pressure";
  SI.PressureDifference dp_core=p_in_actual - p_out_actual
    "Calculated active-core pressure drop including friction and elevation";

  SI.Temperature T_firstCell=core.Ts[1] "Fuel temperature in first axial control volume";
  SI.Temperature T_lastCell=core.Ts[nAxial] "Fuel temperature in last axial control volume";

  SI.SpecificEnthalpy h_in=actualStream(core.port_a.h_outflow)
    "Specific enthalpy entering the core";
  SI.SpecificEnthalpy h_out=actualStream(core.port_b.h_outflow)
    "Specific enthalpy leaving the core";
  SI.Power Q_toFluid=m_flow_in*(h_out - h_in)
    "Net enthalpy rise of the fuel salt";
  /* Normalizing by Q_core alone divides by zero in the Q_core = 0 case, so the residual is
     scaled by Q_energyNorm whenever the test power is zero. At the 8 MW condition Q_norm is
     Q_core and err_energy is exactly what it was before. */
  final parameter SI.Power Q_norm=if abs(Q_core) > 0 then abs(Q_core) else Q_energyNorm
    "Scale of the energy residual";
  SIadd.NonDim err_energy=(Q_toFluid - Q_core)/Q_norm
    "Relative steady-state energy residual; target is zero";
  SI.Temperature T_out=core.Ts[nAxial] "Fuel salt temperature leaving the last axial cell";
  SI.TemperatureDifference dT_core=T_out - T_in
    "Core temperature rise actually calculated by the model";

  /* ---------------- Momentum-balance decomposition ----------------
     Taken from the pipe, which forms the static term from the LOCAL density of every node.
     dp_nonstatic is not called a friction loss: it still contains the acceleration term. */
  SI.Pressure dp_gravity_local=core.dp_gravity_local
    "PRIMARY static term, local node densities";
  SI.Pressure dp_gravity_bulk=core.dp_gravity_bulk
    "CROSS-CHECK ONLY: same term with a single average density";
  SI.Pressure dp_nonstatic=core.dp_nonstatic
    "dp_total minus the local static head; contains acceleration, friction and form";
  SI.Pressure dp_acceleration=core.dp_acceleration
    "Momentum-flux change, computed independently of the TRANSFORM flow model";
  SI.Pressure dp_residual=core.dp_residual
    "Remainder: friction plus form plus anything else the flow model contributes";
  SIadd.NonDim err_gravityForm=(dp_gravity_local - dp_gravity_bulk)/max(abs(dp_gravity_local),
      1)
    "Relative gap between the local-density and average-density static terms";
  SI.Time tau_core_equivalent=geometry.V_channels*core.d_bulk/max(abs(m_flow_in), 1e-9)
    "Transit time of the equivalent channel region at the calculated bulk density";

  SI.DynamicViscosity mu_in=Medium.dynamicViscosity(
      Medium.setState_pT(p_in_actual, T_in)) "Fuel viscosity at the inlet state";
  SIadd.NonDim Re_channel=abs(m_flow_in/geometry.nChannels_total)*geometry.Dh_channel/
      (geometry.A_channel*mu_in)
    "Reynolds number of one physical fuel channel at the imposed total flow";

  SI.SpecificHeatCapacity cp_in=Medium.specificHeatCapacityCp(
      Medium.setState_pT(p_in_actual, T_in)) "Inlet cp for a simple delta-T estimate only";
  SI.TemperatureDifference dT_energyEstimate=Q_core/(m_flow_set*cp_in)
    "Simple Q/(m*cp) estimate; diagnostic only";

 equation
  connect(inlet.ports[1], core.port_a)
    annotation (Line(points={{-60,0},{-20,0}}, color={0,127,255}));
  connect(core.port_b, outlet.ports[1])
    annotation (Line(points={{20,0},{60,0}}, color={0,127,255}));

  when terminal() then
    assert(abs(err_mass) < tol_mass,
      "Core mass balance failed: inlet = " + String(m_flow_in) + " kg/s, outlet = " +
      String(m_flow_out) + " kg/s.", AssertionLevel.error);
    assert(abs(err_energy) < tol_energy,
      "Core energy balance failed: Q_toFluid = " + String(Q_toFluid) + " W, Q_core = " +
      String(Q_core) + " W, relative error = " + String(err_energy) + ". Increase t_settle only if the stored energy is still changing; do not tune geometry or properties to force this assertion to pass.",
      AssertionLevel.error);
  end when;

  annotation (
    experiment(
      StopTime=300,
      __Dymola_NumberOfIntervals=1500,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>Purpose</h4>
<p>This is the first model in the staged MSRE verification plan. It deliberately removes
radial rings, graphite heat storage, the heat exchanger, pump dynamics, delayed-neutron
precursor transport and point kinetics. The only question is whether a TRANSFORM 1-D fluid
model using the documented MSRE channel geometry conserves mass and converts a prescribed
volumetric core power into the correct fuel-salt enthalpy rise while solving the corresponding
momentum balance.</p>

<h4>Relationship to Jeong et al. (2026)</h4>
<p>Jeong et al. use a one-dimensional MARS system model and subdivide each of 15 radial channel
groups into 20 axial cells. This baseline keeps the 20 axial cells but collapses the 15
hydraulically identical groups into one equivalent channel group. A later verification case
will restore the 15 x 20 nodalization and the paper's axial/radial power shapes.</p>

<h4>What is intentionally not validated here</h4>
<ul>
<li><code>Q_core = 8 MW</code> is only a fixed thermal test condition. Passing this model does
not validate an 8 MW MSRE operating point.</li>
<li>The inlet temperature is a boundary condition, not a predicted benchmark value.</li>
<li>No wall heat-transfer correlation is used because heat is deposited directly in the fuel
salt. Therefore the present low-Re core Nusselt-correlation issue cannot contaminate this
conservation test.</li>
<li>The calculated pressure drop is reported but not fitted or asserted against a measurement
until an independent pressure-loss reference is established.</li>
</ul>

<h4>Pass conditions</h4>
<p>At the end of the settling calculation, inlet and outlet mass flow must agree and
<code>m_flow*(h_out-h_in)</code> must equal the imposed <code>Q_core</code> within the stated
numerical tolerance. These are verification conditions, not calibration targets.</p>
</html>"));
end CoreTH_Baseline;
