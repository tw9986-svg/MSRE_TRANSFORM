within MSRE;
package Media "Molten-salt thermophysical property models for the MSRE"
  extends Modelica.Icons.Package;

  package CoolantSalt
    "MSRE secondary coolant salt LiF-BeF2 66-34 mol%, 99.99% Li-7 (TRANSFORM built-in)"
    extends TRANSFORM.Media.Fluids.FLiBe.LinearFLiBe_9999Li7_pT;

    /* See MSRE.Media.FuelSalt.massFraction for why this is here: Modelica Standard Library 4.1.0
       added massFraction to Modelica.Media.Interfaces.PartialMedium, which no TRANSFORM medium
       has, so the TRANSFORM salt no longer matches that constraining package. This package is
       otherwise the TRANSFORM built-in unchanged - the extends adds the missing function and
       nothing else. */
    function massFraction "Return independent mass fractions (if any)"
      extends Modelica.Icons.Function;
      input ThermodynamicState state "Thermodynamic state record";
      output MassFraction Xi[nXi] "Independent mass fractions";
    algorithm
      Xi := fill(0, 0);
      annotation (Inline=true);
    end massFraction;

    annotation (Documentation(info="<html>
<p>The MSRE secondary coolant salt was LiF-BeF2 66-34 mol% with Li enriched in Li-7, which is
exactly the salt TRANSFORM ships as
<a href=\"modelica://TRANSFORM.Media.Fluids.FLiBe.LinearFLiBe_9999Li7_pT\">LinearFLiBe_9999Li7_pT</a>
(ORNL-TM-3832 Table 3). The built-in model is therefore used rather than restating the same
correlations here: this package adds nothing to it but the <code>massFraction</code> function
that Modelica Standard Library 4.1.0 requires of a medium and TRANSFORM does not supply.</p>

<h4>Agreement with the reported MSRE coolant-salt values at 922 K (1200 degF)</h4>
<table border=\"1\">
<tr><th>Property</th><th>TRANSFORM built-in</th><th>Reported MSRE value</th><th>Deviation</th></tr>
<tr><td>density [kg/m3]</td><td>1942</td><td>1922</td><td>+1.0 %</td></tr>
<tr><td>specific heat [J/(kg.K)]</td><td>2386</td><td>2390</td><td>-0.2 %</td></tr>
<tr><td>dynamic viscosity [Pa.s]</td><td>6.81e-3</td><td>~6.8e-3</td><td>&lt;1 %</td></tr>
<tr><td>thermal conductivity [W/(m.K)]</td><td>1.00</td><td>1.0</td><td>~0 %</td></tr>
</table>

<p>Note that the built-in model carries <code>reference_T = T_default = 800 K</code>. This is
harmless here because every secondary-side start temperature in
<a href=\"modelica://MSRE.Systems.PrimarySystem\">PrimarySystem</a> is set explicitly from
<code>T_coolant_start</code>; none of them falls back on <code>Medium.T_default</code>.</p>
</html>"));
  end CoolantSalt;

  package FuelSalt_U235 =
      MSRE.Media.FuelSalt (
      extraPropertiesNames={"dnp1","dnp2","dnp3","dnp4","dnp5","dnp6"},
      C_nominal={43.3,97.5,25.6,24.8,1.83,0.104})
    "MSRE fuel salt carrying the six U-235 delayed-neutron precursor groups as trace substances"
    annotation (Documentation(info="<html>
<p>The six trace substances are the delayed-neutron precursor groups of paper Table 1.
<code>C_nominal</code> is only a numerical scaling factor: it is set to the stagnant
steady-state precursor content per kilogram of fuel salt,
<code>beta_j/(lambda_j*Lambda*m_core)</code>, evaluated with
<code>Lambda = 2.4e-4 s</code>, <code>m_core = 1600 kg</code> and a neutron population
<code>N = 1</code>.</p>
</html>"));

  package FuelSalt_U233 =
      MSRE.Media.FuelSalt (
      extraPropertiesNames={"dnp1","dnp2","dnp3","dnp4","dnp5","dnp6"},
      C_nominal={26.0,40.2,8.85,6.38,0.285,0.0299})
    "MSRE fuel salt carrying the six U-233 delayed-neutron precursor groups as trace substances"
    annotation (Documentation(info="<html>
<p>As <a href=\"modelica://MSRE.Media.FuelSalt_U235\">FuelSalt_U235</a> but with the U-233
precursor data of paper Table 2 and <code>Lambda = 4.0e-4 s</code>.</p>
</html>"));

  annotation (Documentation(info="<html>
<p>Both salts are modelled as linear (weakly compressible) fluids using the TRANSFORM
<code>PartialLinearFluid</code> interface, which is the standard treatment of molten salts
in TRANSFORM.</p>

<p>The coolant salt <i>is</i> a TRANSFORM built-in
(<code>LinearFLiBe_9999Li7_pT</code>). The fuel salt is not: TRANSFORM's only fuelled salt is
<code>LinearFLiBe_12Th_05U_pT</code>, the MSBR salt LiF-BeF2-ThF4-UF4 71.5-16-12-0.5 mol%,
whose 12 mol% ThF4 makes it 52 % denser than the MSRE fuel salt (3337 vs 2189 kg/m3 at 922 K).
Substituting it at the rated 168 kg/s would stretch the fuel-salt transit time by the same
factor, from 25.5 s to roughly 39 s, and so destroy the delayed-neutron-precursor drift
behaviour that these benchmarks exist to test. <a href=\"modelica://MSRE.Media.FuelSalt\">FuelSalt</a> is therefore defined
here, using the same TRANSFORM base class as the built-in salts. Its properties are those of
Cantor, ORNL-TM-2316 (1968), as used by the INL MSRE VTB/SAM model; see
<a href=\"modelica://MSRE.Media.MSRE_Properties\">MSRE_Properties</a>.</p>
</html>"));
end Media;
