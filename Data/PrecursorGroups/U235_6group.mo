within MSRE.Data.PrecursorGroups;
record U235_6group "MSRE 6-group delayed neutron data for U-235 fuel (paper Table 1)"
  extends TRANSFORM.Nuclear.ReactorKinetics.Data.PrecursorGroups.PartialPrecursorGroup(
    extraPropertiesNames={"dnp1","dnp2","dnp3","dnp4","dnp5","dnp6"},
    C_nominal={43.3,97.5,25.6,24.8,1.83,0.104},
    lambdas={0.0125,0.0318,0.1090,0.3170,1.3500,8.6400},
    alphas={0.000208,0.001190,0.001070,0.003020,0.000948,0.000345}/0.006781,
    Beta=0.006781);
  annotation (defaultComponentName="data", Documentation(info="<html>
<p>Table 1 of the reference paper (originally from Hanusek and Juan, Ann. Nucl. Energy 157
(2021) 108208). Used for the pump startup and pump coastdown tests.</p>
<table border=\"1\">
<tr><th>Group</th><th>beta_i</th><th>lambda_i [1/s]</th><th>half-life [s]</th></tr>
<tr><td>1</td><td>0.000208</td><td>0.0125</td><td>55.452</td></tr>
<tr><td>2</td><td>0.001190</td><td>0.0318</td><td>21.797</td></tr>
<tr><td>3</td><td>0.001070</td><td>0.1090</td><td>6.3591</td></tr>
<tr><td>4</td><td>0.003020</td><td>0.3170</td><td>2.1866</td></tr>
<tr><td>5</td><td>0.000948</td><td>1.3500</td><td>0.5134</td></tr>
<tr><td>6</td><td>0.000345</td><td>8.6400</td><td>0.0802</td></tr>
<tr><td>sum</td><td>0.006781</td><td></td><td></td></tr>
</table>
</html>"));
end U235_6group;
