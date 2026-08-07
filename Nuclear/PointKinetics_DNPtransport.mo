within MSRE.Nuclear;
model PointKinetics_DNPtransport
  "Modified point kinetics for a circulating-fuel reactor: precursors are supplied by a transport solution"

  import TRANSFORM;

  replaceable record Data = MSRE.Data.PrecursorGroups.U235_6group constrainedby
    TRANSFORM.Nuclear.ReactorKinetics.Data.PrecursorGroups.PartialPrecursorGroup
    "Delayed neutron precursor data" annotation (choicesAllMatching=true);
  Data data;
  final parameter Integer nC=data.nC "# of delayed neutron precursor groups";

  parameter Integer nV(min=1) = 1
    "# of thermal-hydraulic cells that make up the reactor core";
  parameter SI.Time Lambda=2.4e-4 "Prompt neutron generation time";
  parameter SI.Power Q_fission_start=1e6 "Fission power at the initial steady state";
  parameter Real N_start(min=Modelica.Constants.small) = 1
    "Neutron population at the initial steady state (arbitrary but fixed scale)";

  parameter SI.Time t_null=0
    "Null transient duration: the neutron balance is released, and Beta_eff frozen, at this time"
    annotation (Dialog(group="Initialization"));
  parameter Boolean use_servoControl=false
    "=true: the reactivity is set so that der(N)=0 (flux servo controller of the zero-power tests)";

  /* ---------------- Inputs supplied by the fluid model ---------------- */
  input SIadd.ExtraPropertyExtrinsic mCs[nV,nC]
    "# of precursors of each group present in each core cell"
    annotation (Dialog(group="Inputs"));
  input SI.Volume Vs[nV] "Volume of each core cell" annotation (Dialog(group="Inputs"));
  input SIadd.NonDim SF[nV]=fill(1/nV, nV)
    "Fraction of the fission source generated in each core cell, sum(SF)=1"
    annotation (Dialog(group="Inputs"));

  /* ---------------- Weighting of the core cells (paper Eq. 4) ---------------- */
  parameter SIadd.NonDim phis[nV]=fill(1, nV)
    "Normalized neutron flux of each core cell" annotation (Dialog(group="Weighting"));
  parameter SIadd.NonDim phis_adjoint[nV]=fill(1, nV)
    "Neutron importance of each core cell (unity in the paper)"
    annotation (Dialog(group="Weighting"));

  /* ---------------- Reactivity (paper Eq. 5) ---------------- */
  input SIadd.NonDim rho_input=0
    "Externally imposed reactivity (control rods, poison, ...)"
    annotation (Dialog(group="Inputs"));
  parameter Integer nFeedback=0 "# of linear reactivity feedback terms"
    annotation (Dialog(group="Reactivity feedback"));
  parameter Real alphas_feedback[nFeedback]=fill(0, nFeedback)
    "Reactivity feedback coefficients, e.g. [1/K]"
    annotation (Dialog(group="Reactivity feedback"));
  input Real vals_feedback[nFeedback]=fill(0, nFeedback)
    "Current value of each feedback variable, e.g. a flux weighted temperature"
    annotation (Dialog(group="Inputs"));
  parameter Boolean use_frozenReference=true
    "=true: the feedback reference values are taken from the state reached at t_null"
    annotation (Dialog(group="Reactivity feedback"));
  parameter Real vals_feedback_reference[nFeedback]=fill(0, nFeedback)
    "Reference value of each feedback variable (used when use_frozenReference=false)"
    annotation (Dialog(group="Reactivity feedback"));

  /* ---------------- Results ---------------- */
  Real N(start=N_start, fixed=true) "Neutron population in the reactor core";
  Real Cs[nC] "Effective # of precursors of each group in the core (paper Eq. 4)";
  SI.Power Q_fission "Fission power";
  SI.Power Qs[nV] "Fission power generated in each core cell";
  SIadd.ExtraPropertyFlowRate mC_sources[nV,nC]
    "Precursor production by fission in each core cell, passed to the fluid model (paper Eq. 3)";

  SIadd.NonDim rho "Total reactivity acting on the neutron balance";
  SIadd.NonDim rhos_feedback[nFeedback] "Contribution of each feedback term";
  SIadd.NonDim rho_servo
    "Reactivity the control rods must supply to hold the reactor critical (paper Eq. 7)";
  Real rho_servo_pcm=1e5*rho_servo "Control rod reactivity in pcm";

  SIadd.NonDim Beta_eff_inst
    "Instantaneous effective delayed neutron fraction, Lambda*sum(lambda_i*C_i)/N";
  discrete SIadd.NonDim Beta_eff(start=data.Beta, fixed=true)
    "Effective delayed neutron fraction used in the kinetics (paper Eq. 6)";
  discrete Real vals_reference[nFeedback](start=vals_feedback_reference, each fixed=true)
    "Reference values actually used by the feedback terms";

  final parameter SIadd.NonDim betas[nC]=data.alphas*data.Beta
    "Delayed neutron fraction of each group";
  final parameter SIadd.InverseTime lambdas[nC]=data.lambdas
    "Decay constant of each group";

protected
  Boolean released=time >= t_null "=true once the neutron balance is released";

equation
  /* Effective number of precursors in the core, flux and importance weighted (paper Eq. 4) */
  for j in 1:nC loop
    Cs[j] = sum({phis_adjoint[i]*mCs[i, j] for i in 1:nV})/sum({phis_adjoint[i]*phis[i]*Vs[
      i] for i in 1:nV})*sum(Vs);
  end for;

  Beta_eff_inst = Lambda*sum({lambdas[j]*Cs[j] for j in 1:nC})/N;

  /* Beta_eff and the feedback reference are the steady state reached by the null transient
     (paper Eq. 6 and the discussion following paper Eq. 5). */
  when released then
    Beta_eff = Beta_eff_inst;
    vals_reference = if use_frozenReference then vals_feedback else vals_feedback_reference;
  end when;

  rhos_feedback = {alphas_feedback[j]*(vals_feedback[j] - vals_reference[j]) for j in 1:
    nFeedback};
  rho = rho_input + sum(rhos_feedback);

  /* Ideal flux servo controller: the rod reactivity that makes der(N) vanish (paper Eq. 7) */
  rho_servo = Beta_eff - Beta_eff_inst;

  /* Neutron balance (paper Eq. 1). It is frozen during the null transient, and also when the
     flux servo controller holds the power constant. */
  der(N) = if released and not use_servoControl then (rho - Beta_eff)/Lambda*N + sum({
    lambdas[j]*Cs[j] for j in 1:nC}) else 0;

  Q_fission = Q_fission_start*N/N_start;
  Qs = {Q_fission*SF[i] for i in 1:nV};

  /* Production term of the precursor transport equation, non-zero inside the core only
     (the coefficient f of paper Eq. 3). Every fluid component, in the core and outside it,
     adds its own decay term -lambda_j*mC[i,j]. */
  mC_sources = {{betas[j]/Lambda*N*SF[i] for j in 1:nC} for i in 1:nV};

  annotation (
    defaultComponentName="kinetics",
    Icon(coordinateSystem(preserveAspectRatio=false), graphics={
        Rectangle(
          extent={{-100,100},{100,-100}},
          lineColor={0,0,127},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-149,140},{151,100}},
          textString="%name",
          lineColor={0,0,255}),
        Ellipse(
          extent={{-40,40},{40,-40}},
          lineColor={0,0,0},
          fillColor={255,128,0},
          fillPattern=FillPattern.Sphere),
        Line(points={{-90,0},{-40,0}}, color={0,0,0}),
        Line(points={{40,0},{90,0}}, color={0,0,0}),
        Text(
          extent={{-38,20},{38,-20}},
          lineColor={0,0,0},
          textString="PK"),
        Line(
          points={{-80,-60},{-40,-60},{-20,-40},{0,-60},{20,-80},{40,-60},{80,-60}},
          color={0,0,255},
          smooth=Smooth.Bezier)}),
    Diagram(coordinateSystem(preserveAspectRatio=false)),
    Documentation(info="<html>
<h4>What this model does</h4>
<p>It implements the modified point kinetics model of Section 2 of the reference paper. The
conventional precursor balance is <b>not</b> solved here. Instead the precursor groups are
declared as trace substances of the fuel-salt medium, so that the TRANSFORM fluid components
solve the precursor transport equation</p>

<p><code>d(c_i)/dt + div(c_i*v) = f*beta_i/Lambda*n - lambda_i*c_i</code>&nbsp;&nbsp;(paper Eq. 3)</p>

<p>over the whole primary system. This model</p>
<ol>
<li>receives the resulting precursor inventory <code>mCs[i,j]</code> of every core cell,</li>
<li>condenses it into the effective core precursor number <code>Cs[j]</code> with the
importance and flux weighting of paper Eq. 4,</li>
<li>solves the neutron balance of paper Eq. 1, and</li>
<li>returns the fission production term <code>mC_sources[i,j]</code> that the fluid model needs.
The decay term of paper Eq. 3 is added locally by every fluid component, inside the core and
outside it alike, because precursors decay everywhere in the loop.</li>
</ol>

<h4>Null transient and Beta_eff</h4>
<p>Following Section 2.2 of the paper, the steady state is established by a null transient:
until <code>time = t_null</code> the neutron balance is frozen (<code>der(N)=0</code>) while
the flow field and the precursor distribution converge. At <code>t_null</code> the effective
delayed neutron fraction is evaluated from the converged state,</p>

<p><code>Beta_eff = Lambda/N_o * sum_i lambda_i*C_io</code>&nbsp;&nbsp;(paper Eq. 6)</p>

<p>and held constant for the rest of the run. The reference values of the temperature
feedback terms are frozen at the same instant, which is what makes the feedback reactivity
depend only on the temperature <i>change</i>, as the paper states.</p>

<p>Set <code>t_null = 0</code> to skip the null transient; the model then uses
<code>Beta_eff = data.Beta</code> (the static total fraction) and the reference values given
as parameters, which is the correct choice when the initial condition is a stagnant core.</p>

<h4>Zero-power tests</h4>
<p>With <code>use_servoControl = true</code> the neutron population is held constant and</p>

<p><code>rho_servo = Beta_eff - Lambda/N * sum_i lambda_i*C_i</code>&nbsp;&nbsp;(paper Eq. 7)</p>

<p>is reported. This is the reactivity the control rods insert to keep the reactor critical,
that is, exactly the quantity measured in the MSRE pump startup and coastdown tests. It is
available in pcm as <code>rho_servo_pcm</code>.</p>

<h4>Scaling</h4>
<p><code>N</code> has no absolute meaning; only the ratio <code>N/N_start</code> enters the
fission power. The precursor inventories carried by the fluid must be generated with the same
scale, which is guaranteed because <code>mC_gens</code> is produced by this model.</p>
</html>"));
end PointKinetics_DNPtransport;
