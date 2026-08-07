within MSRE.Data;
partial record PartialKineticsData
  "Base record: prompt neutron generation time and reactivity coefficients"
  extends Modelica.Icons.Record;

  parameter SI.Time Lambda "Prompt neutron generation time";
  parameter Real alpha_fuel(unit="1/K") "Fuel salt temperature reactivity coefficient";
  parameter Real alpha_graphite(unit="1/K")
    "Graphite moderator temperature reactivity coefficient";

  annotation (defaultComponentName="kineticsData");
end PartialKineticsData;
