within MSRE.Verification;
model CoreTH_Baseline
  "1D equivalent-channel MSRE core thermal-hydraulic baseline: fixed flow, fixed inlet temperature, fixed volumetric power"
  extends Modelica.Icons.Example;

  import TRANSFORM;

  replaceable package Medium = MSRE.Media.FuelSalt_U235 constrainedby
    Modelica.Media.Interfaces.PartialMedium
    "Fuel salt property model" annotation (choicesAllMatching=true);

  MSRE.Data.Geometry geometry "MSRE reference geometry";

  /* ----------------------------------------------------------------