within MSRE.Functions;
function driftReactivity
  "Analytic steady-state reactivity loss caused by delayed neutron precursor drift (paper Eq. 8)"
  extends Modelica.Icons.Function;

  input Real betas[:] "Delayed neutron fraction of each precursor group";
  input SIadd.InverseTime lambdas[size(betas, 1)]
    "Decay constant of each precursor group";
  input SI.Time tau_C "Fuel salt transit time through the reactor core";
  input SI.Time tau_L "Fuel salt transit time through the external loop";
  output SIadd.NonDim drho "Reactivity loss (positive number)";

protected
  Integer nC=size(betas, 1);
algorithm
  drho := 0;
  for i in 1:nC loop
    drho := drho + betas[i]/2*(1 + exp(-lambdas[i]*tau_C))*(1 - exp(-lambdas[i]*tau_L))/((1
       - exp(-lambdas[i]*(tau_C + tau_L)))*(1 + (lambdas[i]*tau_C/Modelica.Constants.pi)^2));
  end for;

  annotation (Documentation(info="<html>
<p>Closed-form steady-state drift reactivity for a system made of a core and a single
external loop, a cosine axial power profile, uniform neutron importance and no flow mixing
(paper Eq. 8, after Haubenreich, ORNL-TM-380, and Jeong and Cho, NET 58 (2026) 104160):</p>

<p><code>
drho = sum_i beta_i/2 * (1+exp(-lambda_i*tau_C))*(1-exp(-lambda_i*tau_L))
       / [ (1-exp(-lambda_i*(tau_C+tau_L))) * (1+(lambda_i*tau_C/pi)^2) ]
</code></p>

<p>With the U-235 data of paper Table 1 and the MARS transit times
<code>tau_C = 9.56 s</code>, <code>tau_L = 16.14 s</code> this returns 228.4 pcm, against
226.5 pcm obtained from the transient simulation. Use it to check the asymptotic
reactivity of <a href=\"modelica://MSRE.Experiments.PumpStartup\">PumpStartup</a>.</p>
</html>"));
end driftReactivity;
