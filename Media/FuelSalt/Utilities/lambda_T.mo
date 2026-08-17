within MSRE.Media.FuelSalt.Utilities;
function lambda_T "Thermal conductivity of the MSRE fuel salt"
  extends Modelica.Icons.Function;
  input SI.Temperature T "Temperature";
  output SI.ThermalConductivity lambda "Thermal conductivity";
algorithm
  lambda := 1.44;
  annotation (Inline=true, Documentation(info="<html>
<p>1.44 W/(m.K), which is 0.8320 Btu/(hr.ft.degF). The value 0.83 Btu/(hr.ft.degF) is often
quoted for the MSRE fuel salt and converts to 1.4365 W/(m.K), 0.24 % below the constant coded
here; the two are close but they are not the same number, so the imperial figure is a rounded
restatement rather than the provenance of this constant.</p>

<p><b>Source level: source-unverified.</b> No primary document stating this value has been
opened. Two independent modern points of comparison put the MSRE fuel-salt conductivity near
1.0 W/(m.K) rather than 1.44: TRANSFORM's own MSRE fuel salt medium codes 1.0, and its
coolant-salt medium codes 0.58 Btu/(hr.ft.degF) = 1.0038 W/(m.K). A 44 % spread between the
MSRE-era value and the modern one is not a rounding difference and is not resolved here.</p>

<p>It does not reach the zero-power pump tests, where the power is 100 W and heat transfer is
negligible. It is first-order for the full-power and natural-circulation cases, so it must be
traced before either is reported. See
<a href=\"modelica://MSRE.Media.MSRE_Properties\">MSRE_Properties</a>.</p>
</html>"));
end lambda_T;
