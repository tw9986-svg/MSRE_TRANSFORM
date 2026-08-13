within MSRE.ClosureRelations;
model PrecursorDecay
  "Trace generation closure: fission production minus local precursor decay"
  extends
    TRANSFORM.Fluid.ClosureRelations.InternalTraceGeneration.Models.DistributedVolume_Trace_1D.PartialInternalTraceGeneration;

  parameter Real nParallel=1
    "# of parallel components; must match the nParallel of the host pipe";
  parameter SIadd.InverseTime lambdas[Medium.nC]=zeros(Medium.nC)
    "Decay constant of each precursor group";
  input SIadd.ExtraPropertyFlowRate mC_sources[nV,Medium.nC]=zeros(nV, Medium.nC)
    "Precursor production by fission, totalled over all parallel components"
    annotation (Dialog(group="Inputs"));

  SIadd.ExtraPropertyExtrinsic mCs[nV,Medium.nC]={{Cs[i, j]*Medium.density(states[i])*Vs[i]
      *nParallel for j in 1:Medium.nC} for i in 1:nV}
    "# of precursors of each group held in each node, totalled over all parallel components";

equation
  for i in 1:nV loop
    for j in 1:Medium.nC loop
      mC_flows[i, j] = mC_sources[i, j] - lambdas[j]*mCs[i, j];
    end for;
  end for;

  annotation (defaultComponentName="traceGen", Documentation(info="<html>
<h4>What this replaces</h4>
<p>The right hand side of the delayed neutron precursor transport equation (paper Eq. 3),</p>

<p><code>mC_gens[i,j] = mC_sources[i,j] - lambda_j*mC[i,j]</code></p>

<p>used to be written out by hand in every fuel salt component, and once more at system level
for the heat exchanger shell. That is the shape the term takes in a system code, where a user
sink term has to be declared per component (see the &quot;custom sink term&quot; of
Fischer and Bure&scaron;, NED 416 (2024) 112768, Eq. 13). Modelica does not need it: the term is a
<i>closure</i>, so it is written once here and redeclared into every component that carries
fuel salt.</p>

<p>The practical consequence is that a fuel salt component can no longer be added to the loop
<b>without</b> its decay term, which was previously possible and silently wrong.</p>

<h4>nParallel</h4>
<p><code>PartialInternalTraceGeneration</code> receives <code>Vs</code> for a
<b>single</b> component, and
<code>TRANSFORM.Fluid.Pipes.GenericPipe_MultiTransferSurface</code> divides
<code>internalTraceGen.mC_flows</code> by <code>nParallel</code> before applying it. Both
<code>mC_sources</code> and the decay term must therefore be totals over all parallel
components, which is why <code>nParallel</code> appears in <code>mCs</code> here. It has to be
given the same value as the host pipe; a mismatch scales the precursor inventory of that
component and nothing else will complain.</p>

<h4>Units</h4>
<p><code>Cs</code> is mass specific and <code>mCs</code> is extrinsic, following the TRANSFORM
convention <code>mCs = m*Cs</code> of
<code>TRANSFORM.Fluid.Pipes.BaseClasses.PartialDistributedVolume</code>. The absolute scale is
set by the kinetics model that produces <code>mC_sources</code>.</p>
</html>"));
end PrecursorDecay;
