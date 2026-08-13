# 벤치마킹 스코프 정의

이 저장소의 검증 대상과 참고 문헌의 역할을 확정한다. Phase 통과 판정은 이 문서의 §2 표에
있는 수치로만 한다.

## 1. 문헌의 역할

| 문헌 | 약칭 | 역할 |
|---|---|---|
| J.J. Jeong, Y.J. Cho, H.C. Lee, B. Yun, *Benchmarking the MARS code for molten salt reactor applications using MSRE transient experiments*, Nucl. Eng. Technol. **58** (2026) 104438 | **MARS** | **유일한 벤치마킹 대상.** 수치 대조·통과 판정의 기준 |
| L. Fischer, L. Bureš, *Application of Modelica/TRANSFORM to system modeling of the MSRE*, Nucl. Eng. Des. **416** (2024) 112768 | Fischer | **구현 참고용.** 컴포넌트 배선·closure 구조만 참고. 수치 대조 대상 아님 |
| C. Mao, J. Guo, Y. Zou, R. Yan, *Preliminary Study of Transient Simulations in the MSRE Primary Loop with Modelica/TRANSFORM*, Energies **19** (2026) 13 | Mao | **구현 참고용.** 동일 |

Fischer / Mao 는 같은 도구(Modelica/TRANSFORM)를 쓴 선행 구현이므로 "TRANSFORM 에서 이렇게
배선한다"는 관용구의 근거로만 인용한다. 두 논문의 결과 수치와 본 모델의 결과가 다르다는
사실만으로는 통과·불통과를 판정하지 않는다.

## 2. 통과 판정 기준 수치 (MARS 논문)

| 시험 | 항목 | MARS 계산 | 실험 | 출처 |
|---|---|---|---|---|
| Pump startup | 제어봉 반응도, 25–45 s 평균 | 222.4 pcm | 227.3 pcm | §4.1.1 |
| | 반응도 진동 피크 시각 | 15.3 / 40.7 / 66.2 s (주기 ≈25.5 s) | 미기재 | §4.1.1, Fig. 6 |
| | 점근 반응도 손실 (150 s) | 226.5 pcm | 미기재 | §4.1.2, Fig. 6 |
| | Eq. (8) 해석해 | 228.4 pcm | — | §4.1.2 |
| | τ_C / τ_L (150 s) | 9.56 s / 16.14 s | 미기재 | §4.1.2 |
| | 시스템 전이시간 (전출력) | 25.63 s | 25.2 s | §3.2 |
| | 유량 정격 도달 시간 | ≈10 s | 정규화 유량 표준편차 0.031 | §4.1, §4.1.1, Fig. 4 |
| | 노심체적 확장 민감도 | 50 s 에서 손실 14.2 pcm 감소 (τ_C +1.11 s, τ_L −1.11 s) | — | §4.1.2 |
| Pump coastdown | 초기 유량 | 168 kg/s | 표준편차 1.4 % @20 s | §4.2, Fig. 7 |
| | 반응도 일치 구간 | 70 s 까지 | 측정창 내 평형 미도달 | §4.2 |
| Natural circulation | 초기 유량 (null transient 5000 s 후) | 1.46 kg/s | 미보고 | §4.3, Fig. 10 |
| | 21,000 s 유량 | 4.45 kg/s | 미기재 | §4.3, Fig. 10 |
| | 21,000 s 노심 출력 | 304.5 kW | ≈354 kW | §4.3, Fig. 11 |
| | Eq. (8) drift (초 / 말) | 0.9 pcm / 6.7 pcm | — | §4.3 |
| | 평균 연료염 온도 강하 | ≈4.0 K (≈60 pcm 상당) | 미기재 | §4.3 |
| | C1 (+10 % HX 면적) 최종 출력 | 기저 대비 +12.2 kW | — | §4.3 |

원자력 데이터는 MARS Table 1 (U-235 6군), Table 2 (U-233 6군), Table 3 (Λ, α_f, α_g) 을 그대로
쓴다. 세 표 모두 MARS Ref. [9] 에서 인용된 값이다.

## 3. MARS 논문이 수치를 제공하지 않는 항목 — 통과조건으로 쓸 수 없음

아래는 원문 대조 결과 **미기재**이므로, 이 항목으로 통과 판정을 하려면 기준을 별도로
정의해야 한다 (§5 확인 필요 항목 참조).

| 항목 | 상태 |
|---|---|
| β_eff 수치 | 미기재. Eq. (6) 으로 정의만 하고 값은 본문 어디에도 없음 |
| DNP 축방향·반경방향 분포 | 미기재. 해당 그림·표 없음 |
| 정상상태 노심 온도 절대값 | 미기재. Fig. 9 곡선만 있고 표 없음. §4.3 에서 절대값 불일치를 명시적으로 유보 |
| 연료염 물성 상관식 | 미기재. §2 에 "구현했다" 는 서술만 있고 수치·식 없음 |
| 반경방향 출력 분포 | 비공개. Serpent 계산 결과 (Ref. [9]) |
| 펌프 head / torque / 관성모멘트 | 미기재. §3.2 "not available", generic pump parameters 사용 |
| 노드별 유체 체적 분해 | 미기재 |

## 4. MARS 논문이 스스로 밝힌 한계

아래는 **재현 대상이지만 물리적 정답이 아니다.** 재현에 성공해도 "물리적으로 옳다"는 근거가
되지 않으며, 반대로 개선 시도는 벤치마킹 실패가 아니라 별도 항목으로 다룬다.

- **중요도 φ\* = 1** (§3.2). §4.1.2 원문: *"the good agreement does not imply that this assumption
  is appropriate. Rather, the result appears to be influenced by an **error compensation effect**."*
  결론에서 "neutron importance for the modified PKM" 을 향후 개선 방향으로 명시.
- **흑연 발열 분율 0** (§3.2, code limitation). 결론: *"should be treated as a **top priority** in
  future code development."*
- **저유량 조건 HX 열전달 과소평가** (§4.3). HX 모델을 이 시험의 결정적 인자로 지목.
- **form loss 계수와 HX 전열면적을 전출력 정상상태에 맞춰 보정** (§3.2).

## 5. MARS 노달라이제이션 (재현 기준)

- 1·2차계 합계 387 control volumes, 400 junctions (§3.2)
- 노심 15 개 동심 반경 링 × 20 축방향 노드 = 300 셀 (§3.2)
- 하부/상부 플레넘 각 3 축방향 노드 (§3.2)
- 노심 경계 = 하부 Volume 120-03, 상부 Volume 190-01 (§3.2)
- 열교환기 shell 측 10 volumes, **tube 측 20 volumes** (§3.2)
- 팽창탱크 = time-dependent volume (§3.2)
- 축방향 출력 = 코사인 (Fig. 3)
- DNP 수송 이산화 = semi-implicit, 1차 풍상차분 (§2.1)

## 6. 판정 원칙

1. 문헌 수치는 논문명 + 절/표/식 번호를 함께 적는다. 출처가 없으면 "미기재" 로 둔다.
2. §3 의 미기재 항목은 MARS 기준 통과 판정에 쓰지 않는다.
3. §4 항목을 개선하는 변경은 "벤치마킹 불일치" 가 아니라 별도 개선 항목으로 기록한다.
4. 통과·완료 판정은 사용자가 한다.
