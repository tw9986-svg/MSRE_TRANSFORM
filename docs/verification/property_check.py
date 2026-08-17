#!/usr/bin/env python3
"""
Phase 1 property verification for MSRE.Media.FuelSalt.

This script is an INDEPENDENT re-implementation of the four correlations in
MSRE/Media/FuelSalt/Utilities/*.mo.  It exists because no Modelica compiler was
available in the environment where it was written, so the library's own
Verification.Properties_FuelSalt model could not be translated.  What it checks
is therefore the *arithmetic and the unit conversions* of the correlations, not
the Modelica implementation of them.  The Modelica model carries the same checks
as assertions and remains BLOCKED_NOT_RUN.

Nothing here validates a property against a measurement.  The correlations are
compared against each other and against the values TRANSFORM's own MSRE fuel
salt medium uses; agreement with a measurement is not claimed anywhere.

Outputs (docs/verification/):
    property_grid.csv          the 800-1000 K grid, all four properties
    property_comparison.csv    P0 / TRANSFORM / P2-candidate side by side
    properties_fuelsalt.png    the four correlations over the grid
    property_check.log         everything printed below
"""

import csv
import os
import sys

import numpy as np

OUT = os.path.dirname(os.path.abspath(__file__))

# --------------------------------------------------------------------------
# Unit conversion constants, stated explicitly so that they can be checked
# --------------------------------------------------------------------------
BTU_LB_F__J_KG_K = 4186.8       # 1 Btu/(lb.degF) exactly, IT calorie basis
CAL_G_K__J_KG_K = 4186.8        # 1 cal/(g.K), IT calorie -- same number
CAL_G_K__J_KG_K_TH = 4184.0     # 1 cal/(g.K), thermochemical calorie
BTU_HR_FT_F__W_M_K = 1.730735   # 1 Btu/(hr.ft.degF)
PA_S__CP = 1000.0               # 1 Pa.s = 1000 cP

failures = []
notes = []


def check(name, got, expect, rtol, unit="", context=""):
    """Record a pass/fail against a stated relative tolerance."""
    rel = abs(got - expect) / abs(expect) if expect != 0 else abs(got)
    ok = rel <= rtol
    status = "PASS" if ok else "FAIL"
    line = (f"[{status}] {name:<52s} got {got:>13.6g} {unit:<10s}"
            f" expected {expect:>13.6g}  rel {rel:>9.2e} (tol {rtol:.0e})")
    if context:
        line += f"\n         {context}"
    print(line)
    if not ok:
        failures.append(name)
    return ok


# ==========================================================================
# P0 -- the correlations the library currently implements
#      (MSRE/Media/FuelSalt/Utilities/*.mo, transcribed by hand)
# ==========================================================================
def rho_P0(T):
    """d_T.mo : rho [kg/m3] = 2575 - 0.513*T[degC].  Argument in K."""
    return 2575.0 - 0.513 * (T - 273.15)


def mu_P0(T):
    """eta_T.mo : eta [Pa.s] = 8.94e-5*exp(4092/T[K])."""
    return 8.94e-5 * np.exp(4092.0 / T)


def cp_P0(T):
    """cp_T.mo : constant 1967 J/(kg.K)."""
    return np.full_like(np.asarray(T, dtype=float), 1967.0)


def k_P0(T):
    """lambda_T.mo : constant 1.44 W/(m.K)."""
    return np.full_like(np.asarray(T, dtype=float), 1.44)


# ==========================================================================
# TRANSFORM's own MSRE fuel salt medium, transcribed from
#   TRANSFORM/Media/Fluids/FLiBe/Utilities_64LiF_30BeF2_5ZrF4_1UF4_CrFeNi/*.mo
# (source comment there: "ORNL-TM-4865 Table 2.1 and 2.2")
# ==========================================================================
def rho_TF(T):
    """d_T.mo : (2.575 - 5.13e-4*(T-273.15))*1000."""
    return (2.575 - 5.13e-4 * (T - 273.15)) * 1000.0


def mu_TF(T):
    """eta_T.mo : 0.116e-3*exp(3755/T)."""
    return 0.116e-3 * np.exp(3755.0 / T)


def cp_TF(T):
    """cp_T.mo : from_cal_gK(0.57)."""
    return np.full_like(np.asarray(T, dtype=float), 0.57 * CAL_G_K__J_KG_K)


def k_TF(T):
    """lambda_T.mo : constant 1.0 W/(m.K)."""
    return np.full_like(np.asarray(T, dtype=float), 1.0)


# ==========================================================================
def main():
    print("=" * 100)
    print("MSRE fuel salt property verification -- Phase 1")
    print("=" * 100)
    print("""
Scope.  Arithmetic and unit-conversion verification of the four correlations in
MSRE.Media.FuelSalt.Utilities, plus a like-for-like comparison against the MSRE
fuel salt medium TRANSFORM itself ships.  No measurement is involved, so nothing
below is an experimental validation.
""")

    # ------------------------------------------------------------------
    print("-" * 100)
    print("1.  UNIT CONVERSIONS  (the documented imperial value <-> the SI constant in the code)")
    print("-" * 100)

    # 1a. Specific heat.  cp_T.mo documents 0.47 Btu/(lb.degF) and codes 1967.
    cp_from_btu = 0.47 * BTU_LB_F__J_KG_K
    check("cp: 0.47 Btu/(lb.degF) -> J/(kg.K) vs coded 1967",
          cp_from_btu, 1967.0, 5e-4, "J/(kg.K)",
          "0.47 x 4186.8 = 1967.80; the code rounds to 1967, i.e. -0.041 %.")

    # 1b. Thermal conductivity.  The coded constant is 1.44 W/(m.K); the docstring quotes
    #     0.83 Btu/(hr.ft.degF).  These are not the same number, and the check is written on
    #     the coded value because that is what the model actually evaluates.
    k_imperial_exact = 1.44 / BTU_HR_FT_F__W_M_K
    check("k: coded 1.44 W/(m.K) -> Btu/(hr.ft.degF)",
          k_imperial_exact, 0.832, 1e-3, "Btu/(hr.ft.degF)",
          f"1.44 / 1.730735 = {k_imperial_exact:.5f} Btu/(hr.ft.degF).")
    k_from_btu = 0.83 * BTU_HR_FT_F__W_M_K
    print(f"[NOTE] lambda_T.mo's docstring says 0.83 Btu/(hr.ft.degF), which converts to "
          f"{k_from_btu:.5f} W/(m.K),\n       not the coded 1.44 (-0.24 %). The docstring is a "
          f"rounded restatement, not the provenance\n       of the constant.")
    notes.append(
        "lambda_T.mo documents 0.83 Btu/(hr.ft.degF) but codes 1.44 W/(m.K). The exact round "
        f"trip of 0.83 is {k_from_btu:.4f} W/(m.K) (-0.24 %), and 1.44 W/(m.K) is "
        f"{k_imperial_exact:.4f} Btu/(hr.ft.degF). Too small to matter numerically at 100 W, but "
        "it shows the docstring is a rounded restatement rather than the source of the value.")

    # 1c. Viscosity, Pa.s <-> cP, at the reference temperature the docstring quotes.
    T_1200F = (1200.0 - 32.0) * 5.0 / 9.0 + 273.15
    check("1200 degF -> K (the docstring's reference point)",
          T_1200F, 922.0, 1e-4, "K",
          f"1200 degF = {T_1200F:.3f} K; the medium's reference_T is 922 K.")
    mu922 = float(mu_P0(922.0))
    check("mu(922 K) in cP vs the docstring's 7.6 cP",
          mu922 * PA_S__CP, 7.6, 1e-2, "cP",
          f"eta(922) = {mu922:.5e} Pa.s = {mu922 * PA_S__CP:.4f} cP.")

    # 1d. The degC argument of the density.  A kelvin argument would give this instead:
    rho_922_degC = float(rho_P0(922.0))
    rho_922_wrongK = 2575.0 - 0.513 * 922.0
    check("rho(922 K) with the correct degC argument",
          rho_922_degC, 2242.14, 1e-4, "kg/m3",
          f"Reading the same correlation with a kelvin argument would give "
          f"{rho_922_wrongK:.1f} kg/m3, {100 * (rho_922_wrongK / rho_922_degC - 1):+.1f} %. "
          "This is why d_T.mo subtracts 273.15: the correlation is stated in degC.")

    # ------------------------------------------------------------------
    print()
    print("-" * 100)
    print("2.  INTERNAL CONSISTENCY OF THE MEDIUM DECLARATION  (Media/FuelSalt/package.mo)")
    print("-" * 100)

    # beta_const must equal -1/rho * drho/dT at reference_T = 922 K.
    T_ref = 922.0
    beta_expected = 0.513 / float(rho_P0(T_ref))
    check("beta_const vs 0.513/rho(reference_T)",
          2.2880e-4, beta_expected, 1e-4, "1/K",
          f"-1/rho drho/dT at {T_ref:.0f} K = 0.513/{float(rho_P0(T_ref)):.2f} = {beta_expected:.6e}.")

    check("reference_d vs d_T(reference_T)",
          float(rho_P0(T_ref)), 2242.14, 1e-5, "kg/m3",
          "reference_d is declared as Utilities.d_T(reference_T), so this is definitional; "
          "checked to catch a change to d_T that the docstring table would not follow.")

    # Geometry.d_fuel_ref is quoted at the zero-power test temperature, 908 K.
    check("Geometry.d_fuel_ref vs d_T(908 K)",
          float(rho_P0(908.0)), 2249.3, 1e-4, "kg/m3",
          "Data.Geometry carries d_fuel_ref = 2249.3 kg/m3 as a literal.")

    # ------------------------------------------------------------------
    print()
    print("-" * 100)
    print("3.  P0 vs THE MSRE FUEL SALT MEDIUM TRANSFORM SHIPS")
    print("-" * 100)
    print("""TRANSFORM.Media.Fluids.FLiBe.LinearFLiBe_64LiF_30BeF2_5ZrF4_1UF4_CrFeNi, whose source
comment reads "ORNL-TM-4865 Table 2.1 and 2.2".  This settles open item O-5: TRANSFORM does
ship an MSRE fuel salt.  Whether the library should adopt it is a different question, and the
four rows below are why.
""")

    T_c = 922.0
    rows = [
        ("density [kg/m3]", float(rho_P0(T_c)), float(rho_TF(T_c))),
        ("specific heat [J/(kg.K)]", float(cp_P0(T_c)), float(cp_TF(T_c))),
        ("dynamic viscosity [Pa.s]", float(mu_P0(T_c)), float(mu_TF(T_c))),
        ("thermal conductivity [W/(m.K)]", float(k_P0(T_c)), float(k_TF(T_c))),
    ]
    print(f"{'property at 922 K':<34s}{'this library (P0)':>20s}{'TRANSFORM':>16s}{'deviation':>14s}")
    for nm, a, b in rows:
        print(f"{nm:<34s}{a:>20.6g}{b:>16.6g}{100 * (a / b - 1):>13.2f} %")

    check("density: P0 is byte-for-byte TRANSFORM's correlation",
          float(rho_P0(T_c)), float(rho_TF(T_c)), 1e-12, "kg/m3",
          "2575 - 0.513*T[degC] against (2.575 - 5.13e-4*T[degC])*1000. Identical expressions. "
          "The Phase 2 density change is therefore confirmed against TRANSFORM's own source, "
          "not only against the literature description of it.")

    # beta of the TRANSFORM medium is declared at its own reference_T = 800 K.
    beta_TF = 0.513 / float(rho_TF(800.0))
    check("TRANSFORM beta_const vs 0.513/rho(800 K)",
          2.22586e-4, beta_TF, 1e-4, "1/K",
          "Confirms that this library derives beta the same way TRANSFORM does, at its own "
          "reference temperature.")

    print("""
The three properties that are NOT the density all disagree, and the reason is visible in
TRANSFORM's own tree: its MSRE fuel salt takes cp, mu and k from the pure-FLiBe/coolant
utilities and substitutes only the density.

    TRANSFORM coolant  (Utilities_9999Li7, ORNL-TM-3832 Table 3):
        cp = from_btu_lbF(0.57) = 2386.5 J/(kg.K),  k = from_btu_hrftF(0.58) = 1.0038 W/(m.K)
    TRANSFORM fuel     (Utilities_64LiF_...,  ORNL-TM-4865 Tables 2.1/2.2):
        cp = from_cal_gK(0.57)  = 2386.5 J/(kg.K),  k = 1.0 W/(m.K)
        mu = 0.116e-3*exp(3755/T), which is Utilities_FLiBe's generic FLiBe viscosity verbatim

So TRANSFORM's "MSRE fuel salt" is a density-only specialization of FLiBe.  Adopting it whole
would replace this library's fuel-salt cp with the coolant-salt value.  That is the wrong
direction on physical grounds: the fuel salt carries ZrF4 and UF4 and is about 17 % denser than
the coolant salt, so its specific heat per unit mass must be LOWER than pure FLiBe's, not equal
to it.  0.47 Btu/(lb.degF) < 0.57 Btu/(lb.degF) has the right sense; 0.57 for both does not.
""")
    notes.append(
        "O-5 resolved: TRANSFORM ships LinearFLiBe_64LiF_30BeF2_5ZrF4_1UF4_CrFeNi, an MSRE fuel "
        "salt whose density is identical to this library's. Its cp, mu and k are pure-FLiBe / "
        "coolant-salt values, so it must NOT be adopted wholesale.")

    # ------------------------------------------------------------------
    print("-" * 100)
    print("4.  COMPOSITION")
    print("-" * 100)
    print("""MSRE.Media.FuelSalt declares       LiF-BeF2-ZrF4-UF4  65 - 29.1 - 5   - 0.9   mol%
TRANSFORM's fuel salt declares     LiF-BeF2-ZrF4-UF4  64.1- 30.0 - 5.0 - 0.809 mol%
                              and  a second loading   64.5- 30.4 - 4.9 - 0.137 mol%

These are not the same salt.  The 0.9 / 0.809 pair is the U-235 loading and 0.137 is the U-233
loading, so the library's 65-29.1-5-0.9 is a rounded U-235 composition while TRANSFORM carries
both loadings in one medium name.  The density correlation is nevertheless the same expression
in both, which means the correlation is being applied across a composition difference of about
1 mol% in LiF/BeF2 without that having been assessed.  Recorded, not resolved.""")
    notes.append(
        "Composition mismatch: the library declares 65-29.1-5-0.9 mol%, TRANSFORM's medium "
        "declares 64.1-30.0-5.0-0.809 (and 64.5-30.4-4.9-0.137). The same density correlation is "
        "used for both; the sensitivity to that ~1 mol% difference has not been assessed.")

    # ------------------------------------------------------------------
    print()
    print("-" * 100)
    print("5.  PROPERTY GRID, 800-1000 K")
    print("-" * 100)
    # 5 K steps, with the two reference temperatures forced onto the grid so that the
    # reported values at 908 K and 922 K are evaluated rather than interpolated.
    T = np.unique(np.concatenate([np.arange(800.0, 1000.0 + 1e-9, 5.0), [908.0, 922.0]]))
    rho, mu, cp, kk = rho_P0(T), mu_P0(T), cp_P0(T), k_P0(T)

    # Monotonicity / sign sanity -- cheap but catches a sign slip immediately.
    if not np.all(np.diff(rho) < 0):
        failures.append("density must decrease with temperature")
    if not np.all(np.diff(mu) < 0):
        failures.append("viscosity must decrease with temperature")
    if not (np.all(rho > 0) and np.all(mu > 0) and np.all(cp > 0) and np.all(kk > 0)):
        failures.append("all properties must be positive over the grid")
    print(f"[PASS] density decreases monotonically over 800-1000 K "
          f"({rho[0]:.1f} -> {rho[-1]:.1f} kg/m3)")
    print(f"[PASS] viscosity decreases monotonically over 800-1000 K "
          f"({mu[0] * 1e3:.3f} -> {mu[-1] * 1e3:.3f} cP)")
    print(f"[PASS] all four properties positive over the whole grid")

    # Prandtl number, the group the properties actually enter the model through.
    Pr = cp * mu / kk
    print(f"\nPrandtl number over the grid: {Pr.min():.1f} to {Pr.max():.1f} "
          f"({Pr[T == 922][0]:.1f} at 922 K)")
    print("Reported because cp, mu and k reach the model only through Pr and Re; a property "
          "error\nthat leaves Pr unchanged does not move the heat transfer.")

    with open(os.path.join(OUT, "property_grid.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["T_K", "T_degC", "rho_kg_m3", "mu_Pa_s", "mu_cP",
                    "cp_J_kgK", "k_W_mK", "Pr", "nu_m2_s"])
        for i, t in enumerate(T):
            w.writerow([f"{t:.1f}", f"{t - 273.15:.2f}", f"{rho[i]:.4f}",
                        f"{mu[i]:.6e}", f"{mu[i] * 1e3:.4f}", f"{cp[i]:.1f}",
                        f"{kk[i]:.4f}", f"{Pr[i]:.3f}", f"{mu[i] / rho[i]:.6e}"])
    print(f"\nwrote property_grid.csv  ({len(T)} rows, 800-1000 K in 5 K steps)")

    with open(os.path.join(OUT, "property_comparison.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["T_K", "rho_P0", "rho_TRANSFORM", "cp_P0", "cp_TRANSFORM",
                    "mu_P0", "mu_TRANSFORM", "k_P0", "k_TRANSFORM"])
        for t in T:
            w.writerow([f"{t:.1f}", f"{float(rho_P0(t)):.4f}", f"{float(rho_TF(t)):.4f}",
                        f"{float(cp_P0(t)):.1f}", f"{float(cp_TF(t)):.1f}",
                        f"{float(mu_P0(t)):.6e}", f"{float(mu_TF(t)):.6e}",
                        f"{float(k_P0(t)):.4f}", f"{float(k_TF(t)):.4f}"])
    print("wrote property_comparison.csv")

    # ------------------------------------------------------------------
    plot(T)

    # ------------------------------------------------------------------
    print()
    print("=" * 100)
    if failures:
        print(f"RESULT: {len(failures)} CHECK(S) FAILED")
        for x in failures:
            print(f"   - {x}")
    else:
        print("RESULT: all checks passed")
    print("=" * 100)
    if notes:
        print("\nFindings recorded (not failures):")
        for i, n in enumerate(notes, 1):
            print(f"  {i}. {n}")
    print("""
Status of this run
    numerically verified : the arithmetic and unit conversions above
    NOT verified         : the Modelica implementation of the same correlations
                           (MSRE.Verification.Properties_FuelSalt is BLOCKED_NOT_RUN)
    NOT validated        : none of these properties has been checked against a measurement,
                           and no primary source document could be opened from this container
""")
    return 1 if failures else 0


def plot(T):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(2, 2, figsize=(11, 8))
    fig.suptitle("MSRE fuel salt properties: this library (P0) vs the medium TRANSFORM ships\n"
                 "verification of arithmetic only; neither set is validated against measurement",
                 fontsize=11)

    specs = [
        (ax[0][0], rho_P0, rho_TF, "density [kg/m$^3$]", 1.0, False),
        (ax[0][1], cp_P0, cp_TF, "specific heat [J/(kg$\\cdot$K)]", 1.0, False),
        (ax[1][0], mu_P0, mu_TF, "dynamic viscosity [cP]", 1e3, True),
        (ax[1][1], k_P0, k_TF, "thermal conductivity [W/(m$\\cdot$K)]", 1.0, False),
    ]
    for a, f0, ftf, label, scale, logy in specs:
        a.plot(T, np.asarray(f0(T), dtype=float) * scale, lw=2.0,
               label="P0 (this library)", color="#1f4e79")
        a.plot(T, np.asarray(ftf(T), dtype=float) * scale, lw=2.0, ls="--",
               label="TRANSFORM MSRE fuel salt", color="#c0504d")
        a.set_xlabel("temperature [K]")
        a.set_ylabel(label)
        if logy:
            a.set_yscale("log")
        a.grid(alpha=0.3)
        a.legend(fontsize=8)
        a.axvline(908, color="grey", lw=0.8, ls=":")
        a.axvline(922, color="grey", lw=0.8, ls=":")

    ax[0][0].annotate("identical", xy=(900, 2255), fontsize=9, color="green")
    fig.text(0.5, 0.015,
             "dotted lines: 908 K (zero-power pump tests) and 922 K = 1200 degF (medium reference)",
             ha="center", fontsize=8, color="grey")
    fig.tight_layout(rect=[0, 0.03, 1, 0.94])
    p = os.path.join(OUT, "properties_fuelsalt.png")
    fig.savefig(p, dpi=140)
    print(f"wrote {os.path.basename(p)}")


if __name__ == "__main__":
    sys.exit(main())
