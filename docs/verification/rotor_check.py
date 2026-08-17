#!/usr/bin/env python3
"""
Phase 4 / section 8.2 -- verification of the pump rotor ODE against its closed-form solutions.

WHAT THIS IS.  MSRE.Components.FuelPump_Dynamics integrates

    J*der(omega) = tau_motor - tau_hyd - tau_fric,   tau_hyd = tau_hyd_nominal*omega*|omega|/omega_n^2

With the default friction (zero) that ODE has closed-form solutions, and this script integrates
it numerically and compares.  This is a verification of the *equation*, carried out outside
Modelica.  It is NOT a run of the Modelica model, and it is NOT a validation of the pump against
any measurement -- there is no measured MSRE pump speed or flow history in this repository.

WHAT IT IS ALSO FOR.  The library's documentation states that startup "reaches 98.7 % of rated
flow in 10 s".  tanh(10/4) = 0.9866 is the SHAFT SPEED.  The flow is a different variable,
separated from the speed by the loop momentum balance.  Section 3 puts a number on that
separation so the documentation can be corrected to something defensible.

No third-party solver is used: RK4 with a step small enough that the error is far below the
quantities being compared, which is checked by halving it.
"""

import csv
import os
import sys

import numpy as np

OUT = os.path.dirname(os.path.abspath(__file__))

# ---------------------------------------------------------------------------
# Parameters, exactly as MSRE.Components.FuelPump_Dynamics defaults them via
# MSRE.Data.Geometry (ORNL density, 908 K).
# ---------------------------------------------------------------------------
N_NOMINAL = 1160.0                       # rpm
OMEGA_N = 2 * np.pi * N_NOMINAL / 60.0   # rad/s
DP_NOMINAL = 3.0e5                       # Pa
M_FLOW_NOMINAL = 168.0                   # kg/s
D_FUEL = 2249.3                          # kg/m3 at 908 K
ETA_IS = 0.8
TAU_SHAFT = 4.0                          # s, the single fitted parameter
HEAD_RATIO_SHUTOFF = 1.25

V_FLOW_N = M_FLOW_NOMINAL / D_FUEL                       # m3/s
P_HYD = DP_NOMINAL * V_FLOW_N                            # W
TAU_HYD_N = P_HYD / (OMEGA_N * ETA_IS)                   # N.m
J = TAU_SHAFT * TAU_HYD_N / OMEGA_N                      # kg.m2

failures = []


def check(name, got, expect, atol, unit="", context=""):
    err = abs(got - expect)
    ok = err <= atol
    print(f"[{'PASS' if ok else 'FAIL'}] {name:<54s} got {got:>12.7g} {unit:<7s}"
          f" exact {expect:>12.7g}  |err| {err:>9.2e} (tol {atol:.0e})")
    if context:
        print(f"         {context}")
    if not ok:
        failures.append(name)
    return ok


def rk4(f, y0, t):
    """Fixed-step RK4."""
    y = np.empty((len(t),) + np.shape(y0), dtype=float)
    y[0] = y0
    for i in range(len(t) - 1):
        h = t[i + 1] - t[i]
        k1 = f(t[i], y[i])
        k2 = f(t[i] + h / 2, y[i] + h / 2 * k1)
        k3 = f(t[i] + h / 2, y[i] + h / 2 * k2)
        k4 = f(t[i] + h, y[i] + h * k3)
        y[i + 1] = y[i] + h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
    return y


def rotor_rhs(u_motor):
    """der(omega) for the rotor, with zero friction (the model's default)."""
    tau_motor_nominal = TAU_HYD_N   # tau_fric_coulomb = tau_fric_viscous = 0

    def f(_t, w):
        tau_motor = tau_motor_nominal * u_motor
        tau_hyd = TAU_HYD_N * w * abs(w) / OMEGA_N ** 2
        return np.array([(tau_motor - tau_hyd) / J])
    return f


def main():
    print("=" * 100)
    print("Pump rotor ODE verification -- Phase 4, section 8.2")
    print("=" * 100)
    print(f"""
Derived parameters (nothing here is fitted except tau_shaft):
    omega_nominal      {OMEGA_N:10.4f} rad/s   ({N_NOMINAL:.0f} rpm)
    V_flow_nominal     {V_FLOW_N:10.6f} m3/s   (168 kg/s at {D_FUEL:.1f} kg/m3)
    P_hydraulic        {P_HYD / 1e3:10.4f} kW     (dp_nominal * V_flow_nominal)
    tau_hyd_nominal    {TAU_HYD_N:10.4f} N.m    (that power / (omega_n * eta_is))
    tau_shaft          {TAU_SHAFT:10.4f} s      <-- FITTED effective parameter, not a measured inertia
    J                  {J:10.4f} kg.m2  (follows from tau_shaft; NOT independent of it)

Note on J.  J and tau_shaft are one degree of freedom written two ways, and the model exposes
both. Only one may ever be set. No measured MSRE fuel-pump moment of inertia is in hand, so J is
a *derived* consequence of a fitted time constant and must not be reported as a rotor property.
""")

    # ------------------------------------------------------------------
    print("-" * 100)
    print("1.  STARTUP FROM REST   ->   omega/omega_n = tanh(t/tau_shaft)")
    print("-" * 100)
    t = np.arange(0.0, 40.0 + 1e-12, 1e-3)
    w = rk4(rotor_rhs(1.0), np.array([0.0]), t)[:, 0]
    x_num = w / OMEGA_N
    x_exact = np.tanh(t / TAU_SHAFT)
    err = np.max(np.abs(x_num - x_exact))
    print(f"max |numerical - tanh| over 0-40 s : {err:.3e}")
    if err > 1e-9:
        failures.append("startup ODE does not reproduce tanh")
    else:
        print("[PASS] the rotor ODE integrates to tanh(t/tau_shaft) to 1e-9")

    for ts in (4.0, 8.0, 10.0, 16.0):
        i = int(round(ts / 1e-3))
        check(f"startup speed ratio at t = {ts:>4.1f} s",
              x_num[i], float(np.tanh(ts / TAU_SHAFT)), 1e-9)

    i10 = int(round(10.0 / 1e-3))
    print(f"""
    ---> at 10 s the SHAFT SPEED is {100 * x_num[i10]:.2f} % of rated.
         This is the origin of the "98.7 %" in the documentation. It is a speed, not a flow.
""")

    # ------------------------------------------------------------------
    print("-" * 100)
    print("2.  COASTDOWN FROM RATED   ->   omega/omega_0 = 1/(1 + t/tau_shaft)")
    print("-" * 100)
    t2 = np.arange(0.0, 60.0 + 1e-12, 1e-3)
    w2 = rk4(rotor_rhs(0.0), np.array([OMEGA_N]), t2)[:, 0]
    x2_num = w2 / OMEGA_N
    x2_exact = 1.0 / (1.0 + t2 / TAU_SHAFT)
    err2 = np.max(np.abs(x2_num - x2_exact))
    print(f"max |numerical - hyperbola| over 0-60 s : {err2:.3e}")
    if err2 > 1e-9:
        failures.append("coastdown ODE does not reproduce the hyperbola")
    else:
        print("[PASS] the rotor ODE integrates to 1/(1+t/tau_shaft) to 1e-9")

    for ts, label in ((4.0, "one tau_shaft -> exactly half"),
                      (20.0, "20 s -> one sixth"),
                      (36.0, "36 s -> one tenth")):
        i = int(round(ts / 1e-3))
        check(f"coastdown speed ratio at t = {ts:>4.1f} s",
              x2_num[i], 1.0 / (1.0 + ts / TAU_SHAFT), 1e-9, "", label)
    print(f"""
    The three rows PumpCoastdown_RotorDynamics tells a reader to check:
        N at t_null            {N_NOMINAL * x2_num[0]:7.1f} rpm   (doc says 1160)
        N at t_null + 4 s      {N_NOMINAL * x2_num[4000]:7.1f} rpm   (doc says  580)
        N at t_null + 20 s     {N_NOMINAL * x2_num[20000]:7.1f} rpm   (doc says  193)
    All three confirmed against the ODE.
""")

    # ------------------------------------------------------------------
    print("-" * 100)
    print("3.  STEP-SIZE CONVERGENCE  (that the 1e-9 above is the ODE, not the integrator)")
    print("-" * 100)
    for h in (4e-3, 2e-3, 1e-3, 5e-4):
        tt = np.arange(0.0, 10.0 + 1e-12, h)
        ww = rk4(rotor_rhs(1.0), np.array([0.0]), tt)[-1, 0] / OMEGA_N
        print(f"    h = {h:.0e} s   ratio(10 s) = {ww:.12f}   "
              f"|err| = {abs(ww - np.tanh(10.0 / TAU_SHAFT)):.3e}")
    print("    RK4 is fourth order, so the error falls by ~16x per halving; it is already far\n"
          "    below anything being compared.")

    # ------------------------------------------------------------------
    print()
    print("-" * 100)
    print("4.  WHY THE SPEED RESULT MUST NOT BE RESTATED AS A FLOW RESULT")
    print("-" * 100)
    print("""
The flow is separated from the speed by the loop momentum balance,

    I * dQ/dt = dp_pump(Q, N) - R_loop * Q|Q|,    I = rho * sum(L_i/A_i)

so the flow can only follow the speed instantaneously if I is negligible. It is not zero, and
the estimate below says how far from zero it is. THIS IS A BOUNDING ESTIMATE, NOT THE LIBRARY'S
ANSWER: it lumps the loop into one inertia and one resistance, whereas PrimarySystem distributes
momentum over TRANSFORM pipe volumes, splits the core into 15 parallel rings and includes
buoyancy. Only the Modelica model can produce the real number, and it has not been run.
""")
    # Sum L/A around the loop from Data.Geometry.
    segs = [
        ("fuel channels", 1.6406, 0.4315),
        ("lower plenum", 0.30, 0.0777 / 0.30),
        ("upper plenum", 0.30, 0.0777 / 0.30),
        ("outlet riser", 4.00, np.pi / 4 * 0.1286 ** 2),
        ("pump bowl", 0.60, 0.150 / 0.60),
        ("pump discharge", 5.00, np.pi / 4 * 0.1286 ** 2),
        ("HX shell", 2.44, 0.266 / 2.44),
        ("HX outlet pipe", 7.00, np.pi / 4 * 0.1286 ** 2),
        ("downcomer", 2.40, 0.432371 / 2.40),
    ]
    print(f"    {'segment':<18s}{'L [m]':>9s}{'A [m2]':>11s}{'L/A [1/m]':>12s}")
    tot = 0.0
    for nm, L, A in segs:
        tot += L / A
        print(f"    {nm:<18s}{L:>9.4f}{A:>11.5f}{L / A:>12.2f}")
    print(f"    {'sum L/A':<18s}{'':>9s}{'':>11s}{tot:>12.2f}")

    I_loop = D_FUEL * tot
    R_loop = DP_NOMINAL / V_FLOW_N ** 2
    R_pump_dp = (HEAD_RATIO_SHUTOFF - 1.0) * DP_NOMINAL / V_FLOW_N ** 2
    print(f"""
    I = rho*sum(L/A)   = {I_loop:.4e} kg/m4
    R_loop             = {R_loop:.4e} Pa.s2/m6   (rated duty: 3.0 bar at {V_FLOW_N:.5f} m3/s)
    dp_pump(Q,N)       = 1.25*dp_n*(N/N_n)^2 - {R_pump_dp:.4e}*Q|Q|
""")

    def flow_rhs(t_, y):
        Q = y[0]
        x = float(np.tanh(t_ / TAU_SHAFT))          # speed ratio from part 1
        dp_pump = HEAD_RATIO_SHUTOFF * DP_NOMINAL * x ** 2 - R_pump_dp * Q * abs(Q)
        return np.array([(dp_pump - R_loop * Q * abs(Q)) / I_loop])

    tq = np.arange(0.0, 40.0 + 1e-12, 1e-4)
    Q = rk4(flow_rhs, np.array([0.0]), tq)[:, 0]
    q = Q / V_FLOW_N
    i10q = int(round(10.0 / 1e-4))
    speed10 = float(np.tanh(10.0 / TAU_SHAFT))

    print(f"    {'t [s]':>7s}{'speed/rated':>14s}{'flow/rated':>13s}{'flow - speed':>15s}")
    for ts in (1.0, 2.0, 5.0, 10.0, 15.0, 20.0):
        i = int(round(ts / 1e-4))
        s = float(np.tanh(ts / TAU_SHAFT))
        print(f"    {ts:>7.1f}{s:>14.4f}{q[i]:>13.4f}{q[i] - s:>15.4f}")

    tau_flow = I_loop * V_FLOW_N / (2 * DP_NOMINAL)
    print(f"""
    ---> at 10 s the FLOW is {100 * q[i10q]:.2f} % of rated, against {100 * speed10:.2f} % for the speed.

    The two are close because the hydraulic time constant, I*Q_n/(2*dp_n) = {tau_flow:.3f} s, is
    about {TAU_SHAFT / tau_flow:.0f}x shorter than tau_shaft = {TAU_SHAFT:.1f} s, so the flow tracks the speed with
    only a short lag. That is a *result*, not a licence to use the words interchangeably: the
    closeness is a property of this loop's inertia and would not survive a heavier loop, a
    faster rotor, or the coastdown into natural circulation. The documentation should state the
    98.7 % as a speed and quote the flow separately once the model has been run.
""")

    with open(os.path.join(OUT, "rotor_startup.csv"), "w", newline="") as f:
        wtr = csv.writer(f)
        wtr.writerow(["t_s", "N_rpm", "speed_ratio_numeric", "speed_ratio_tanh",
                      "abs_err", "flow_ratio_lumped_estimate"])
        for ts in np.arange(0.0, 40.0 + 1e-9, 0.1):
            i = int(round(ts / 1e-3))
            iq = int(round(ts / 1e-4))
            wtr.writerow([f"{ts:.1f}", f"{N_NOMINAL * x_num[i]:.4f}", f"{x_num[i]:.10f}",
                          f"{np.tanh(ts / TAU_SHAFT):.10f}",
                          f"{abs(x_num[i] - np.tanh(ts / TAU_SHAFT)):.3e}", f"{q[iq]:.6f}"])
    with open(os.path.join(OUT, "rotor_coastdown.csv"), "w", newline="") as f:
        wtr = csv.writer(f)
        wtr.writerow(["t_s", "N_rpm", "speed_ratio_numeric", "speed_ratio_hyperbola", "abs_err"])
        for ts in np.arange(0.0, 60.0 + 1e-9, 0.1):
            i = int(round(ts / 1e-3))
            wtr.writerow([f"{ts:.1f}", f"{N_NOMINAL * x2_num[i]:.4f}", f"{x2_num[i]:.10f}",
                          f"{1.0 / (1.0 + ts / TAU_SHAFT):.10f}",
                          f"{abs(x2_num[i] - 1.0 / (1.0 + ts / TAU_SHAFT)):.3e}"])
    print("    wrote rotor_startup.csv, rotor_coastdown.csv")

    plot(t, x_num, x_exact, t2, x2_num, x2_exact, tq, q)

    print()
    print("=" * 100)
    if failures:
        print(f"RESULT: {len(failures)} CHECK(S) FAILED")
        for x in failures:
            print("   -", x)
    else:
        print("RESULT: all checks passed")
    print("=" * 100)
    print("""
Status
    numerically verified : the rotor ODE reproduces both closed-form speed laws to 1e-9, and
                           one tau_shaft produces both, which is the property the model claims
    NOT verified         : the MODELICA implementation of this ODE. This script re-implements
                           the equation; it does not execute FuelPump_Dynamics.
    NOT validated        : no measured MSRE pump speed or flow history was used or is present
                           in this repository. Section 8.3 fitting is BLOCKED -- reference data
                           missing.
""")
    return 1 if failures else 0


def plot(t, x, xe, t2, x2, x2e, tq, q):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(1, 3, figsize=(15, 4.6))
    fig.suptitle("Pump rotor ODE vs closed form -- verification outside Modelica "
                 "(the Modelica model itself has not been run)", fontsize=11)

    ax[0].plot(t, xe, lw=4, color="#c9d6e4", label="exact  tanh(t/$\\tau$)")
    ax[0].plot(t, x, lw=1.4, color="#1f4e79", label="RK4 of the rotor ODE")
    ax[0].axhline(np.tanh(2.5), color="grey", ls=":", lw=0.9)
    ax[0].axvline(10, color="grey", ls=":", lw=0.9)
    ax[0].annotate(f"{100 * np.tanh(2.5):.1f} % at 10 s\n(SPEED)", xy=(11, 0.80), fontsize=9)
    ax[0].set_title("startup, motor on")
    ax[0].set_xlabel("time [s]"); ax[0].set_ylabel("$\\omega/\\omega_{nominal}$")

    ax[1].plot(t2, x2e, lw=4, color="#e4cdc9", label="exact  $1/(1+t/\\tau)$")
    ax[1].plot(t2, x2, lw=1.4, color="#c0504d", label="RK4 of the rotor ODE")
    ax[1].set_title("coastdown, motor tripped")
    ax[1].set_xlabel("time [s]"); ax[1].set_ylabel("$\\omega/\\omega_0$")

    ax[2].plot(t, xe, lw=2, color="#1f4e79", label="shaft speed (exact)")
    ax[2].plot(tq, q, lw=2, ls="--", color="#4f8a3d", label="flow, lumped-loop estimate")
    ax[2].axvline(10, color="grey", ls=":", lw=0.9)
    ax[2].set_xlim(0, 25)
    ax[2].set_title("speed is not flow\n(lumped estimate, not the library's momentum balance)",
                    fontsize=10)
    ax[2].set_xlabel("time [s]"); ax[2].set_ylabel("fraction of rated")

    for a in ax:
        a.grid(alpha=0.3); a.legend(fontsize=8, loc="lower right")
    fig.tight_layout(rect=[0, 0, 1, 0.92])
    fig.savefig(os.path.join(OUT, "rotor_verification.png"), dpi=140)
    print("    wrote rotor_verification.png")


if __name__ == "__main__":
    sys.exit(main())
