within MSRE.Data.PrecursorGroups;
record U233_6group "MSRE 6-group delayed neutron data for U-233 fuel (paper Table 2)"
  extends TRANSFORM.Nuclear.ReactorKinetics.Data.PrecursorGroups.PartialPrecursorGroup(
    extraPropertiesNames={"dnp1","dnp2","dnp3","dnp4","dnp5","dnp6"},
    C_nominal={26.0,40.2,8.85,6.38,0.285,0.0299},
    lambdas={0.0125,0.0323,0.1050,0.2940,1.2400,10.020},
    alphas={0.000208,0.000830,0.000595,0.001200,0.000226,0.000192}/0.003251,
    Beta=0.003251);
  annotation (defaultComponentName="data", Documentation(info="<html>
<p>Table 2 of the reference paper. Used for the natural circulation test.</p>
<table border=\"1\">
<tr><th>Group</th><th>beta_i</th><th>lambda_i [1/s]</th><th>half-life [s]</th></tr>
<tr><td>1</td><td>0.000208</td><td>0.0125</td><td>55.452</td></tr>
<tr><td>2</td><td>0.000830</td><td>0.0323</td><td>21.460</td></tr>
<tr><td>3</td><td>0.000595</td><td>0.1050</td><td>6.6014</td></tr>
<tr><td>4</td><td>0.001200</td><td>0.2940</td><td>2.3576</td></tr>
<tr><td>5</td><td>0.000226</td><td>1.2400</td><td>0.5590</td></tr>
<tr><td>6</td><td>0.000192</td><td>10.020</td><td>0.0680</td></tr>
<tr><td>sum</td><td>0.003251</td><td></td><td></td></tr>
</table>
<h4>The group-1 fraction is suspect, and it does not matter here</h4>
<p>The source table gives the group-1 fraction as 0.000208, digit for digit the U-235 value of
its Table 1, together with the same decay constant and half-life. Evaluated relative fractions
for U-233 usually put group 1 near 0.086 of the total, which would be about 0.00028 here,
against the 0.064 implied by the published number. A transcription slip is plausible. The value
is nevertheless reproduced <b>exactly as published</b>, because guessing at a correction would
put an invented number into what is supposed to be a reproduction of someone else's input deck.</p>

<p>Its leverage was quantified rather than argued about. Substituting a Keepin-like 0.000228
for group 1 and re-evaluating paper Eq. 8 over the natural circulation transient:</p>
<table border=\"1\">
<tr><th>group-1 beta</th><th>sum(beta)</th><th>drift at 1.46 kg/s</th><th>drift at 4.45 kg/s</th><th>change over the transient</th></tr>
<tr><td>0.000208 (as published)</td><td>0.003251</td><td>0.87 pcm</td><td>6.54 pcm</td><td>5.67 pcm</td></tr>
<tr><td>0.000228 (Keepin-like)</td><td>0.003271</td><td>0.92 pcm</td><td>6.87 pcm</td><td>5.95 pcm</td></tr>
</table>

<p>The difference over the whole transient is 0.28 pcm, against roughly 60 pcm of temperature
feedback which the paper shows to be what actually drives the power. So the ambiguity is far
below the resolution of this benchmark and cannot change any conclusion drawn from it. It is
recorded here rather than asserted anywhere, since there is no independent source at hand to
decide which value the paper's authors intended.</p>

<p>If you do have the underlying Serpent evaluation (Hanusek and Juan, Ann. Nucl. Energy 157
(2021) 108208), settling this is a one-line change to <code>alphas</code> and
<code>Beta</code>.</p>
</html>"));
end U233_6group;
