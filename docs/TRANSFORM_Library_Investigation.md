# ORNL-Modelica/TRANSFORM-Library 조사 결과

- 조사 대상: `https://github.com/ORNL-Modelica/TRANSFORM-Library`
- 조사 시점 커밋: `504359d88b26bbf6c5509bd5fd2c83bbc5e04453` (2026-08-07, `main`)
- 라이브러리 버전: `TRANSFORM` version `1.0`, `uses(Modelica 4.0.0)` (`TRANSFORM/package.mo`)
- 표기 규칙: 아래 경로는 모두 레포에 실제로 존재하는 파일/모델만 기재. 확인하지 못한 항목은 **확인 불가**로 명시.
- 경로 표기: Modelica 클래스 경로 (`TRANSFORM.Fluid.Pipes.GenericPipe_MultiTransferSurface`) 와 파일 경로 (`TRANSFORM/Fluid/Pipes/GenericPipe_MultiTransferSurface.mo`) 는 1:1 대응.

---

## 1. 요청 컴포넌트별 경로와 주요 파라미터

### 1.1 1D 단상 유체 파이프

| 클래스 | 파일 | 비고 |
|---|---|---|
| `TRANSFORM.Fluid.Pipes.GenericPipe_MultiTransferSurface` | `TRANSFORM/Fluid/Pipes/GenericPipe_MultiTransferSurface.mo` | **현재 권장 모델**. 노드당 다중 전열면(`nSurfaces`) 지원 |
| `TRANSFORM.Fluid.Pipes.GenericPipe` | `TRANSFORM/Fluid/Pipes/GenericPipe.mo` | `extends TRANSFORM.Icons.ObsoleteModel`. 문서에 "이 모델은 MultiTransferSurface 로 대체되어 삭제 예정"이라고 명시됨. 전열면 1개 |
| `TRANSFORM.Fluid.Pipes.GenericPipe_withWall` | `TRANSFORM/Fluid/Pipes/GenericPipe_withWall.mo` | 위 파이프 + `Conduction_2D` 벽 |
| `TRANSFORM.Fluid.Pipes.GenericPipe_withWallx2` | `TRANSFORM/Fluid/Pipes/GenericPipe_withWallx2.mo` | 내/외벽 2겹 |
| `TRANSFORM.Fluid.Pipes.GenericPipe_withWallAndInsulation` | `TRANSFORM/Fluid/Pipes/GenericPipe_withWallAndInsulation.mo` | |
| `TRANSFORM.Fluid.Pipes.GenericPipe_wWall_wTraceMass` | `TRANSFORM/Fluid/Pipes/GenericPipe_wWall_wTraceMass.mo` | 벽 + 벽 내부 미량물질 확산까지 |
| `TRANSFORM.Fluid.Pipes.TransportDelayPipe` | `TRANSFORM/Fluid/Pipes/TransportDelayPipe.mo` | 순수 이송지연 모델 |
| `TRANSFORM.Fluid.Pipes.BaseClasses.PartialDistributedVolume` | `TRANSFORM/Fluid/Pipes/BaseClasses/PartialDistributedVolume.mo` | 위 파이프들의 질량/에너지/화학종/미량물질 보존식 정의 |

`GenericPipe_MultiTransferSurface` 주요 파라미터 (다이얼로그 그룹 기준):

- 구조/기하
  - `nParallel` (Real, 병렬 동일 부품 수)
  - `replaceable model Geometry` — 기본값 `TRANSFORM.Fluid.ClosureRelations.Geometry.Models.DistributedVolume_1D.StraightPipe`, constrainedby `...DistributedVolume_1D.GenericPipe`
  - Geometry 내부 파라미터 (`TRANSFORM/Fluid/ClosureRelations/Geometry/Models/DistributedVolume_1D/GenericPipe.mo`):
    `nV`(노드 수), `nSurfaces`(전열/전달면 수), `dimensions[nV]`(수력직경), `crossAreas[nV]`, `perimeters[nV]`, `dlengths[nV]`, `roughnesses[nV]`, `surfaceAreas[nV,nSurfaces]`, `angles[nV]`, `dheights[nV]`, `height_a`
    → 파생: `Vs[nV] = crossAreas .* dlengths`, `V_total`, `dxs[nV]`
- 매질/미량물질
  - `replaceable package Medium` (constrainedby `Modelica.Media.Interfaces.PartialMedium`) — `PartialDistributedVolume` 에서 선언
- 압력손실(운동량)
  - `replaceable model FlowModel` — 기본값 `TRANSFORM.Fluid.ClosureRelations.PressureLoss.Models.DistributedPipe_1D.SinglePhase_Developed_2Region_NumStable`, constrainedby `...DistributedPipe_1D.PartialDistributedStaggeredFlow`
- 열전달
  - `use_HeatTransfer` (Boolean, 기본 false)
  - `replaceable model HeatTransfer` — 기본 `...HeatTransfer.Models.DistributedPipe_1D_MultiTransferSurface.Ideal`, constrainedby `...PartialHeatTransfer_setT`
  - `replaceable model InternalHeatGen` — 기본 `...InternalVolumeHeatGeneration.Models.DistributedVolume_1D.GenericHeatGeneration`
- 미량물질 전달/생성
  - `use_TraceMassTransfer` (Boolean, 기본 false)
  - `replaceable model TraceMassTransfer` — 기본 `...MassTransfer.Models.DistributedPipe_TraceMass_1D_MultiTransferSurface.Ideal`
  - `replaceable model InternalTraceGen` — 기본 `...InternalTraceGeneration.Models.DistributedVolume_Trace_1D.GenericTraceGeneration`
- 초기화 (Initialization 탭)
  - `p_a_start`, `p_b_start`, `T_a_start`, `T_b_start`, `use_Ts_start`, `h_a_start`, `h_b_start`,
    `X_a_start[Medium.nX]`, `X_b_start[Medium.nX]`, `C_a_start[Medium.nC]`, `C_b_start[Medium.nC]`,
    `m_flow_a_start`, `m_flow_b_start`, `m_flows_start[nV+1]`
  - 배열형 시작값: `ps_start[nV]`, `Ts_start[nV]`, `hs_start[nV]`, `Xs_start[nV,nX]`, `Cs_start[nV,nC]`
- Dynamics (Advanced 탭)
  - `energyDynamics`, `massDynamics`, `substanceDynamics`(final = massDynamics), `traceDynamics`, `momentumDynamics`
    (`Modelica.Fluid.Types.Dynamics`; 기본 `DynamicFreeInitial`, `momentumDynamics` 는 `SteadyState`)
- 모델 구조 (Advanced 탭)
  - `exposeState_a` (기본 true), `exposeState_b` (기본 false), `useLumpedPressure`, `lumpPressureAt`,
    `useInnerPortProperties`, `allowFlowReversal`, `g_n`
- 커넥터
  - `port_a`, `port_b` : `TRANSFORM.Fluid.Interfaces.FluidPort_Flow`
  - `heatPorts[nV, geometry.nSurfaces]` : `HeatAndMassTransfer.Interfaces.HeatPort_Flow` (조건부, `use_HeatTransfer`)
  - `massPorts[nV, geometry.nSurfaces]` : `HeatAndMassTransfer.Interfaces.MolePort_Flow` (조건부, `use_TraceMassTransfer`)

사용 가능한 압력손실 모델 (`TRANSFORM/Fluid/ClosureRelations/PressureLoss/Models/DistributedPipe_1D/`):
`Nominal_Linear`, `SinglePhase_Developed_2Region_NumStable`, `SinglePhase_Developed_2Region_Simple`,
`SinglePhase_ReynoldsRelation_NumStable`, `SinglePhase_Turbulent_MSL`,
`TwoPhase_Developed_2Region_NumStable`, `TwoPhase_Developed_2Region_NumStable_alternate`

사용 가능한 열전달 모델 (`.../HeatTransfer/Models/DistributedPipe_1D_MultiTransferSurface/`):
`Ideal`, `Alphas`, `Nus`, `Nus_DittusBoelter_Simple`, `Nus_McCartyWolf_Simple`, `Nus_SinglePhase_2Region`,
`Nus_SinglePhase_2Region_modelBased`, `FlowAcrossTubeBundles_Grimison`, `Alphas_TwoPhase_3Region`,
`Alphas_TwoPhase_3Region_CHFtransition`, `Alphas_TwoPhase_4Region`, `Alphas_TwoPhase_5Region`

### 1.2 유체 체적 (lumped volume)

| 클래스 | 파일 | 포트 |
|---|---|---|
| `TRANSFORM.Fluid.Volumes.SimpleVolume` | `TRANSFORM/Fluid/Volumes/SimpleVolume.mo` | `port_a`, `port_b` (`FluidPort_State`) |
| `TRANSFORM.Fluid.Volumes.SimpleVolume_1Port` | `TRANSFORM/Fluid/Volumes/SimpleVolume_1Port.mo` | 1포트 |
| `TRANSFORM.Fluid.Volumes.MixingVolume` | `TRANSFORM/Fluid/Volumes/MixingVolume.mo` | `port_a[nPorts_a]`, `port_b[nPorts_b]` (connectorSizing) |
| `TRANSFORM.Fluid.Volumes.ExpansionTank` | `TRANSFORM/Fluid/Volumes/ExpansionTank.mo` | 커버가스 있는 팽창탱크 (레벨 상태변수) |
| `TRANSFORM.Fluid.Volumes.ExpansionTank_1Port` | `TRANSFORM/Fluid/Volumes/ExpansionTank_1Port.mo` | |
| `TRANSFORM.Fluid.Volumes.BaseClasses.PartialVolume` | `TRANSFORM/Fluid/Volumes/BaseClasses/PartialVolume.mo` | 보존식 정의 |

`SimpleVolume` / `MixingVolume` 주요 파라미터:

- `replaceable model Geometry` — 기본 `TRANSFORM.Fluid.ClosureRelations.Geometry.Models.LumpedVolume.GenericVolume` (`V`, `dheight` 제공)
- `use_HeatPort` (Boolean) → `heatPort` (`HeatAndMassTransfer.Interfaces.HeatPort_State`)
- `Q_gen` (input SI.HeatFlowRate, 내부 발열)
- `use_TraceMassPort` (Boolean) → `traceMassPort` (`MolePort_State`), `MMs[Medium.nC]` (질량비→몰 변환계수)
- `mC_gen[Medium.nC]` (input `SIadd.ExtraPropertyFlowRate`, **내부 미량물질 생성항**)
- 초기화: `p_start`, `use_T_start`, `T_start`, `h_start`, `X_start[nX]`, `C_start[nC]`
- Dynamics: `energyDynamics`, `massDynamics`, `substanceDynamics`(final), `traceDynamics`
- `MixingVolume` 추가: `nPorts_a`, `nPorts_b`

`ExpansionTank` 주요 파라미터: `A`(단면적), `V0`, `p_surface`(input), `p_start`, `level_start`, `T_start`/`h_start`, `X_start`, `C_start`, `massDynamics`, `traceDynamics`, `allowFlowReversal`.

### 1.3 열구조 (solid heat structure)

분산형(다노드) 전도 모델 — `TRANSFORM/HeatAndMassTransfer/DiscritizedModels/`:

| 클래스 | 파일 |
|---|---|
| `TRANSFORM.HeatAndMassTransfer.DiscritizedModels.Conduction_1D` | `Conduction_1D.mo` |
| `TRANSFORM.HeatAndMassTransfer.DiscritizedModels.Conduction_2D` | `Conduction_2D.mo` |
| `TRANSFORM.HeatAndMassTransfer.DiscritizedModels.Conduction_3D` | `Conduction_3D.mo` |
| `...DiscritizedModels.HMTransfer_1D / _2D / _3D` | `HMTransfer_1D.mo` 등 (열+물질 동시) |
| `...DiscritizedModels.BaseClasses.Dimensions_1.PartialDistributedVolume` | `BaseClasses/Dimensions_1/PartialDistributedVolume.mo` (에너지 보존식) |

`Conduction_1D` 주요 파라미터:

- `replaceable package Material` — constrainedby `TRANSFORM.Media.Interfaces.Solids.PartialAlloy`
  (사용 가능 고체: `TRANSFORM/Media/Solids/` 아래 `Graphite`, `Hastelloy_N_Haynes`, `AlloyN`, `SS316`, `SS304`, `UO2`, `UN`, `UC`, `Beryllium`, `Molybdenum`, `Inconel625/690`, `HT9`, `YSZ`, `ZircHydride`, `Alumina`, `Copper`, `Tungsten`, `Rhenium`, `Cr225Mo1`, `FoamGlass`, `FOAMGLAS`, `FiberGlassGeneric`, `SS304_TRACE`, `SS316_TRACE`, `Sodium`, `Helium`, `ZrNb_E125`, `CustomSolids`)
- `replaceable model Geometry` — 기본 `...ClosureRelations.Geometry.Models.Plane_1D`, constrainedby `PartialGeometry_1D`
  선택지: `Plane_1D`, `Cylinder_1D_r`, `Cylinder_1D_theta`, `Cylinder_1D_z`, `Sphere_1D_r`, `Sphere_1D_theta` (+2D/3D 버전)
  - 예: `Cylinder_1D_r` 파라미터 = `nR`, `r_inner`, `r_outer`, `angle_theta`, `length_z`, `drs[nR]`, `dthetas[nR]`, `dzs[nR]`
- `replaceable model ConductionModel` — 기본 `...BaseClasses.Dimensions_1.ForwardDifference_1O` (선택: `BackwardDifference_1O`)
- `replaceable model InternalHeatModel` — 기본 `...Dimensions_1.GenericHeatGeneration`
  (선택: `VolumetricHeatGeneration`, `TotalHeatGeneration`, `OhmicHeatGeneration`)
- `nParallel`, `exposeState_a1`(기본 true), `exposeState_b1`(기본 false)
- 초기화: `T_a1_start`, `T_b1_start`, `Ts_start[nVs[1]]`, `ds_reference[]`, `energyDynamics`
- `velocity_1` (input, 고체가 이동하는 경우의 엔탈피 이송)
- 커넥터: `port_a1`, `port_b1` (`HeatPort_Flow`), `port_external[nVs[1]]` (`HeatPort_State`, 비이산화 방향 외부 열전달)

집중정수형 벽 모델 — `TRANSFORM/HeatAndMassTransfer/Volumes/`:
`SimpleWall.mo`, `SimpleWall_Cylinder.mo`, `SimpleWall_noMedia.mo`, `UnitVolume.mo`, `UnitVolume_withMedia.mo`,
`UnitVolume_wTraceMass.mo`, `UnitVolume_wTraceMass_withMedia.mo`

- `SimpleWall_Cylinder` 파라미터: `length`, `r_inner`, `r_outer`, `R`(기본 `log(r_o/r_i)/(2*pi*L*lambda)`), `Q_gen`, `exposeState_a`, `exposeState_b`, `T_start`, `energyDynamics`

### 1.4 2유체 열교환기

| 클래스 | 파일 | 성격 |
|---|---|---|
| `TRANSFORM.HeatExchangers.GenericDistributed_HX` | `TRANSFORM/HeatExchangers/GenericDistributed_HX.mo` | **분산형 2유체 + 관벽 2D 전도**. shell/tube 각각 `GenericPipe_MultiTransferSurface`, 벽은 `Conduction_2D` |
| `TRANSFORM.HeatExchangers.GenericDistributed_HX_Rwall` | `GenericDistributed_HX_Rwall.mo` | 벽을 열저항으로 축약 |
| `TRANSFORM.HeatExchangers.GenericDistributed_HX_withMass` | `GenericDistributed_HX_withMass.mo` | + 미량물질 벽 투과 |
| `TRANSFORM.HeatExchangers.Simple_HX` | `Simple_HX.mo` | `SimpleVolume[nV]` 2열 + `UA` 기반 열전달 |
| `TRANSFORM.HeatExchangers.Simple_HX_A` | `Simple_HX_A.mo` | |
| `TRANSFORM.HeatExchangers.LMTD_HX_Q / _UA / _A` | `LMTD_HX_Q.mo` 등 | LMTD 사이징용 |
| `TRANSFORM.HeatExchangers.EffectivenessNTU_HX` | `EffectivenessNTU_HX.mo` | `extends TRANSFORM.Icons.UnderConstruction` — 미완성 표시. 포트 없음, 파라미터 계산식 1줄뿐 |
| `TRANSFORM.HeatExchangers.BellDelaware_STHX` | `BellDelaware_STHX/` | 쉘앤튜브 상세 |

`GenericDistributed_HX` 주요 파라미터:

- 포트: `port_a_tube`, `port_b_tube`, `port_a_shell`, `port_b_shell` (모두 `FluidPort_Flow`)
- `replaceable package Medium_shell`, `Medium_tube`, `replaceable package Material_tubeWall` (constrainedby `PartialAlloy`)
- `replaceable model Geometry` — 기본 `...Geometry.Models.DistributedVolume_1D.HeatExchanger.StraightPipeHX`, constrainedby `...HeatExchanger.GenericHX`
  (`geometry.nV`, `geometry.nR`, `geometry.nSurfaces_shell`, `geometry.nSurfaces_tube`, `dimensions_tube`, `dimensions_tube_outer`, `length_tube` 등)
- `counterCurrent` (Boolean, 기본 true) — shell 측 온도/열유속 벡터 순서 뒤집기
- `nParallel` (동일 HX 병렬 수)
- `replaceable model FlowModel_shell`, `FlowModel_tube` (기본 `SinglePhase_Developed_2Region_NumStable`)
- `replaceable model HeatTransfer_shell`, `HeatTransfer_tube` (기본 `...DistributedPipe_1D_MultiTransferSurface.Ideal`)
- `replaceable model InternalHeatGen_tube/_shell`, `InternalTraceGen_tube/_shell` (기본 `GenericHeatGeneration` / `GenericTraceGeneration`)
- 초기화 탭 3종: "Shell Initialization", "Tube Initialization", 벽 온도 `Ts_wall_start[geometry.nR, geometry.nV]`
  각 유체측: `p_a_start_*`, `p_b_start_*`, `T_a_start_*`, `T_b_start_*`, `h_*`, `Xs_start_*`, `Cs_start_*`, `m_flows_start_*`
- `energyDynamics` 등은 `{shell, tube, tubeWall}` 배열 형태로 지정
- 추가 열포트: `heatPorts_addShell[geometry.nV, nSurfaces_shell-1]`, `heatPorts_addTube[geometry.nV, nSurfaces_tube-1]`
- 내부 연결 구조 (파일 내 `connect` 문 기준):
  `tube.heatPorts[:,1] ↔ tubeWall.port_a1`, `tubeWall.port_b1 ↔ counterFlow.port_a`,
  `counterFlow.port_b ↔ shell.heatPorts[:,1]`, `tubeWall.port_a2/port_b2 ↔ adiabaticWall`

`Simple_HX` 주요 파라미터: `Medium_1`, `Medium_2`, `nV`, `V_1`, `V_2`, `UA`(input `SI.ThermalConductance`), `CF`/`CFs[nV]`(보정계수), `counterCurrent`(고정 true), 각 측 초기화값(`p_a_start_1` 등).

### 1.5 유량원 / 펌프

**경계조건 (`TRANSFORM/Fluid/BoundaryConditions/`)**

| 클래스 | 파일 | 주요 파라미터 |
|---|---|---|
| `TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T` | `MassFlowSource_T.mo` | `m_flow`, `T`, `X[nX]`, `C[nC]`, `nPorts`, `use_m_flow_in`, `use_T_in`, `use_X_in`, `use_C_in` → 입력커넥터 `m_flow_in`, `T_in`, `X_in[nX]`, `C_in[nC]` |
| `TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_h` | `MassFlowSource_h.mo` | 위와 동일하되 `h`/`h_in` |
| `TRANSFORM.Fluid.BoundaryConditions.Boundary_pT` | `Boundary_pT.mo` | `p`, `T`, `X`, `C`, `use_p_in`/`use_T_in`/`use_X_in`/`use_C_in`, `nPorts` |
| `TRANSFORM.Fluid.BoundaryConditions.Boundary_ph` | `Boundary_ph.mo` | |
| `TRANSFORM.Fluid.BoundaryConditions.FixedBoundary` | `FixedBoundary.mo` | |

**펌프 (`TRANSFORM/Fluid/Machines/`)**

| 클래스 | 파일 | 성격 |
|---|---|---|
| `TRANSFORM.Fluid.Machines.Pump_SimpleMassFlow` | `Pump_SimpleMassFlow.mo` | 유량 규정형. `m_flow_nominal`, `use_input`(→`in_m_flow`), `allowFlowReversal`. 압력차에 의한 엔탈피 변화 무시 |
| `TRANSFORM.Fluid.Machines.Pump` | `Pump.mo` | 원심펌프. `controlType ∈ {"RPM","m_flow","pressure","dp"}`, `use_port`, `k_inputSignal`, 입력 `N_input`/`m_flow_input`/`p_input`/`dp_input` |
| `TRANSFORM.Fluid.Machines.Pump_Controlled` | `Pump_Controlled.mo` | |
| `TRANSFORM.Fluid.Machines.Pump_Mechanical`, `Pump_wShaft` | | 샤프트 연결형 |
| `TRANSFORM.Fluid.Machines.Pump_PressureBooster` | `Pump_PressureBooster.mo` | |
| `TRANSFORM.Fluid.Machines.TurboPump`, `TurboPump_homologouscurves` | | |
| `TRANSFORM.Fluid.Machines.BaseClasses.PartialPump` | `BaseClasses/PartialPump.mo` | `Pump` 계열 베이스 |
| `TRANSFORM.Fluid.Machines.BaseClasses.PartialPump_Simple` | `BaseClasses/PartialPump_Simple.mo` | |

`PartialPump` 주요 파라미터: `nParallel`, `N_nominal`, `m_flow_nominal`, `dp_nominal`, `head_nominal`,
`diameter`/`diameter_nominal`, `V_flow_nominal`, `checkValve`, `exposeState_a`(기본 true)/`exposeState_b`,
`use_powerCharacteristic`, `replaceable model FlowChar` (head vs. 체적유량), `replaceable model PowerChar`,
초기화 `p_a_start`, `p_b_start`, `T_a_start`/`h_a_start`, `X_start`, `C_start`, `m_flow_start`.
특성곡선 라이브러리: `TRANSFORM/Fluid/Machines/BaseClasses/PumpCharacteristics/{Flow, Efficiency, Power, HomologousSets, NondimensionalCurves}`.

### 1.6 점동특성(Point Kinetics) 컴포넌트

| 클래스 | 파일 | 성격 |
|---|---|---|
| `TRANSFORM.Nuclear.ReactorKinetics.PointKinetics_L1_powerBased` | `TRANSFORM/Nuclear/ReactorKinetics/PointKinetics_L1_powerBased.mo` | 선구물질을 **내부 상태**(`Cs[nC]`, 단위 W)로 보유하는 표준 점동특성 |
| `TRANSFORM.Nuclear.ReactorKinetics.PointKinetics_L1_atomBased_external` | `TRANSFORM/Nuclear/ReactorKinetics/PointKinetics_L1_atomBased_external.mo` | 선구물질 농도를 **외부 입력**(`mCs[nV,nC]`, 단위 atoms)으로 받는 순환연료용 모델 |
| `TRANSFORM.Nuclear.ReactorKinetics.SparseMatrix.PointKinetics_L1_powerBased_sparseMatrix` | `SparseMatrix/PointKinetics_L1_powerBased_sparseMatrix.mo` | |
| `TRANSFORM.Nuclear.ReactorKinetics.SparseMatrix.PointKinetics_L1_atomBased_external_sparseMatrix` | `SparseMatrix/PointKinetics_L1_atomBased_external_sparseMatrix.mo` | |
| `TRANSFORM.Nuclear.ReactorKinetics.Reactivity.FissionProducts` 외 | `Reactivity/` | `FissionProducts.mo`, `FissionProducts_withDecayHeat.mo`, `FissionProducts_externalBalance_withTritium.mo`, `FissionProducts_externalBalance_withTritium_withDecayHeat.mo`, `TraceSubstances.mo` |

`PointKinetics_L1_powerBased` 주요 파라미터/입력:

- `Q_nominal`, `specifyPower`, `Q_fission_input`, `Q_external`, `rho_input`
- `replaceable record Data` — 기본 `Data.PrecursorGroups.precursorGroups_6_TRACEdefault`
- `replaceable record Data_DH` — 기본 `Data.DecayHeat.decayHeat_0` (선택: `decayHeat_11_TRACEdefault`)
- `replaceable record Data_FP` — 기본 `Data.FissionProducts.fissionProducts_0`
- 궤환: `nFeedback`, `alphas_feedback[nFeedback]`, `vals_feedback[nFeedback]`, `vals_feedback_reference[nFeedback]`
- 동특성 파라미터: `Lambda_start`, `Beta_start`(=data.Beta), `alphas_start`, `lambdas_start`,
  실시간 변동 입력 `dLambda`, `dBeta`, `dalphas[nC]`, `dlambdas[nC]`
- 붕괴열: `nDH`, `lambdas_dh`, `efs_dh`, `use_history`, `history[:,2]`, `includeDH`
- 핵분열생성물: `nu_bar_start`, `w_f_start`, `SigmaF_start`, `fissionSources_start[nFS]`, `fissionTypes_start[nFS,nT]`, `V`(농도 기준체적), `mC_nominal[nFP]`, `toggle_ReactivityFP`
- 추가 반응도: `nC_add`, `mCs_add[nC_add]`, `Vs_add`, `sigmasA_add_start[nC_add]`
- Dynamics: `energyDynamics`, `traceDynamics`, `decayheatDynamics`, `fissionProductDynamics`

`PointKinetics_L1_atomBased_external` 주요 파라미터/입력: 위와 유사하되 아래가 다름

- `nV` (이산 체적 수) — 노드별로 선구물질을 받는다
- **입력** `mCs[nV, nC]` (`SIadd.ExtraPropertyExtrinsic`, "# of neutron precursors in each volume [atoms]")
- **입력** `mCs_FP[nV, nFP]`, `mCs_TR[nV, nTR]`, `Vs[nV]`
- **출력 변수** `mC_gens[nV, nC]` (`SIadd.ExtraPropertyFlowRate`, 선구물질 생성률 [atoms/s])
- `N_external` (외부 중성자원, 1/s), `SF_Q_fission[nV]` (출력분포 형상계수, 합=1)
- `Qs[nV]`, `Qs_decay[nV,nFP]`, `Q_total`, `Q_decay`
- 내부에 `Reactivity.FissionProducts_externalBalance_withTritium_withDecayHeat` 인스턴스 포함
- `summary_data` : `TRANSFORM.Nuclear.ReactorKinetics.Data.summary_traceSubstances` (미량물질 이름/`C_nominal`/인덱스 제공)

---

## 2. 각 컴포넌트가 푸는 보존식

### 2.1 1D 파이프 — `PartialDistributedVolume` + `GenericPipe(_MultiTransferSurface)` + `FlowModel`

**총량 정의** (`TRANSFORM/Fluid/Pipes/BaseClasses/PartialDistributedVolume.mo:152-157`)

```
ms[i]      = Vs[i]*mediums[i].d
Us[i]      = ms[i]*mediums[i].u
mXis[i,:]  = ms[i]*mediums[i].Xi
mCs[i,:]   = ms[i] .* Cs[i,:]
```

**보존식** (같은 파일 `:158-198`) — `Dynamics.SteadyState` 이면 좌변 0, 아니면 미분항

```
질량      : der(ms[i])        = mbs[i]
에너지    : der(Us[i])        = Ubs[i]                 (내부에너지 기반)
화학종    : der(mXis[i,:])    = mXibs[i,:]
미량물질  : der(mCs_scaled[i,:]) = mCbs[i,:] ./ Medium.C_nominal ,  mCs = mCs_scaled .* C_nominal
```

**소스/플럭스 항** (`GenericPipe_MultiTransferSurface.mo:360-363`)

```
mbs[i]    = m_flows[i] - m_flows[i+1]
Ubs[i]    = Wb_flows[i] + H_flows[i] - H_flows[i+1]
            + sum(heatTransfer.Q_flows[i,:]) + internalHeatGen.Q_flows[i]/nParallel
mXibs[i,:]= mXi_flows[i,:] - mXi_flows[i+1,:]
mCbs[i,:] = mC_flows[i,:] - mC_flows[i+1,:]
            + mC_flows_traceMassTransferSum[i,:] + internalTraceGen.mC_flows[i,:]/nParallel
```

(구형 `GenericPipe.mo:356-361` 도 동일 구조, 열전달항만 단일면 `heatTransfer.Q_flows[i]`)

경계 플럭스는 상류차분(`semiLinear`)로 계산됨:
`H_flows[i] = semiLinear(m_flows[i], mediums[i-1].h, mediums[i].h)` 등, 미량물질도 동일하게
`mC_flows[i,:] = semiLinear(m_flows[i], Cs[i-1,:], Cs[i,:])`.
포트 경계에서는 `inStream(port_a.C_outflow)` 사용, `nParallel` 로 나눠짐.

`Wb_flows` 는 기계일 항 `v*A*dpdx + v*F_fric` 로 정의(모델 구조 분기별 식 존재).

**운동량 보존** (스태거드 격자, `TRANSFORM/Fluid/ClosureRelations/PressureLoss/Models/DistributedPipe_1D/`)

`PartialDistributedStaggeredFlow.mo:94-105`
```
Is[i] = m_flows[i]*dlengths[i]
der(Is[i]) = Ibs[i]     (momentumDynamics == SteadyState 이면 0 = Ibs[i])
```
`PartialMomentumBalance.mo:40-53`
```
Ibs      = I_flows - Fs_p - Fs_fg
I_flows  = A_i*rho_i*v_i^2 - A_{i+1}*rho_{i+1}*v_{i+1}^2      (use_I_flows=true 일 때, 아니면 0)
Fs_p     = 0.5*(A_i + A_{i+1})*(p_{i+1} - p_i)
Fs_fg    = (dps_fg[i] + dps_K_filtered[i]) * 0.5*(A_i + A_{i+1})
dps_K    = 0.5*K_ab*rho*v^2  (정방향) / -0.5*K_ba*rho*v^2 (역방향)
```
`dps_fg`(마찰+중력 압력강하)는 선택한 구체 FlowModel(예: `SinglePhase_Developed_2Region_NumStable`)이 정의.

### 2.2 유체 체적 — `Fluid.Volumes.BaseClasses.PartialVolume`

`PartialVolume.mo:156-185`
```
m = V*medium.d ,  U = m*medium.u ,  mXi = m*medium.Xi ,  mC = m*C

der(m)         = mb
der(U)         = Ub
der(mXi)       = mXib
der(mC_scaled) = mCb ./ Medium.C_nominal ,  mC = mC_scaled .* C_nominal
```
(각각 해당 Dynamics 가 `SteadyState` 이면 좌변 0). 운동량 방정식 없음 — 포트 압력은 정수두만 반영:
`port_a.p = medium.p + medium.d*g_n*0.5*geometry.dheight`.

`SimpleVolume` 에서의 소스항 (`SimpleVolume.mo:13-19`)
```
mb  = port_a.m_flow + port_b.m_flow
Ub  = Σ port.m_flow*actualStream(h_outflow) + Q_flow_internal + Q_gen
mXib= Σ port.m_flow*actualStream(Xi_outflow)
mCb = Σ port.m_flow*actualStream(C_outflow) + mC_flow_internal + mC_gen
```
`MixingVolume` 은 위를 `nPorts_a`/`nPorts_b` 합으로 확장.

### 2.3 열구조 — `HeatAndMassTransfer.DiscritizedModels`

`BaseClasses/Dimensions_1/PartialDistributedVolume.mo:37-52`
```
ms[i]       = Vs[i]*ds_reference[i]
delta_ms[i] = ms[i] - Vs[i]*materials[i].d      (정적 체적 가정 하의 질량 변화 추적용)
Us[i]       = Vs[i]*materials[i].d*materials[i].u
der(Us[i])  = Ubs[i]        (energyDynamics == SteadyState 이면 0 = Ubs[i])
```
→ **에너지 보존식만 푼다** (고체이므로 질량/운동량 방정식 없음).

`Conduction_1D.mo:96-105` 의 소스항
```
Ubs[i] = H_flows_1[i] - H_flows_1[i+1] + Q_flows_1[i] - Q_flows_1[i+1]
         + (internalHeatModel.Q_flows[i] + port_external[i].Q_flow)/nParallel
port_a1.Q_flow = nParallel*( Q_flows_1[1] + H_flows_1[1] )
port_b1.Q_flow = nParallel*(-Q_flows_1[nV+1] - H_flows_1[nV+1])
```
`Q_flows_1` 은 `ConductionModel`(예: `ForwardDifference_1O`)이 Fourier 법칙 이산화로 정의.
`H_flows_1` 는 `velocity_1 ≠ 0` 인 경우의 고체 엔탈피 이송항(상류차분).

`SimpleWall_Cylinder.mo:34-47` (집중정수)
```
Ub = port_a.Q_flow + port_b.Q_flow + Q_gen
port_a.Q_flow = (port_a.T - material.T)*2/R   (양단 모두 flux 노출인 경우)
R = log(r_outer/r_inner)/(2*pi*length*lambda)
```

### 2.4 열교환기

`GenericDistributed_HX` 는 **새 보존식을 쓰지 않는다.** shell/tube 각각 `GenericPipe_MultiTransferSurface`
(→ 2.1 의 질량/에너지/화학종/미량물질/운동량 식)와 `Conduction_2D` 관벽(→ 2.3 의 에너지 식)을
`connect` 로 결합한 조립 모델이다. `counterCurrent=true` 이면 `counterFlow` 블록이 shell 측 열포트
벡터 순서를 뒤집어 향류를 구성한다.

`Simple_HX` 는 `SimpleVolume[nV]` 2열(→ 2.2 의 식) + 마찰저항 + `UA`/`CF` 기반 열전달 요소의 조립 모델.

`EffectivenessNTU_HX` 는 유체 포트가 없고 대수식 한 줄만 존재:
`Q_flow = epsilon*U*surfaceArea/NTU*(T_1_hot - T_1_cold)` (`UnderConstruction` 아이콘 상속).

### 2.5 유량원 / 펌프

`MassFlowSource_T` (`MassFlowSource_T.mo:83-90`) — 보존식이 아니라 경계조건:
```
sum(ports.m_flow) = -m_flow_in_internal
medium.T (또는 medium.h) = 입력값
medium.Xi        = X_in_internal[1:nXi]
ports.C_outflow  = fill(C_in_internal, nPorts)
```

`Pump_SimpleMassFlow` (`Pump_SimpleMassFlow.mo:32-41`)
```
port_a.m_flow + port_b.m_flow = 0
port_a.m_flow = m_flow
h/Xi/C 는 양방향 pass-through (inStream 그대로 전달) → 압력차에 의한 엔탈피 상승 무시
```

`Pump`(→`PartialPump`)는 `PartialVolume(V=0)` 을 상속하므로 정상상태 질량/에너지/화학종/미량물질 균형을 갖고,
```
mb  = port_a.m_flow + port_b.m_flow
Ub  = Σ port.m_flow*actualStream(h_outflow) + (펌프 일)
```
여기에 `FlowChar`(수두-유량 특성), `PowerChar`/효율 특성, 상사법칙(`N`, `diameter`) 관계식이 추가된다.

### 2.6 점동특성

`PointKinetics_L1_powerBased.mo:311-337` — **출력(W) 기준** 점동특성

```
rho = rho_input + Σ alphas_feedback[j]*(vals_feedback[j] - vals_feedback_reference[j])
      + (핵분열생성물 반응도) + (추가 반응도)

der(Q_fission) = (rho - Beta)/Lambda * Q_fission + Σ lambdas[j]*Cs[j] + Q_external/Lambda
der(Cs[j])     = betas[j]/Lambda * Q_fission - lambdas[j]*Cs[j]
Qs_decay[j]    = lambdas_dh[j]*Es[j]
der(Es[j])     = efs_dh[j]*Q_fission - lambdas_dh[j]*Es[j]
Q_total        = Q_fission + Σ Qs_decay
```
(`betas = alphas*Beta`. 각 Dynamics 가 `SteadyState` 이면 좌변 0)

`PointKinetics_L1_atomBased_external.mo:245-265` — **원자수 기준, 선구물질 방정식 외부화**

```
rho = rho_input + Σ 궤환 + Σ fissionProducts.rhos + Σ fissionProducts.rhos_TR

der(Q_fission) = (rho - Beta)/Lambda * Q_fission
                 + Σ_i [ w_f/(Lambda*nu_bar) * Σ_j lambdas[j]*mCs[i,j] ]
                 + w_f/(Lambda*nu_bar) * N_external

mC_gens[i,j]   = betas[j]*nu_bar/w_f * Q_fission * SF_Q_fission[i] - lambdas[j]*mCs[i,j]

Qs_decay[i,:]  = fissionProducts.Qs_near_i[i,:]
Qs[i]          = Q_fission*SF_Q_fission[i] + Σ Qs_decay[i,:]
```
→ **`der(mCs)` 식이 이 모델 안에 없다.** 선구물질 농도의 시간 적분은 유체 모델(파이프의 미량물질 보존식)이
담당하고, 이 모델은 생성/붕괴 항 `mC_gens` 만 계산해 되돌려 준다. 순환연료(MSR) 구성의 핵심 구조.

---

## 3. 용융염 Medium (FLiBe 등) — **존재함**

패키지 루트: `TRANSFORM.Media.Fluids` (`TRANSFORM/Media/Fluids/`)

`package.order` 기준 등록된 유체:
`Sodium`, `FLiBe`, `Incompressible`, `PbLi`, `NaFNaBF4`, `FLiNaK`, `KFZrF4`, `NaFZrF4`, `NaK`, `Water`,
`KClMgCl2`, `DOWTHERM`, `NaClKClMgCl2`, `Therminol_66`, `EthyleneGlycol`, `Lithium`, `NaNO3KNO3`

### 3.1 FLiBe 계열 Medium 경로

| Medium 클래스 | 조성 / 설명 | 물성함수 패키지 |
|---|---|---|
| `TRANSFORM.Media.Fluids.FLiBe.LinearFLiBe_pT` | LiF-BeF2 67-33 mol%, 99.995% Li-7 | `FLiBe.Utilities_FLiBe` |
| `TRANSFORM.Media.Fluids.FLiBe.LinearFLiBe_9999Li7_pT` | LiF-BeF2 66-34 mol%, 99.99% Li-7 | `FLiBe.Utilities_9999Li7` |
| `TRANSFORM.Media.Fluids.FLiBe.LinearFLiBe_12Th_05U_pT` | LiF-BeF2-ThF4-UF4 71.5-16-12-0.5 mol% (연료염) | `FLiBe.Utilities_12Th_05U` |
| `TRANSFORM.Media.Fluids.FLiBe.LinearFLiBe_64LiF_30BeF2_5ZrF4_1UF4_CrFeNi` | **MSRE 연료염** LiF-BeF2-ZrF4-UF4 + Cr/Fe/Ni | `FLiBe.Utilities_64LiF_30BeF2_5ZrF4_1UF4_CrFeNi` |
| `TRANSFORM.Media.Fluids.FLiBe.ConstantPropertyLiquidFLiBe` | 상수물성 단순 매질 | — |

파일 경로: `TRANSFORM/Media/Fluids/FLiBe/<클래스명>/package.mo`,
물성함수: `TRANSFORM/Media/Fluids/FLiBe/<Utilities_*>/{d_T.mo, cp_T.mo, eta_T.mo, lambda_T.mo}`

`Linear*` 계열은 모두 `TRANSFORM.Media.Interfaces.Fluids.PartialLinearFluid` 를 상속(선형 압축성, p-T 기반).

### 3.2 물성 상관식 (실제 코드값)

**`LinearFLiBe_pT` / `Utilities_FLiBe` (출처 주석: ORNL/TM-2006/12)**

| 물성 | 상관식 | 파일 |
|---|---|---|
| 밀도 | `d = -0.4884*T + 2413` [kg/m³, T in K] | `Utilities_FLiBe/d_T.mo` |
| 비열 | `cp = 2416` [J/kg-K] (상수) | `Utilities_FLiBe/cp_T.mo` |
| 점도 | `eta = 1.16e-4*exp(3755/T)` [Pa·s] | `Utilities_FLiBe/eta_T.mo` |
| 열전도도 | `lambda = 0.0005*T + 0.63` [W/m-K] | `Utilities_FLiBe/lambda_T.mo` |

패키지 상수: `reference_p=1e5`, `reference_T=800`, `beta_const=2.4151e-4`, `kappa_const=2.89e-10`,
`MM_const=0.033`, `T_default=800`, `reference_h = cp_T(800)*(800-273.15)`, `reference_s=0`, `constantJacobian=false`

**`LinearFLiBe_9999Li7_pT` / `Utilities_9999Li7` (출처 주석: ORNL-TM-3832 Table 3, 영국단위 변환)**

| 물성 | 상관식 |
|---|---|
| 밀도 | `d = from_lb_feet3(138.68 - 0.01456*to_degF(T))` |
| 비열 | `cp = from_btu_lbF(0.57)` |
| 점도 | `eta = from_lb_hrfeet(0.2806*exp(6759/to_degR(T)))` |
| 열전도도 | `lambda = from_btu_hrfeetF(0.58)` |

`beta_const=2.106645e-4`, `kappa_const=2.89e-10`

**`LinearFLiBe_12Th_05U_pT` / `Utilities_12Th_05U` (출처 주석: ORNL-TM-3832 Table 3)**

| 물성 | 상관식 |
|---|---|
| 밀도 | `d = from_lb_feet3(236.3 - 0.0233*to_degF(T))` |
| 비열 | `cp = from_btu_lbF(0.32)` |
| 점도 | `eta = from_lb_hrfeet(0.2637*exp(7362/to_degR(T)))` |
| 열전도도 | `lambda = from_btu_hrfeetF(0.75)` |

`beta_const=1.964787e-4`, `kappa_const=2.89e-10`

**`LinearFLiBe_64LiF_30BeF2_5ZrF4_1UF4_CrFeNi` / `Utilities_64LiF_...` (출처 주석: ORNL-TM-4865 Table 2.1, 2.2 — MSRE)**

| 물성 | 상관식 |
|---|---|
| 밀도 | `d = (2.575 - 5.13e-4*(T-273.15))*1000` [kg/m³] |
| 비열 | `cp = from_cal_gK(0.57)` |
| 점도 | `eta = 0.116e-3*exp(3755/T)` |
| 열전도도 | `lambda = 1.0` [W/m-K] (상수) |

`beta_const=2.22586e-4`, `kappa_const=5.5072154e-11`

**`ConstantPropertyLiquidFLiBe`** — `Modelica.Media.Interfaces.PartialSimpleMedium` 상속:
`cp_const=2380`, `cv_const=1785`, `d_const=1948`, `eta_const=0.006`, `lambda_const=1.1059`,
`a_const=3300`, `T_min=850`, `T_max=1050`, `MM_const=0.072948`

### 3.3 기타 용융염

`FLiNaK`, `KFZrF4`, `NaFZrF4`, `NaFNaBF4`, `KClMgCl2`, `NaClKClMgCl2`, `NaNO3KNO3` 도 같은 `Linear*_pT` +
`Utilities_*` 패턴으로 존재함 (`TRANSFORM/Media/Fluids/<name>/`). 각 상관식 상세는 이번 조사에서
FLiBe 계열만 코드 확인함 — **나머지 염의 개별 상관식 값은 확인 불가(미확인)**.

### 3.4 예제

`TRANSFORM/Media/Fluids/Examples/` 에 `LinearFLiBe_pT.mo`, `LinearFLiBe_9999Li7.mo`,
`LinearFLiBe_12Th_05U_pT.mo`, `LinearFLiBe_64LiF_30BeF2_5ZrF4_1UF4_CrFeNi.mo`, `LinearFLiNaK_pT.mo` 등 존재.

---

## 4. 파이프의 trace substance (C / extraPropertiesNames / nC) 이송 지원 — **지원함**

### 4.1 이송 경로

- 커넥터: `TRANSFORM.Fluid.Interfaces.FluidPort` (`TRANSFORM/Fluid/Interfaces/FluidPort.mo`)
  ```modelica
  stream Medium.ExtraProperty C_outflow[Medium.nC];
  ```
  → `FluidPort_Flow`, `FluidPort_State`, `FluidPorts_Flow`, `FluidPorts_State` 모두 상속.
- 파이프 내부 상태량: `Cs[nV, Medium.nC]` (`stateSelect=StateSelect.prefer`),
  `mCs[nV,nC] = ms[i].*Cs[i,:]`, 수치안정용 `mCs_scaled = mCs./Medium.C_nominal`
  (`PartialDistributedVolume.mo:72-78, 195-196`)
- 이송 플럭스: `mC_flows[nV+1, nC]`, 상류차분 `semiLinear` (`GenericPipe_MultiTransferSurface.mo`,
  `GenericPipe.mo:415-444`)
- 초기값: `C_a_start[nC]`, `C_b_start[nC]` → `Cs_start[nV,nC] = linspaceRepeat_1D(...)`
- Dynamics: `traceDynamics` (기본 `massDynamics` 상속)
- `Medium.nC` / `Medium.extraPropertiesNames` / `Medium.C_nominal` 은 Modelica 표준 `PartialMedium`
  메커니즘 그대로 사용 → Medium 재선언 시 `extraPropertiesNames=...`, `C_nominal=...` 로 주입

### 4.2 소스텀(생성/소멸) 주입 인터페이스 — **존재함**, 두 가지 경로

**(a) 체적 내부 생성항: `InternalTraceGen` 교체 모델**

- 인터페이스: `TRANSFORM.Fluid.ClosureRelations.InternalTraceGeneration.Models.DistributedVolume_Trace_1D.PartialInternalTraceGeneration`
  파일: `TRANSFORM/Fluid/ClosureRelations/InternalTraceGeneration/Models/DistributedVolume_Trace_1D/PartialInternalTraceGeneration.mo`
  - 입력: `Medium`, `nV`, `states[nV]`, `Cs[nV,nC]`, `Vs[nV]`, `dimensions[nV]`, `crossAreas[nV]`, `dlengths[nV]`
  - 출력: `mC_flows[nV, Medium.nC]` (`SIadd.ExtraPropertyFlowRate`)
- 구현체 2종:
  - `GenericTraceGeneration` — 입력 `mC_gen[nC]`, `mC_gens[nV,nC]`; 식 `mC_flows[i,ic] = mC_gens[i,ic]`
  - `VolumetricTraceGeneration` — 입력 `mC_ppp[nC]`, `mC_ppps[nV,nC]`; 식 `mC_flows[i,ic] = mC_ppps[i,ic]*Vs[i]`
- 파이프의 보존식에 `+ internalTraceGen.mC_flows[i,:]/nParallel` 로 직접 들어감.
- **`InternalTraceGen` 을 `replaceable model` 로 노출하는 컴포넌트** (grep 결과 전부):
  - `TRANSFORM.Fluid.Pipes.GenericPipe` (`:202`)
  - `TRANSFORM.Fluid.Pipes.GenericPipe_MultiTransferSurface` (`:205`)
  - `TRANSFORM.Fluid.Pipes.BaseClasses.GenericPipe_wTraceMass_Record` (`:14`)
  - `TRANSFORM.Fluid.Pipes.BaseClasses.GenericPipe_wTraceMass_Record_multiSurface` (`:15`)
    → 이를 상속하는 `GenericPipe_wWall_wTraceMass`
  - `TRANSFORM.HeatExchangers.GenericDistributed_HX` (`InternalTraceGen_tube` `:490`, `InternalTraceGen_shell` `:493`)
  - `TRANSFORM.HeatExchangers.GenericDistributed_HX_Rwall` (`:460`, `:463`)
  - `TRANSFORM.HeatExchangers.GenericDistributed_HX_withMass` (`:538`, `:542`)
- **주의**: `TRANSFORM.Fluid.Pipes.GenericPipe_withWall` / `GenericPipe_withWallx2` /
  `GenericPipe_withWallAndInsulation` 에는 `InternalTraceGen` 이 외부로 노출되어 있지 않다(grep 결과 0건).
  미량물질은 통과·이송되지만, 이 래퍼들에서는 소스텀을 밖에서 꽂을 수 없다.
  → 소스텀이 필요하면 `GenericPipe_MultiTransferSurface` 또는 `GenericPipe_wWall_wTraceMass` 를 쓸 것.

사용 예 (`TRANSFORM/Nuclear/ReactorKinetics/Examples/PointKinetics_Drift_Test_flat.mo:57-63`):

```modelica
redeclare model InternalTraceGen =
  TRANSFORM.Fluid.ClosureRelations.InternalTraceGeneration.Models
    .DistributedVolume_Trace_1D.GenericTraceGeneration (
      mC_gens = cat(2,
        core_kinetics.mC_gens,
        core_kinetics.fissionProducts.mC_gens,
        core_kinetics.fissionProducts.mC_gens_TR))
```

**(b) 벽면 물질전달: `TraceMassTransfer` + `massPorts`**

- `use_TraceMassTransfer=true` 로 활성화, `massPorts[nV, nSurfaces]` (`MolePort_Flow`) 노출
- 인터페이스: `...ClosureRelations.MassTransfer.Models.DistributedPipe_TraceMass_1D.PartialMassTransfer_setC`
  및 `..._1D_MultiTransferSurface.PartialMassTransfer_setC`
- 보존식에 `+ traceMassTransfer.mC_flows[i,:]` 로 합산

**(c) 집중정수 체적**: `SimpleVolume` / `MixingVolume` 은 `mC_gen[Medium.nC]` (input) 을 직접 제공,
`use_TraceMassPort` 로 `traceMassPort` (`MolePort_State`) 도 노출.

### 4.3 미량물질 이름/스케일 자동 구성

`TRANSFORM.Nuclear.ReactorKinetics.Data.summary_traceSubstances`
(`TRANSFORM/Nuclear/ReactorKinetics/Data/summary_traceSubstances.mo`) 가
선구물질(PG) + 핵분열생성물(FP) + 삼중수소(TR) + 부식생성물(CP) 을 이어붙여
`extraPropertiesNames[nC]`, `C_nominal[nC]`, `lambdas[nC]`, `parents[nC,nC]`, `w_near_decay`, `w_far_decay` 와
구간 인덱스 `iPG[2]`, `iFP[2]`, `iTR[2]`, `iCP[2]`, `iH3` 를 제공한다.

Medium 선언 시 이렇게 연결 (같은 예제 `:5-8`):

```modelica
replaceable package Medium = TRANSFORM.Media.Fluids.FLiBe.LinearFLiBe_pT (
  extraPropertiesNames = core_kinetics.summary_data.extraPropertiesNames,
  C_nominal            = core_kinetics.summary_data.C_nominal);
```

관련 미량물질 전용 컴포넌트: `TRANSFORM/Fluid/TraceComponents/`
(`TraceDecayAdsorberBed.mo`, `TraceDecayAdsorberBed_sparseMatrix.mo`, `TraceSeparator.mo`,
`DecayBed_Simple.mo`, `SimpleSeparator.mo`),
센서 `TRANSFORM/Fluid/Sensors/{TraceSubstances.mo, TraceSubstancesTwoPort.mo, TraceSubstancesTwoPort_multi.mo}`.

---

## 5. 점동특성이 지연중성자 선구물질 농도를 외부 입력으로 받는 구조인가 — **가능함 (전용 모델 존재)**

### 5.1 해당 모델

`TRANSFORM.Nuclear.ReactorKinetics.PointKinetics_L1_atomBased_external`
(`TRANSFORM/Nuclear/ReactorKinetics/PointKinetics_L1_atomBased_external.mo`)

핵심 선언 (`:26-33`, `:198-199`, `:245-262`):

```modelica
parameter Integer nV = 1 "# of discrete volumes";
input SI.Volume[nV] Vs "Volume for atom concentration basis";
input SIadd.ExtraPropertyExtrinsic[nV,nC]  mCs    "# of neutron precursors in each volume [atoms]";
input SIadd.ExtraPropertyExtrinsic[nV,nFP] mCs_FP "Fission product number in each volume [atoms]";
input TRANSFORM.Units.ExtraPropertyExtrinsic mCs_TR[nV,nTR] "tritium contributors [atoms]";
input TRANSFORM.Units.NonDim SF_Q_fission[nV] "Shape factor for Q_fission, sum() = 1";

SIadd.ExtraPropertyFlowRate[nV,nC] mC_gens
  "Generation rate of neutron precursor groups [atoms/s]";
```

즉 **선구물질 농도 `mCs` 는 input, 생성률 `mC_gens` 는 output** 이다. 모델 내부에 `der(mCs)` 방정식이
없으므로, 선구물질 수송·적분은 유체 모델이 맡는 완전 외부화 구조다.

### 5.2 결합 방식 (레포 내 실제 예제)

`TRANSFORM/Nuclear/ReactorKinetics/Examples/PointKinetics_Drift_Test_flat.mo` (MSR 순환연료 형태):

1. Medium 을 FLiBe + `summary_data` 기반 `extraPropertiesNames`/`C_nominal` 로 선언
2. 노심 `core` = `GenericPipe_MultiTransferSurface`, 루프 `loop_` = 같은 모델, 폐루프로 연결
3. 파이프 → 동특성: 노드별 원자수 전달
   ```modelica
   core_kinetics(
     nV = core.nV,
     Vs = core.Vs*core.nParallel,
     mCs    = core.mCs[:, summary_data.iPG[1]:summary_data.iPG[2]]*core.nParallel,
     mCs_FP = core.mCs[:, summary_data.iFP[1]:summary_data.iFP[2]]*core.nParallel, ...)
   ```
4. 동특성 → 파이프: 생성항 주입
   ```modelica
   redeclare model InternalTraceGen = ...GenericTraceGeneration(
     mC_gens = cat(2, core_kinetics.mC_gens,
                      core_kinetics.fissionProducts.mC_gens,
                      core_kinetics.fissionProducts.mC_gens_TR))
   ```
5. 노심 밖 배관은 붕괴만 (`-lambda*mC` + 모핵종 전이 `parents` 행렬) 을 `mC_gens_pipe1` 로 직접 구성해 주입
6. 온도 궤환: `nFeedback=1`, `vals_feedback={core.summary.T_effective}`, `alphas_feedback={-1e-4}`
7. 발열: `InternalHeatGen = GenericHeatGeneration(Q_gens = core_kinetics.Qs + fissionProducts.Qs_far)`

동일 계열 예제:
`PointKinetics_Drift_Test_flat_Xenon.mo`, `PointKinetics_Drift_Test_sine.mo`,
`PointKinetics_Drift_Test_feedback_Xenon.mo` (모두 `TRANSFORM/Nuclear/ReactorKinetics/Examples/`)

### 5.3 사용 가능한 선구물질 데이터 레코드

`TRANSFORM/Nuclear/ReactorKinetics/Data/PrecursorGroups/`

| 레코드 | 값 |
|---|---|
| `precursorGroups_6_FLiBeFueledSalt` | `lambdas={0.0125,0.0318,0.109,0.317,1.35,8.64}`, `alphas={0.0320,0.1664,0.1613,0.4596,0.1335,0.0472}`, `Beta=0.0065`, `C_nominal=fill(1e14,6)` |
| `precursorGroups_6_TRACEdefault` | 6군 TRACE 기본값 |
| `precursorGroups_1_userDefined` | 사용자 정의 1군 |
| `PartialPrecursorGroup` / `PartialPrecursorGroup_betas` | 베이스 레코드 (`extraPropertiesNames`, `alphas`, `Beta`, `lambdas`, `parents[nC,nC]`, `w_near_decay`, `w_far_decay`, `C_nominal`) |

기타 데이터: `Data/DecayHeat/`(`decayHeat_0`, `decayHeat_11_TRACEdefault`),
`Data/FissionProducts/`(`fissionProducts_0`, `fissionProducts_91_U235_Pu239`, `fissionProducts_cut6_U235_Pu239`,
`fissionProducts_TeIXe_U235`, `fissionProducts_H3TeIXe_U235`, `fissionProducts_test`),
`Data/Tritium/`(`tritium_0`, `FLiBe`), `Data/CorrosionProducts/`(`corrosionProduct_0`, `corrosionProduct_1_Cr`)

### 5.4 대비: 내부 상태형

`PointKinetics_L1_powerBased` 는 `Cs[nC]` 를 **내부 상태변수**로 갖고 `der(Cs)` 를 직접 푼다.
따라서 순환연료로 인한 선구물질 유실/드리프트를 모사하려면 `atomBased_external` 쪽을 써야 한다.
(`powerBased` 에도 `nC_add`, `mCs_add[nC_add]` 입력이 있으나 이는 *추가 반응도 기여 물질*용이지
선구물질 방정식 외부화가 아니다.)

---

## 6. MSR 관련 참고 자산

| 항목 | 경로 |
|---|---|
| MSR 예제 (BOP 없음) | `TRANSFORM/Examples/MoltenSaltReactor/MSDR_noBOP.mo` |
| MSR 서브컴포넌트 | `TRANSFORM/Examples/MoltenSaltReactor/Components/{BOP.mo, BOP2.mo, BOP3.mo, DRACS.mo}` |
| MSR 데이터 레코드 | `TRANSFORM/Examples/MoltenSaltReactor/Data/{data_RCTR, data_PHX, data_SHX, data_PIPING, data_PUMP, data_OFFGAS, data_BOP, Summary}.mo` |
| 미량물질 수송 검증 예제 | `TRANSFORM/Fluid/Pipes/Examples/SpeciesTransportProgressionProblems/` |
| 삼중수소 예제 | `TRANSFORM/Fluid/Examples/TritiumExamples/` |
| 노심 서브채널/연료 모델 | `TRANSFORM/Nuclear/CoreSubchannels/`, `TRANSFORM/Nuclear/FuelModels/`, `TRANSFORM/Nuclear/PowerProfiles/` |

---

## 7. 확인 불가 / 미확인 항목

- FLiBe 이외 용융염(`FLiNaK`, `KFZrF4`, `NaFZrF4`, `NaFNaBF4`, `KClMgCl2`, `NaClKClMgCl2`, `NaNO3KNO3`)의
  개별 물성 상관식 수식 — 패키지 존재는 확인, 상관식 값은 **확인 불가(미열람)**
- `GenericDistributed_HX_Rwall`, `GenericDistributed_HX_withMass`, `BellDelaware_STHX` 의 상세 방정식 —
  파일 존재와 `InternalTraceGen_*` 노출 여부만 확인, 내부 식은 **확인 불가(미열람)**
- `PumpCharacteristics` 하위 개별 곡선 함수의 수식 — 디렉터리 구성만 확인, **확인 불가(미열람)**
- `SparseMatrix` 계열 점동특성(`PointKinetics_L1_*_sparseMatrix`)의 방정식 — 파일 존재만 확인, **확인 불가(미열람)**
- `Conduction_2D` / `Conduction_3D` 의 이산화 상세 — `Conduction_1D` 만 코드 확인, 나머지 **확인 불가(미열람)**
- `EffectivenessNTU_HX` 는 유체 포트가 없고 `UnderConstruction` 상태이므로 실사용 가능한 ε-NTU
  2유체 열교환기는 이 레포에서 **확인되지 않음**
