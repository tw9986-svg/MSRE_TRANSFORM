within MSRE.Data;
record Kinetics_U233
  "Prompt neutron generation time and reactivity coefficients for U-233 fuel (paper Table 3)"
  extends MSRE.Data.PartialKineticsData(
    Lambda=4.0e-4,
    alpha_fuel=-11.3e-5,
    alpha_graphite=-5.81e-5);

  annotation (defaultComponentName="kineticsData", Documentation(info="<html>
<p>Table 3 of the reference paper (1 pcm = 1e-5):</p>
<table border=\"1\">
<tr><th>Parameter</th><th>Value</th></tr>
<tr><td>prompt neutron generation time</td><td>4.0e-4 s</td></tr>
<tr><td>fuel temperature coefficient</td><td>-11.3 pcm/K</td></tr>
<tr><td>graphite temperature coefficient</td><td>-5.81 pcm/K</td></tr>
</table>
<p>Used together with <a href=\"modelica://MSRE.Data.PrecursorGroups.U233_6group\">U233_6group</a>
for the natural circulation test.</p>
</html>"));
end Kinetics_U233;
