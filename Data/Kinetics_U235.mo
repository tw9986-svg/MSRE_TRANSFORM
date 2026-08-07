within MSRE.Data;
record Kinetics_U235
  "Prompt neutron generation time and reactivity coefficients for U-235 fuel (paper Table 3)"
  extends MSRE.Data.PartialKineticsData(
    Lambda=2.4e-4,
    alpha_fuel=-8.71e-5,
    alpha_graphite=-6.66e-5);

  annotation (defaultComponentName="kineticsData", Documentation(info="<html>
<p>Table 3 of the reference paper (1 pcm = 1e-5):</p>
<table border=\"1\">
<tr><th>Parameter</th><th>Value</th></tr>
<tr><td>prompt neutron generation time</td><td>2.4e-4 s</td></tr>
<tr><td>fuel temperature coefficient</td><td>-8.71 pcm/K</td></tr>
<tr><td>graphite temperature coefficient</td><td>-6.66 pcm/K</td></tr>
</table>
<p>Used together with <a href=\"modelica://MSRE.Data.PrecursorGroups.U235_6group\">U235_6group</a>
for the pump startup and pump coastdown tests.</p>
</html>"));
end Kinetics_U235;
