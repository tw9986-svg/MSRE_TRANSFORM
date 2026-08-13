# MARS-KS 벤치마킹 잔재에 대한 비판적 검토

**대상**: 이 저장소의 `MSRE` 패키지 (v0.2.2)
**벤치마킹 대상 (수치 대조·통과 판정 기준)**: J.J. Jeong et al., *Benchmarking the MARS code for MSR applications using MSRE transient experiments*, NET 58 (2026) 104438 — 이하 **MARS 논문**
**구현 참고용 (수치 대조 대상 아님)**: L. Fischer, L. Bureš, *Application of Modelica/TRANSFORM to system modeling of the MSRE*, NED 416 (2024) 112768 — 이하 **Fischer**
**구현 참고용**: TRANSFORM-Library (ORNL-Modelica), 실제 소스 대조 완료

> **스코프 주의.** 이 문서에서 Fischer 를 인용한 부분은 전부 *구현 참고*이며, Fischer 의 수치와
> 본 모델의 결과가 다르다는 사실만으로 통과·불통과를 판정하지 않는다. 통과 판정 기준은
> [`benchmark_scope.md`](benchmark_scope.md) 에만 있다. 특히 §C1–C6 의 "권고: Fischer" 는
> *배선·방법론을 참고하라*는 뜻이지 *Fischer 의 값에 맞추라*는 뜻이 아니다.

---

## 0. 요약

이 모델은 MARS 논문의 **결과**뿐 아니라 **MARS라는 코드가 가진 구조적 제약**까지 함께 이식했습니다.
시스템 코드(MARS/RELAP 계열)는 (a) 정상상태 초기화 기능이 없고, (b) 점동특성 모듈이 스칼라 β를
입력으로 요구하며, (c) closure를 사용자 코드로 갈아끼울 수 없고, (d) 매질 물성/펌프 곡선이
입력 카드로 고정됩니다. Modelica/TRANSFORM에는 이 네 가지 제약이 **전부 없습니다**.
그런데 현재 구현은 네 가지 모두를 그대로 재현하고 있습니다.

가장 심각한 것부터:

| # | 항목 | 성격 | 영향 |
|---|---|---|---|
| **A1** | `t_null` null transient (600 s / 5000 s) | MARS의 초기화 부재를 이식 | 계산량 수 배, 결과에는 기여 없음 |
| **A2** | `Beta_eff` 를 `when` 으로 동결 | MARS 점동특성 모듈의 입력 요구를 이식 | 물리적 β를 버림, 이산 상태 발생 |
| **C1** | `phis_adjoint = fill(1, nV)` | MARS 논문의 단순화를 이식 | **Eq. 4 가중 기계장치 전체가 무력화** |
| **C3** | Geometry 를 MARS의 transit time 에 역산 | 대상 코드의 파생량에 피팅 | 채널 체적 +30 %, plena 1/4.7 배 |
| **A3** | 점동특성 모델 자체 재작성 | TRANSFORM 기존 자산 미사용 | 붕괴열·FP·Xe-135 경로 차단 |

`C1` 은 질문에서 언급하신 "중요도 가중치" 부분과 정확히 맞물립니다. 아래 §3.1 참조.

---

## 1. 검토 기준

"벤치마킹해야 하는 것"과 "MARS의 구현상 편의"를 구분하는 기준을 먼저 세웁니다.

* **벤치마킹 대상 (유지해야 함)** — 물리 모델(Eq. 3의 DNP 수송, Eq. 5의 반응도 모델),
  실험 시나리오, 원자력 데이터(Table 1–3), 그리고 비교 대상 수치(226.5 pcm, 25.5 s 주기 등).
* **MARS의 구현 편의 (이식하면 안 되는 것)** — 초기화 절차, 이산화 방식, 노드 수,
  스칼라 β 입력, closure 선택지 부재, 입력 카드로 고정된 물성.

두 번째 범주를 그대로 옮기면, TRANSFORM으로 프레임워크를 만든다는 목적 자체가 훼손됩니다.
"MARS로 할 수 있는 것을 Modelica로도 할 수 있다"는 증명은 되지만,
"Modelica로만 할 수 있는 것"은 하나도 남지 않기 때문입니다.

---

## 2. 구조·프레임워크 레벨 (최우선)

### A1. Null transient — 가장 명확한 이식 오류

**현재 구현**

```modelica
// Nuclear/PointKinetics_DNPtransport.mo:20
parameter SI.Time t_null=0 "Null transient duration: ...";
protected Boolean released = time >= t_null;
der(N) = if released and not use_servoControl then (...) else 0;
```

```modelica
// Experiments/PumpStartup.mo:5      t_null = 600
// Experiments/PumpCoastdown.mo:5    t_null = 600
// Experiments/NaturalCirculation.mo:6  t_null = 5000
```

그리고 `Systems/PrimarySystem.mo:89`:

```modelica
inner TRANSFORM.Fluid.SystemTF systemTF(
    energyDynamics=TRANSFORM.Types.Dynamics.FixedInitial,   // → massDynamics → traceDynamics
    momentumDynamics=TRANSFORM.Types.Dynamics.DynamicFreeInitial)
```

`traceDynamics` 는 `massDynamics` → `energyDynamics` = `FixedInitial` 을 상속합니다.
즉 400여 개 유체 셀 × 6개 trace substance 상태가 모두 `C_start = 0` 에서 출발해,
Tolerance 1e-6 으로 600 s(자연순환은 5000 s)를 적분한 뒤에야 비로소 실험이 시작됩니다.

**왜 MARS는 그렇게 하는가** — MARS/RELAP 계열에는 정상상태 해석기가 없습니다.
정상상태는 "과도해석기를 충분히 오래 돌려서 얻는 것"이며, 이것이 null transient입니다.
MARS 논문이 이 절차를 기술한 것은 물리가 아니라 코드의 한계 때문입니다.

**Modelica/TRANSFORM에는 이 한계가 없습니다.** 확인한 사실:

* `TRANSFORM/Types/Dynamics.mo` 에 `SteadyStateInitial` 이 존재
  ("Dynamic balance, Steady state initial with guess value").
* `TRANSFORM/Fluid/SystemTF.mo:27` 에 `traceDynamics` 파라미터가 독립적으로 존재.
* `TRANSFORM/Fluid/Pipes/BaseClasses/PartialDistributedVolume.mo:144` 에서
  `traceDynamics == Dynamics.SteadyStateInitial` 일 때 `der(Cs) = 0` 을 초기 방정식으로 부과.

**수정 방향**

```modelica
inner TRANSFORM.Fluid.SystemTF systemTF(
    energyDynamics   = TRANSFORM.Types.Dynamics.SteadyStateInitial,
    traceDynamics    = TRANSFORM.Types.Dynamics.SteadyStateInitial,
    momentumDynamics = TRANSFORM.Types.Dynamics.SteadyStateInitial);
```

* **PumpStartup** — 정체 상태이므로 셀별로 `0 = source_i − λ_i·mC_i`,
  즉 `mC_i = β_i N /(Λ λ_i)` 라는 **해석해**입니다. 600 s 적분이 전혀 필요 없고,
  결과가 더 정확합니다(600 s는 group 1 반감기 55.5 s의 약 11배로 "거의" 수렴한 상태일 뿐).
* **PumpCoastdown / NaturalCirculation** — 유동이 있는 정상상태이므로 비선형
  초기화 문제가 되지만, 이것이 바로 Dymola 초기화 solver가 하는 일입니다.

**예상 효과**: `NaturalCirculation` 은 StopTime 26000 s 중 5000 s(19 %)가 순수 낭비이고,
`PumpStartup` 은 750 s 중 600 s(80 %)가 낭비입니다. 이 부분이 제거되면 파라미터 스터디
(논문의 C1–C4 민감도 케이스)를 돌리는 비용이 근본적으로 달라집니다.

> **주의할 점**: `SteadyStateInitial` 로 바꾸면 초기화 문제가 커지므로 좋은 초기 추정값이
> 필요합니다. `C_start` 를 0 대신 위 해석해로 주면 초기화가 잘 수렴합니다.
> 단계적으로 가려면 trace만 먼저 `SteadyStateInitial` 로 바꾸고 나머지는 유지하는 것이
> 안전합니다.

---

### A2. `Beta_eff` 동결 — 물리적 β를 버린 자리

**현재 구현** (`Nuclear/PointKinetics_DNPtransport.mo:77, 101–104, 115`)

```modelica
discrete SIadd.NonDim Beta_eff(start=data.Beta, fixed=true);
when released then
  Beta_eff = Beta_eff_inst;
  vals_reference = if use_frozenReference then vals_feedback else vals_feedback_reference;
end when;
der(N) = ... (rho - Beta_eff)/Lambda*N + sum(lambdas .* Cs) ...;
```

**비판**. 점동특성 방정식의 β는 **핵데이터 상수**입니다 — 핵분열 중성자 중 지발 중성자가
차지하는 분율. 순환연료라고 해서 이 값이 바뀌지 않습니다. 순환 때문에 바뀌는 것은
`Σ λ_i C_i` 항이고, 노심 밖에서 붕괴한 선구체만큼 이 항이 작아지면서
**drift 반응도가 자동으로 나타납니다**. 즉 물리적으로 올바른 식은

```
der(N) = (rho − β_static)/Λ · N + Σ λ_i C_i(t)
```

이며, `β_circ` 는 방정식에 넣는 파라미터가 아니라 정상상태에서 **읽어내는 진단량**
(`β_circ = Λ Σλ_i C_i / N`)입니다.

MARS가 `β_eff` 를 동결하는 이유는 코드 구조 때문입니다. MARS의 점동특성 모듈은
입력 카드로 스칼라 β를 받으므로, 초기 상태를 임계로 만들려면 β를 순환값으로
바꿔 넣는 수밖에 없습니다. Fischer 논문도 같은 문제에 다르게 대응합니다
(Eq. 11의 정규화 상수 K 도입).

**현 구현이 "틀린 답"을 주지는 않습니다** — pump 시험에서 보고하는 것은
`rho_servo = Beta_eff − Beta_eff_inst` 라는 **차이**이므로 오프셋은 상쇄됩니다.
문제는 대가입니다:

1. `discrete` 변수 + `when` → 이벤트 발생, 초기화 solver와 상성이 나쁨,
   `t_null` 없이는 동작 불가 (A1과 결합되어 있음).
2. `Beta_eff` 를 얻으려면 **반드시 과도해석을 돌려야** 합니다. drift 반응도를
   파라미터로 뽑아낼 수 없습니다.
3. 실제 β와 모델 β가 달라져서, 외부 반응도 삽입(Fischer §4.2.1의 스텝 삽입 시험)을
   할 때 `ρ/β` 비가 어긋납니다. Fischer가 Eq. 21에서 지적한 바로 그 문제입니다.

**수정 방향** — 동결 대신 **초기 임계 반응도를 초기화 미지수로**:

```modelica
final parameter SIadd.NonDim Beta = data.Beta "Static delayed neutron fraction (nuclear data)";
parameter SIadd.NonDim rho_0(fixed=false) "Initial critical reactivity offset (= −drift reactivity)";
...
initial equation
  0 = (rho_0 - Beta)/Lambda*N + sum({lambdas[j]*Cs[j] for j in 1:nC});   // 초기 임계 조건
equation
  rho = rho_0 + rho_input + sum(rhos_feedback);
  der(N) = (rho - Beta)/Lambda*N + sum({lambdas[j]*Cs[j] for j in 1:nC});
```

이렇게 하면

* `when` / `discrete` 소멸, `t_null` 불필요,
* **`rho_0` 자체가 drift 반응도**이므로 `driftReactivity` (Eq. 8)와 **파라미터 수준에서**
  직접 비교 가능 — 현재는 750 s 지점의 과도해 값을 읽어야 함
  (`Verification/Transient_DriftReactivity.mo` 전체가 단순해집니다),
* 피드백 기준 온도도 `parameter Real vals_reference[nFeedback](each fixed=false)` +
  `initial equation vals_reference = vals_feedback` 로 동일하게 처리 가능.

---

### A3. 점동특성 모델을 처음부터 다시 작성

TRANSFORM에는 **이미 이 모델이 있습니다**:
`TRANSFORM.Nuclear.ReactorKinetics.PointKinetics_L1_atomBased_external`

소스 대조 결과 (`PointKinetics_L1_atomBased_external.mo:242–265`):

| 기능 | TRANSFORM 내장 | 이 저장소 |
|---|---|---|
| `nV` 개 셀의 `mCs[nV,nC]` 를 유체에서 입력받음 | O (line 28) | O |
| `Vs[nV]` 입력 | O (line 25) | O |
| `SF_Q_fission[nV]` 출력 형상 | O (line 221) | O (`SF`) |
| `mC_gens` 에 **붕괴항 포함**해서 반환 | O (line 260–261) | 부분 (컴포넌트마다 수기) |
| 선형 반응도 피드백 `nFeedback` | O (line 243) | O |
| `specifyPower` (출력 고정) | O (line 249) | 유사 (`use_servoControl`) |
| `energyDynamics` / `SteadyStateInitial` | O (line 234–241) | X |
| 붕괴열 (`Qs_decay`) | O | X |
| 핵분열생성물 / Xe-135 반응도 | O (`fissionProducts`) | X |
| 삼중수소 | O | X |
| 원자 단위(ν, w_f) 기반 → 절대 농도 비교 가능 | O | X (`N` 임의 스케일) |

또한 `TRANSFORM/Nuclear/ReactorKinetics/Examples/PointKinetics_Drift_Test_flat.mo` 는
**core + loop 순환 선구체 drift 문제 자체가 이미 예제로 들어 있습니다**
(`core_inlet.use_C_in` 으로 루프 출구 농도를 노심 입구로 되먹임).

**내장 모델에 없는 것은 딱 하나** — Eq. 4의 **수반속(adjoint) 중요도 가중**입니다.
내장 모델은 `sum({sum(lambdas .* mCs[i,:]) for i in 1:nV})` 로 균일 가중만 합니다.

**수정 방향**: 자체 모델을 유지하되 **`PointKinetics_L1_atomBased_external` 를 상속(extends)해서
가중항만 재정의**하거나, 최소한 `Data.summary_traceSubstances` 구조와
원자 단위 기저(ν, w_f)를 맞추십시오. 그래야

* 붕괴열, Xe-135 를 나중에 "켜기"만 하면 되고 (프레임워크 목적에 직결),
* `mCs` 가 atoms 단위가 되어 Fischer Fig. 10의 ORNL DNP 붕괴율 데이터
  (s⁻¹·kg⁻¹)와 **직접** 비교 가능해집니다.
  현재는 `N_start=1` 에 묶인 임의 스케일이라 절대 비교가 불가능하고,
  `U235_6group` 의 `C_nominal={43.3, 97.5, ...}` 도 그 스케일과 정합하지 않아
  solver의 trace 오차 제어가 잘못 작동합니다.

---

### A4. 붕괴항 `−λ·mC` 를 컴포넌트마다 수기 복제

현재 같은 식이 **세 군데**에 흩어져 있습니다:

```modelica
// Components/SaltPipe.mo:101
mC_gens_total[i,j] = mC_sources[i,j] - lambdas[j]*pipe.mCs[i,j];
// Components/CoreChannel.mo:136
mC_gens_total[i,j] = mC_sources[i,j] - lambdas[j]*pipe.mCs[i,j]*nParallel;
// Systems/PrimarySystem.mo:297   ← 시스템 모델 안에 물리식이 들어감
mC_gens_hxShell[i,j] = -data_PG.lambdas[j]*hx.shell.mCs[i,j];
```

이것은 Fischer 논문 Eq. 13("custom sink term")을 그대로 옮긴 것이고, MARS에서는
사용자 소스 항을 카드로 넣는 것 외에 방법이 없으므로 자연스럽습니다.
하지만 TRANSFORM에는 **closure 교체 메커니즘**이 있습니다.

**수정 방향** — `MSRE/ClosureRelations/PrecursorDecay.mo` 하나 만들기:

```modelica
model PrecursorDecay "Precursor transport RHS: fission source minus local decay"
  extends TRANSFORM.Fluid.ClosureRelations.InternalTraceGeneration.Models.
          DistributedVolume_Trace_1D.PartialInternalTraceGeneration;
  parameter Real nParallel = 1 "Must match the host pipe's nParallel";
  parameter SIadd.InverseTime lambdas[Medium.nC] = zeros(Medium.nC);
  input SIadd.ExtraPropertyFlowRate mC_sources[nV,Medium.nC] = zeros(nV, Medium.nC)
    "Fission production, total over all parallel channels";
equation
  for i in 1:nV loop
    for ic in 1:Medium.nC loop
      mC_flows[i,ic] = mC_sources[i,ic]
                     - lambdas[ic]*Cs[i,ic]*Medium.density(states[i])*Vs[i]*nParallel;
    end for;
  end for;
end PrecursorDecay;
```

인터페이스 확인 완료:
`PartialInternalTraceGeneration` 은 `Cs[nV,nC]` (질량비 농도), `Vs[nV]`, `states[nV]` 를
이미 입력으로 갖고 있으므로 `mCs` 는 `Cs·ρ·V` 로 재구성됩니다
(`PartialDistributedVolume.mo:156` 의 `mCs[i,:] = ms[i].*Cs[i,:]` 와 동일).
`GenericPipe_MultiTransferSurface.mo:211–219` 를 보면 closure 에 넘어가는 `Vs` 는
**단일 채널 기준**이고, 같은 파일 line 363 에서 `internalTraceGen.mC_flows[i,:]/nParallel`
로 나누므로 `mC_flows` 는 **병렬 전체 합** 이어야 합니다. 위 식의 `*nParallel` 이 그 이유이며,
이는 현재 `CoreChannel.mo:136` 이 손으로 하고 있는 것과 정확히 같은 규약입니다.
(반대로 `SaltPipe.mo:101` 에는 `nParallel` 이 없는데, `SaltPipe` 는 항상 `nParallel=1`
이므로 우연히 맞습니다 — 이런 암묵적 가정이 closure로 옮기면 사라집니다.)

그 다음 `redeclare model InternalTraceGen = MSRE.ClosureRelations.PrecursorDecay(...)`
한 줄로 끝납니다. 이득:

* 유체 컴포넌트를 새로 붙일 때 붕괴항을 **잊을 수 없게** 됩니다.
  현재 구조에서는 열교환기 shell 처럼 시스템 모델에서 손으로 배선해야 하므로,
  HX를 재노달라이즈하면 조용히 틀립니다.
* HX shell 의 붕괴항 처리에서 `nParallel` 이 빠져 있는지 여부 같은 실수를 원천 차단.
  (`CoreChannel` 은 `*nParallel` 이 있고 `SaltPipe` 는 없는데, `hx.shell` 은
  `nParallel` 이 1인지 확인이 필요합니다 — 현재 코드는 이 검증을 독자에게 떠넘깁니다.)

---

## 3. 물리 입력 레벨 — "벤치마킹 대상을 잘못 고른" 부분

### C1. 중요도 가중이 사실상 꺼져 있음 ★ (질문하신 지점)

```modelica
// Systems/PrimarySystem.mo:83
final parameter SIadd.NonDim phis_adjoint[nV_core] = fill(1, nV_core)
  "Neutron importance of each core cell (unity, as assumed throughout the paper)";
```

`PointKinetics_DNPtransport.mo:92–95` 의 Eq. 4 구현:

```modelica
Cs[j] = sum({phis_adjoint[i]*mCs[i,j]}) / sum({phis_adjoint[i]*phis[i]*Vs[i]}) * sum(Vs);
```

`phis_adjoint = 1` 이면 분모는 `Σ φ_i V_i` 인데, `phis_core` 는
`SF_i·ΣV/V_i` 로 정의되어 있으므로 `Σ φ_i V_i = ΣV·ΣSF = ΣV` 입니다.
따라서 **`Cs[j] = Σ_i mCs[i,j]`**, 즉 노심 내 선구체의 **단순 총합**입니다.
Eq. 4의 가중 기계장치 전체가 항등식으로 붕괴합니다.

이것은 MARS 논문의 단순화를 그대로 받은 것이지만, **Fischer는 여기서 훨씬 더 나갑니다**:

* Fischer Eq. 9: `ASF_j ∝ WIF_j / SF_j` 로 수반 형상함수를 **ORNL 문헌
  (Engel & Haubenreich, ORNL-TM-0378, 1962)의 WIF 로부터 유도**.
* Fischer Table 3의 실제 값:

  | 구성요소 | Σ SF | Σ WIF |
  |---|---|---|
  | Downcomer | 0.03 | 7.0 × 10⁻⁵ |
  | Inlet plenum | 0.03 | 1.6 × 10⁻⁴ |
  | Outlet plenum | 0.06 | 7.0 × 10⁻⁴ |
  | Fuel channels | 0.83 | 0.999 |
  | Graphite | 0.05 | (1.00, α_g 전용) |

* Fischer §4.1.2 원문: *"the loss of reactivity due to flowing fuel is very sensitive to
  the flow velocity and shape functions used in the model, **especially ASF_radial and
  the weights associated with the plena**."*

즉 **plena의 중요도 가중이 drift 반응도의 1차 민감 인자**라고 선행연구가 명시하고 있는데,
현 모델은 그 부분을 균일 1로 두고 있습니다. 게다가 이 모델은 하부 plenum 마지막 노드와
상부 plenum 첫 노드를 "노심"으로 포함시키므로(`Geometry.mo:21–23`), plena 셀에
채널 셀과 **동일한 중요도**를 주고 있습니다 — Fischer의 데이터에 따르면 실제 중요도는
채널 대비 10⁻³~10⁻⁴ 수준입니다.

**수정 방향**

1. `phis_adjoint` 를 `Geometry` 레코드의 노출 파라미터로 승격하고,
   Fischer Table 3 / ORNL-TM-0378의 WIF로부터 유도한 기본값을 넣을 것.
   plena 셀에는 채널 대비 ~10⁻³ 수준의 값을 주어야 합니다.
2. `fill(1, nV_core)` 는 **MARS 교차검증용 옵션**으로 남기고 기본값에서 내릴 것.
3. Fischer Eq. 11의 정규화 `K = 1/Σ(ASF_j·SF_j)` 와 현재 코드의 정규화
   `ΣV / Σ(φ†_i φ_i V_i)` 가 `φ†≠1` 일 때 서로 다릅니다. 어느 쪽을 쓸지 명시하고
   `Verification` 에 항등식 검사(`φ†=1` 일 때 두 정규화가 일치)를 추가할 것.
4. **이것이 MARS 대비 이 프레임워크의 실질적 우위가 될 수 있는 지점입니다.**
   MARS는 입력 카드로 노드별 중요도를 주기 어렵지만, Modelica에서는 배열 파라미터
   하나입니다. 두 결과(균일 vs ORNL WIF)를 나란히 제시하면 그 자체로 논문이 됩니다.

---

### C2. 출력/속 형상: 해석 함수 vs 공개된 ORNL 실측 데이터

현재 (`Functions/corePowerShape.mo`, `Data/Geometry.mo:64–73`):

* 축방향 — `cos(π(z−L/2)/(1.2·L))` 순수 코사인.
* 반경방향 — J0 형상 + 25 % reflector saving 을 손으로 만든 15개 값.
* README 근거: *"The paper takes it from a Serpent calculation that is not public."*

**그런데 Fischer는 Serpent를 쓰지 않습니다.** Fischer §2.2:

> *"the axial ... and radial ... shape functions were determined with the help of the
> **relative fuel fission reaction rate data from Haubenreich (1964)**, see Figs. 1 and 2"*

Haubenreich (1964)는 공개된 ORNL 문헌입니다. 즉 **MARS 논문의 비공개 입력을 대체할
공개 데이터가 이미 선행 TRANSFORM 연구에 명시되어 있는데**, 이 저장소는 그것을 쓰지 않고
해석 함수를 만들었습니다. MARS를 벤치마킹한다는 이유로 MARS의 입력 출처를 따라간 결과입니다.

또한 Fischer Fig. 1의 실측 축방향 fission density는 **대칭 코사인이 아닙니다**
(반사체·plena 영향으로 비대칭). 현재의 대칭 코사인은 상·하부 plenum 노드에
동일한 선원 분율을 주는데, Fischer Table 3은 inlet 0.03 / outlet 0.06 으로
**2배 차이**를 줍니다.

**수정 방향**: `Data/PowerShapes.mo` 레코드를 만들어 Haubenreich(1964) 축·반경 방향
fission rate 를 테이블로 넣고, `corePowerShape` 는 그 테이블을 적분해서 셀별 SF를
내도록 변경. 현재의 해석 형상은 `f_analytic=true` 옵션으로 남길 것.

---

### C3. Geometry — MARS의 파생량에 역산 피팅 ★

`Data/Geometry.mo` 문서 원문:

> *"The volumes here are therefore **calibrated to reproduce the transit times reported
> in the paper**"* (core 9.56 s, loop 16.14 s)

검증 결과 계산은 정확합니다:

| 항목 | 계산값 |
|---|---|
| `V_channels` = 1140 × 3.9198e-4 × 1.626 | **0.7266 m³** |
| `V_core` | 0.7784 m³ |
| `V_loop` | 1.3143 m³ |
| `V_total` | 2.0927 m³ (MSRE 실측 약 73 ft³ = 2.073 m³ — 양호) |
| τ_core @ ρ=2063 | 9.558 s ✔ |
| τ_loop @ ρ=2063 | 16.139 s ✔ |

**총량은 맞지만 분배가 Fischer와 크게 다릅니다:**

| | 이 저장소 | Fischer | 비 |
|---|---|---|---|
| 연료 채널 체적 | 0.7266 m³ | 0.5601 m³ (1140 × 2.89 cm² × 170 cm) | **+30 %** |
| 하부 plenum | 0.0777 m³ | 0.359 m³ (0.283 + 1 s 체류 0.076) | **1/4.6** |
| 상부 plenum | 0.0777 m³ | 0.373 m³ (0.297 + 1 s 체류 0.076) | **1/4.8** |
| 채널 유로면적 | 3.92 cm² | 2.89 cm² (설계값) | +36 % |
| 채널당 전열면적 | 1434 cm² | 1309 cm² (설계값) | +10 % |
| Downcomer | 0.5869 m³ ("잔량 흡수") | 별도 |

Fischer는 유로면적 2.89 cm²와 전열면적 1309 cm²가 **설계값과 일치한다**고 명시합니다
(§3.2). MSRE 노심 채널 내 염 체적은 ORNL 문헌상 약 20 ft³ ≈ 0.57 m³ 로 알려져 있어
Fischer 쪽과 일관됩니다.

**왜 문제인가**: C1에서 본 것처럼 채널과 plena는 중요도가 10³ 배 차이 납니다.
따라서 **노심 체적의 채널/plena 분배 비율이 drift 반응도를 직접 결정합니다.**
transit time 총합만 맞추는 피팅은 이 분배를 전혀 구속하지 못합니다.
현재 모델은 노심 인벤토리의 93 % 를 고중요도 채널에 넣고 있으나,
설계값 기준으로는 그보다 훨씬 적습니다.

**추가로 밀도 상관식이 미해결입니다.** TRANSFORM에는 MSRE 연료염 매질이
**이미 들어 있습니다**:

```
TRANSFORM.Media.Fluids.FLiBe.LinearFLiBe_64LiF_30BeF2_5ZrF4_1UF4_CrFeNi
  // ORNL-TM-4865 Table 2.1 and 2.2
  d(T) = (2.575 − 5.13e-4·(T−273.15))·1000   →  922 K 에서 2242 kg/m³
```

이 저장소는 `2575.3 − 0.5641·T[K]` → 922 K 에서 **2055 kg/m³** 를 씁니다.
**9 % 차이**이고, τ = V·ρ/ṁ 이므로 이 차이는 보정 체적에 그대로 전가됩니다.
ρ=2242 라면 τ_core=9.56 s 를 맞추기 위한 `V_core` 는 0.7164 m³ 인데,
이는 현재의 채널 체적 0.7266 m³ 보다도 **작습니다** — 즉 현재 기하로는 불가능합니다.

관련해서 `Media/package.mo` 의 다음 서술은 **사실과 다릅니다**:

> *"TRANSFORM's only fuelled salt is `LinearFLiBe_12Th_05U_pT`, the MSBR salt"*

`LinearFLiBe_64LiF_30BeF2_5ZrF4_1UF4_CrFeNi` 가 바로 MSRE 연료염(UF₄ 포함)입니다.
(반면 냉각염 `LinearFLiBe_9999Li7_pT` 에 대한 저장소의 물성표 — 1942 kg/m³,
2386 J/kgK, 6.81e-3 Pa·s, 1.00 W/mK — 는 소스에서 재계산한 결과 **전부 정확**했습니다.)

**수정 방향**

1. 밀도·비열 상관식의 1차 출처(ORNL-TM-0728 / ORNL-TM-4865)를 확인해
   저장소 값과 TRANSFORM 값 중 어느 쪽이 MSRE 연료염인지 확정할 것.
   **이 하나가 전체 기하 보정의 전제**입니다.
2. `Geometry` 를 **설계 치수로부터 상향식으로** 재구성:
   채널 유로면적 2.89 cm², 전열면적 1309 cm²/채널, plena 0.283 / 0.297 m³ + 1 s 체류 체적.
   transit time 은 **피팅 목표가 아니라 검증 항목**으로 강등.
   (`Verification` 에 τ_core / τ_loop assert 추가 — 현재 `Analytic_DriftReactivity` 가
   간접적으로 하고 있는 것을 명시적으로.)
3. `Media/package.mo` 의 사실 오류 수정, `LinearFLiBe_64LiF_...` 를 대안 매질로
   `choicesAllMatching` 에 노출.
4. `Analytic_DriftReactivity.mo:33` 의 `d_fuel=2055.2` (922 K)와
   `Geometry` 문서의 2063 (908 K)이 섞여 쓰이고 있으니 단일 출처로 통일.

---

### C4. 흑연 발열 분율 0

```modelica
// Systems/PrimarySystem.mo:42
parameter Real f_graphiteHeating=0 "... (0 in the paper)";
```

Fischer Table 3: 흑연 ΣSF = **0.05**. 그리고 Fischer §4.1.1:

> *"The remaining discrepancy to the reference data is likely to come from the
> **different graphite heating fractions** used in the calculations."*

흑연 온도는 α_g = −6.66 pcm/K 를 통해 반응도에 직접 들어가고, 자연순환 시험은
온도 피드백이 지배적(문서 자체가 "약 4 K 하강 ≈ 60 pcm"이라고 적고 있음)이므로
이 기본값은 자연순환 결과를 편향시킵니다.

**수정**: 기본값 0.05 (또는 ORNL 값 ~0.06)로 변경하고, 0 은 MARS 교차검증 옵션으로.

---

### C5. 링별 유량 분배가 균일

`Components/ReactorCore.mo:116–138` — 15개 링 모두 동일 기하(`each crossArea`,
`each dimension`, `each length`)에 양단 압력이 같으므로 **유량이 정확히 균등 분배**됩니다.
그러나 `f_radial` 은 1.61 → 0.475 로 3.4배 차이가 납니다.

Fischer §3.2:

> *"The friction losses were set so that the flow velocity in the groups agree with
> measurements of **Kedl (1970)**."*

실제 MSRE 채널 유속은 반경 방향으로 분포가 있고, 이는 **노심 체류시간 분포 →
drift 반응도**와 **출구 온도 분포 → 속가중 평균 온도 → 피드백 반응도** 양쪽에
직접 영향을 줍니다. 현재는 3.4배 출력차를 균일 유량으로 나누므로 출구 온도 분산이
실제보다 크게 나옵니다.

**수정**: `CoreChannel` 에 링별 form loss `Ks` 또는 유효 유로면적을 노출하고,
`Geometry` 에 Kedl(1970) 유속 분포로부터 결정한 기본값을 넣을 것.

---

### C6. 노드 수 15 × 20 을 MARS와 동일하게 맞춤

`Geometry.mo:8–17`, `ReactorCore.mo` 문서: *"the channel region has 300 cells,
**exactly as in the MARS input**"*.

Fischer는 **반경 3그룹**(93 / 279 / 768 채널, 그룹별 출력이 비슷하도록 선택)을 씁니다.
MARS에서 300 볼륨은 싸지만, Modelica에서 링당 2D 흑연 전도(nR=3 × nZ=20)까지 붙으면
900개 흑연 노드 + 300 유체 셀 × 6 trace = **수천 상태**입니다. 게다가 A1의 null transient가
겹칩니다.

**노드 수를 맞추는 것은 벤치마킹이 아닙니다** — 수렴한 결과를 맞추는 것이 벤치마킹입니다.
Fischer는 Table 4에서 ex-core 노드 수 2/4/8/12 를 해석해와 비교해 **4개면 충분**하다는
수렴성 근거를 제시하고 baseline 을 정합니다. 이 저장소에는 그런 검증이 없습니다.

**수정**: `Verification/Nodalization_Convergence.mo` 를 추가해
(a) ex-core 노드 수에 대한 `ξ_i = 1 − exp(−λ_i τ_ec)` 수렴 (Fischer Table 4 재현),
(b) `nRings` / `nAxial` 에 대한 drift 반응도 수렴을 보인 뒤, 기본 노드 수를 결정할 것.
그 결과 15×20 이 필요하다고 나오면 그때 근거를 갖고 유지하면 됩니다.

---

## 4. 컴포넌트 레벨

### B1–B2. `FuelPump` 자작 및 속도 법칙 처방

`Components/FuelPump.mo` 는 2차 펌프 특성곡선, 상사법칙, N=0 시 form loss 축퇴를
직접 구현합니다. TRANSFORM에 **전부 있습니다**:

* `TRANSFORM.Fluid.Machines.Pump` — `controlType="RPM"`, `use_port=true` 로 속도 입력,
  `N_nominal` / `dp_nominal` / `m_flow_nominal` 기반 상사법칙
  (`BaseClasses/PartialPump_nom.mo:71–96`).
* 교체 가능한 유량 특성:
  `PumpCharacteristics/Flow/{Parabolic_2Region, PerformanceCurve, PerformanceCurve_table, CombiTableCurve}`
  → MSRE 실제 펌프 성능곡선(Fischer가 언급한 Jaradat 2021의 곡선)을 테이블로 넣을 수 있음.
* **`TRANSFORM.Fluid.Machines.Pump_wShaft`** — `Modelica.Mechanics.Rotational.Interfaces.Flange_a`
  샤프트. 여기에 `Modelica.Mechanics.Rotational.Components.Inertia(J=...)` 를 붙이면
  **MARS 논문이 튜닝했다는 관성모멘트 J 가 그대로 파라미터**가 됩니다.
* `PumpCharacteristics/PumpTripCoastdown.mo` — `y = x/(1 + t/t_half)`.
  `PumpCoastdown.mo:26` 의 `N_rated/(1 + (time−t_null)/tau_coast)` 와 **동일한 식**이
  이미 라이브러리에 있습니다.

**핵심 비판**: 현재 `Experiments/PumpStartup.mo:26` 과 `PumpCoastdown.mo:26` 은
펌프 속도를 **해석식으로 처방**합니다. 이는 MARS의 각운동량 방정식이 만들어낸 *결과*를
곡선으로 흉내낸 것이지, 같은 *메커니즘*이 아닙니다. MARS 논문의 민감도 사례
("관성모멘트를 절반으로")를 재현하려면 현재는 `tau_startup` 을 3.4 → 1.7 로
"다시 피팅"해야 하는데, `Pump_wShaft` + `Inertia(J)` 라면 **`J` 를 절반으로 놓기만**
하면 됩니다. 그리고 논문이 지적한 "기동은 좋아지고 관성정지는 나빠진다"는 결합 효과가
**모델에서 자동으로** 나옵니다 — 현재는 두 실험이 독립적인 두 곡선이라 그 결합이 사라집니다.

부차적으로 `FuelPump` 자체에도 문제가 있습니다:

* 유체 체적이 없어 pump bowl 인벤토리를 별도 `SaltPipe` 로 우회
  (`PrimarySystem.mo:172`). TRANSFORM `Pump` 는 내부 체적과 trace 물질 수지
  (`PartialPump.mo:28` 의 `mCb=... + mC_flow_internal`)를 갖습니다.
* `port_a.h_outflow = inStream(port_b.h_outflow) − dh` — 역류 시 펌프가 헤드를
  "빼는" 형태가 되어 비물리적. 자연순환 시험에서 펌프는 정지 상태이므로 관련됩니다.
* `head = head_shutoff·(N/N_n)² − R_pump·V|V|` 에서 N=0 시 저항 계수 `R_pump` 가
  `headRatio_shutoff` 에 묶여 있습니다. 정지 펌프의 수력 저항은 **독립적인 물리량**이며,
  자연순환 유량(1.46 → 4.45 kg/s)을 좌우하는 1차 인자입니다. 이 결합은 근거가 없습니다.

### B3. 팽창탱크가 선구체 sink

```modelica
// Systems/PrimarySystem.mo:187
TRANSFORM.Fluid.BoundaryConditions.Boundary_pT expansionTank(
    nPorts=1, p=geometry.p_system, T=T_start, C=C_start);   // C_start = zeros(nC)
```

`Boundary_pT` 는 **무한 저장조**입니다. 열팽창으로 염이 탱크로 나가면 선구체가
영구 소멸하고, 들어올 때는 `C = 0` 인 염이 주입됩니다. 등온인 pump 시험에서는
영향이 작지만, **자연순환 시험은 21000 s 동안 수 K 온도 변화**가 있어 실제 체적 교환이
발생합니다. 이는 물리에 없는 선구체 손실 경로입니다.

**수정**: `TRANSFORM.Fluid.Volumes.ExpansionTank` (또는 `ExpansionTank_1Port`) 사용.
실제 체적과 자체 trace 수지를 갖습니다.

### B4. 열전달 상관식 — TRANSFORM의 최대 강점을 안 쓴 자리

`ClosureRelations/Nus_MoltenSalt.mo`:

```modelica
Nus[i,j] = Nu_floor + f_enhance*0.023*(Res[i]^2 + Re_reg^2)^0.4*Prs[i]^0.4;
```

두 가지 지적:

**(a) 형식** — 층류항과 난류항을 **더하는** 것은 표준 상관식이 아닙니다
(천이영역에서 과대예측). TRANSFORM에는 정석 구현이 있습니다:
`Nus_SinglePhase_2Region` 은 `TRANSFORM.Math.spliceTanh(Nus_turb, Nus_lam, Res−Re_center, Re_width)`
로 매끄럽게 전환하고, `Nus_lam` 기본 4.36, `Nus_turb` 기본 Dittus–Boelter,
`L_char` 입력까지 **이미 동일한 인터페이스**(`PartialSinglePhase`, 즉 `Nus_MoltenSalt` 가
상속하는 바로 그 기저 클래스)로 제공합니다. `Re_center`/`Re_width` 는
`PartialHeatTransfer_setT.mo:30–31, 66–67` 에서 `Re_lam=2300`, `Re_turb=4000` 으로부터
자동 유도되므로 `(Re²+Re_reg²)^0.4` 같은 정규화 트릭이 불필요합니다.

**(b) 물리 — 이것이 더 중요합니다.** MSR 고유의 열전달 현상, 즉 **유체 내부 발열
보정**이 빠져 있습니다. Fischer 논문은 §2.1 전체를 여기에 할애합니다 (Eq. 1–2):

```
Nu_{Q+jw} = Nu_jw / (1 + (Q·D/j_w)·φ(Re,Pr))
φ = 3/44                     (층류, Poppendiek & Palmer 1954)
φ = 1.656·Pr^(−0.4)·Re^(−0.5) (난류, Fiorina et al. 2014)
```

MSRE 노심에서는 **연료 자체가 열원**이므로 벽면 열유속만 있는 경우와 온도 분포가
질적으로 다릅니다. Fischer §4.1.1:

> *"Conventional heat-transfer correlations such as **Sieder-Tate were not able to predict
> the correct temperature distribution** but tended to show a significantly lower bulk
> graphite temperature."*

현재 모델은 연료 채널에 `Q_gens` 를 넣고 흑연을 수동 흡열체로 두면서
평범한 Dittus–Boelter(+floor)를 씁니다 — 정확히 Fischer가 "안 된다"고 한 접근입니다.
그리고 흑연 온도는 α_g 를 통해 반응도로 들어갑니다.

**이것은 단순한 개선이 아니라, MARS로는 하기 어렵고 TRANSFORM으로는 5줄이면 되는
차별화 지점입니다.** `PartialSinglePhase` 를 상속한 closure 하나로 끝납니다:

```modelica
model Nus_InternallyHeated "Fiorina/Poppendiek internal heat generation correction"
  extends TRANSFORM.Fluid.ClosureRelations.HeatTransfer.Models.
          DistributedPipe_1D_MultiTransferSurface.PartialSinglePhase;
  input SI.HeatFlowRate Q_gens[nHT] "Volumetric heat source of each node";
  ...
equation
  for i in 1:nHT loop
    phi[i] = TRANSFORM.Math.spliceTanh(1.656*Prs[i]^(-0.4)*Res[i]^(-0.5), 3/44,
                                       Res[i] - 2300, 500);
    Nus[i,j] = Nus_base[i,j] / (1 + Q_vol[i]*dimensions[i]/j_w[i] * phi[i]);
  end for;
```

**(c) 튜닝 계수** — `Geometry.mo:119–122`:

```modelica
parameter Real f_shellHT=3.0  "... ; calibrates the full-power duty";
parameter Real Nu_floor_shell=10.0 "... ; calibrates the natural circulation duty";
```

전열 성능을 정답에 맞추는 두 개의 자유 파라미터입니다. TRANSFORM에
`FlowAcrossTubeBundles_Grimison` (Grimison 상관식, 관 배열/피치 입력, 정렬·엇갈림 선택,
행 수 보정 테이블 내장)이 있으므로, 16 in shell / 163 tubes / 배플 간격이라는
**실제 기하로부터** shell측 계수가 나오게 할 수 있습니다.
그러면 자연순환 시험 결과가 "튜닝된 답"이 아니라 예측이 됩니다.

---

## 5. 사소하지만 명확한 결함

**D1. `rho_CR_pcm` 라벨이 실제와 불일치.**
`PointKinetics_DNPtransport.mo:111`:

```modelica
rho_servo = Beta_eff - Beta_eff_inst;
```

이것은 임계 유지에 필요한 **총 반응도**입니다 (Fischer Eq. 22와 동일).
그러나 `PrimarySystem.mo:368` 은 이것을 `rho_CR_pcm` "control rod reactivity" 로
내보냅니다. 제어봉 반응도 = 총 반응도 − 온도 피드백 반응도 − 외부 반응도 입니다.
pump 시험은 등온이라 실질 차이가 없지만, `PumpStartup` / `PumpCoastdown` 은
`alphas_feedback` 을 0으로 두지 않고 `data_K.alpha_fuel/alpha_graphite` 를 그대로
넘깁니다 (Fischer는 §4.2.2에서 이 시험에 대해 **명시적으로 α=0 으로 설정**한다고 기술).
수정:

```modelica
rho_servo = Beta_eff - Beta_eff_inst - sum(rhos_feedback) - rho_input;
```

또는 실험 모델에서 `alpha_fuel = alpha_graphite = 0` 으로 재선언.

**D2. `use_servoControl=true` 일 때 `rho` 가 dangling.**
`der(N)=0` 이므로 `rho` 는 어떤 방정식에도 들어가지 않습니다. 계산은 되지만
반응도 수지가 닫히지 않아, 나중에 외부 반응도 삽입 시험(Fischer §4.2.1)을 추가할 때
조용히 무시됩니다.

**D3. 붕괴열 / 핵분열생성물 부재.**
자연순환 시험은 8 kW 에서 시작합니다. 이 시험 이전 운전 이력에 따라 붕괴열이
초기 출력과 같은 자릿수일 수 있습니다. TRANSFORM 점동특성 모델은
`Data.DecayHeat` + `Qs_decay` 를 기본 제공하고 `use_history` 로 운전 이력까지
받습니다 (`PointKinetics_L1_powerBased.mo:105–115`). 최소한 무시 근거를 문서화하십시오.

**D4. 검증 모델이 한 번도 실행되지 않음.**
`Verification/Transient_DriftReactivity.mo` 문서 원문: *"Never executed. No Modelica
compiler was available while this was written."* 문서화된 정직함은 좋지만,
`Analytic_DriftReactivity` 는 파라미터 전용 모델이라 OpenModelica로도 검증 가능합니다.
(참고로 `driftReactivity(9.56, 16.14)` 를 독립 계산한 결과 **228.35 pcm**,
`Beta_circ = 0.00450` 으로 assert 조건과 일치함을 확인했습니다 — 함수 구현 자체는 정확합니다.)

---

## 6. 수정 로드맵

우선순위는 **(효과 ÷ 위험)** 순입니다.

### 1단계 — 구조 정리 (물리 결과 불변, 즉시 착수 가능)

1. `A4` — `PrecursorDecay` closure 하나로 붕괴항 통합. `PrimarySystem` 에서
   `mC_gens_hxShell` 제거.
2. `D1`, `D2` — `rho_servo` 정의 수정, pump 시험에서 α=0 명시.
3. `C3-4` — 밀도 기준 통일 (2055 @922 K vs 2063 @908 K).
4. `D4` — `Analytic_DriftReactivity` 를 OpenModelica로 실제 실행하고 결과 기록.

### 2단계 — 초기화 재구성 (핵심, 결과 동일하되 훨씬 빠름)

5. `A2` — `Beta_eff` 동결을 `rho_0(fixed=false)` + `initial equation` 으로 교체.
6. `A1` — `traceDynamics = SteadyStateInitial`. `t_null` 을 0으로 하고 세 실험에서 제거.
   `C_start` 에 정체상태 해석해를 초기 추정값으로 제공.
7. `Verification/Transient_DriftReactivity` 를 단순화 — `rho_0` 와 `driftReactivity` 를
   **파라미터끼리** 비교하는 assert로 강등하고, 과도해석 assert는 진동 주기만 남김.

### 3단계 — 물리 입력 정정 (결과가 바뀜, 논문거리)

8. `C1` — `phis_adjoint` 를 ORNL WIF 기반으로. **균일 가중 vs WIF 가중 비교 결과를 제시.**
9. `C3` — `Geometry` 를 설계 치수 상향식으로 재구성, transit time 은 검증 항목으로 강등.
10. `C2` — Haubenreich(1964) fission rate 테이블 도입.
11. `C4` — `f_graphiteHeating = 0.05`.
12. `C6` — 노달라이제이션 수렴 검증 모델 추가 후 기본 노드 수 재결정.

### 4단계 — TRANSFORM 고유 역량 활용 (프레임워크 목적 달성)

13. `B4` — 내부발열 보정 Nusselt closure (`Nus_InternallyHeated`) 구현.
    **MARS 대비 명확한 우위 지점.**
14. `B1/B2` — `Pump_wShaft` + `Inertia(J)` 로 교체, 관성모멘트를 물리 파라미터로.
15. `B3` — `Volumes.ExpansionTank` 로 교체.
16. `B4c` — shell측을 `FlowAcrossTubeBundles_Grimison` 으로, 튜닝 계수 2개 제거.
17. `A3` — 점동특성을 `PointKinetics_L1_atomBased_external` 기반으로 재구성.
    붕괴열 / Xe-135 / 삼중수소 경로 확보.

---

## 7. 프레임워크 목적에 대한 제언

목표가 "MARS-KS 벤치마킹"이 아니라 "**TRANSFORM 기반 MSR 프레임워크 구축**" 이라면,
현재 저장소의 구성 자체를 한 층 나눌 것을 권합니다.

```
MSRE/                     ← 지금의 저장소
├── Media, Data, ...      ← MSRE 고유 (플랜트 데이터)
└── Experiments/          ← MSRE 실험

MSR/                      ← 새로 분리할 재사용 계층
├── Nuclear/
│   ├── PointKinetics_DNPtransport      ← 노심 정의에 무관
│   └── Data/ (ASF/WIF 인터페이스 포함)
├── ClosureRelations/
│   ├── PrecursorDecay                  ← A4
│   ├── Nus_InternallyHeated            ← B4, MSR 고유 물리
│   └── Nus_MoltenSalt_2Region
└── Components/
    └── FueledPipe, FueledChannel       ← 붕괴항이 항상 켜진 유체 컴포넌트
```

이렇게 하면 다음 플랜트(MSRR, Seaborg CMSR 등)로 갈 때 `MSRE/` 만 갈아끼우면 됩니다.
현재는 `PrimarySystem` 안에 `mC_gens_hxShell` 같은 물리식이 들어 있어
재사용 시 조용히 깨집니다.

그리고 논문화 관점에서, **가장 값어치 있는 결과는 MARS와 같은 답을 내는 것이 아니라
MARS가 낼 수 없는 답을 내는 것**입니다. 구체적으로 세 가지가 손에 잡힙니다:

1. **중요도 가중의 민감도** (`C1`) — Fischer가 "가장 민감하다"고 지목했으나
   정량화하지 않은 지점. 균일 / ORNL WIF / plena 가중 변화 3케이스를 돌리면
   drift 반응도 문헌값 산포(Fischer Fig. 9의 코드별 200–260 pcm 편차)를
   설명할 수 있습니다.
2. **내부발열 보정 열전달** (`B4`) — MARS/RELAP 계열은 closure 교체가 불가능하므로
   원리적으로 못 합니다. 흑연 온도 → α_g 경로를 통해 자연순환 시험 결과를 바꿉니다.
3. **초기화의 등가성** (`A1`/`A2`) — "null transient 600 s"와
   "정상상태 초기화"가 동일한 상태에 도달함을 보이는 것 자체가,
   시스템 코드 사용자에게 Modelica의 이점을 보여주는 깔끔한 결과입니다.

---

## 부록 A. 검증에 사용한 수치

독립 재계산 결과 (Python, 저장소 파라미터 사용):

```
V_channels = 1140 × 3.9198e-4 × 1.626      = 0.7266 m³
V_core     = V_channels + 0.0777/3 × 2     = 0.7784 m³
V_loop                                      = 1.3143 m³
V_total                                     = 2.0927 m³
τ_core  @ ρ=2063 kg/m³, ṁ=168 kg/s          = 9.558 s   (문서값 9.56 ✔)
τ_loop                                      = 16.139 s  (문서값 16.14 ✔)
driftReactivity(β_U235, λ_U235, 9.56, 16.14) = 228.35 pcm (문서값 228.4 ✔)
β_circ = 0.006781 − 0.0022835                = 0.004498  (문서값 ~0.0045 ✔)

TRANSFORM LinearFLiBe_64LiF_30BeF2_5ZrF4_1UF4_CrFeNi:
  d(922 K) = (2.575 − 5.13e-4 × 648.85)×1000 = 2242.1 kg/m³
저장소 FuelSalt:
  d(922 K) = 2575.3 − 0.5641×922             = 2055.2 kg/m³   (차이 +9.1 %)
  d(908 K)                                    = 2063.1 kg/m³
ρ=2242 일 때 τ_core=9.56 s 를 위한 V_core     = 0.7164 m³  < V_channels(0.7266) → 성립 불가
```

## 부록 B. 대조한 TRANSFORM 소스 (커밋 시점 master)

| 주장 | 파일 |
|---|---|
| 분산 선구체 점동특성 내장 | `TRANSFORM/Nuclear/ReactorKinetics/PointKinetics_L1_atomBased_external.mo:242–265` |
| DNP drift 예제 존재 | `.../Examples/PointKinetics_Drift_Test_flat.mo` |
| `SteadyStateInitial` 존재 | `TRANSFORM/Types/Dynamics.mo` |
| `traceDynamics` 독립 파라미터 | `TRANSFORM/Fluid/SystemTF.mo:27` |
| trace 정상상태 초기화 구현 | `TRANSFORM/Fluid/Pipes/BaseClasses/PartialDistributedVolume.mo:142–145` |
| 2영역 Nusselt (spliceTanh) | `.../DistributedPipe_1D_MultiTransferSurface/Nus_SinglePhase_2Region.mo` |
| 관군 횡류 상관식 | `.../FlowAcrossTubeBundles_Grimison.mo` |
| 펌프 상사법칙 / 특성곡선 | `TRANSFORM/Fluid/Machines/BaseClasses/PartialPump_nom.mo:71–96` |
| 샤프트 펌프 (관성 부착 가능) | `TRANSFORM/Fluid/Machines/Pump_wShaft.mo` |
| 관성정지 곡선 | `.../PumpCharacteristics/PumpTripCoastdown.mo` |
| 팽창탱크 (실체적) | `TRANSFORM/Fluid/Volumes/ExpansionTank.mo` |
| MSRE 연료염 매질 | `TRANSFORM/Media/Fluids/FLiBe/LinearFLiBe_64LiF_30BeF2_5ZrF4_1UF4_CrFeNi/` |
