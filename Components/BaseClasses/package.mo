within MSRE.Components;
package BaseClasses "Partial models shared by the MSRE components"
  extends Modelica.Icons.BasesPackage;

  annotation (Documentation(info="<html>
<p>Partial models that exist so that two component implementations can be exchanged for one
another through a <code>replaceable</code> declaration. Nothing here is meant to be
instantiated directly.</p>
</html>"));
end BaseClasses;
