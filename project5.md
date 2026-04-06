AI 기반 실시간 학습 집중도 평가 플랫폼 - 프로젝트 분석 (이력서용)
1. 프로젝트 설명
프로젝트명: AI 기반 실시간 학습 집중도 평가 플랫폼
기간: 2026.03.16 ~ 2026.04.02 (약 2.5주)
소속: 멋쟁이사자처럼
팀 구성: 2명

프로젝트 목표:
기존 온라인 강의는 학습자의 반응을 즉각적으로 확인하기 어렵다는 한계가 있었습니다. 본 플랫폼은 학습자의 웹캠 하나로 표정·시선·자세·핸드폰 사용 여부를 AI로 실시간 분석하여 강의자에게 즉각 피드백을 제공하고, 세션 종료 후 LLM 기반 강의 개선 리포트를 생성하는 에듀테크 플랫폼입니다.

2. 주요 기능 및 기술 스택
2.1 핵심 기능
웹캠 기반 집중도·피로도·졸음 실시간 수치화
RandomForest 5-class 표정 분류 (집중/지루함/혼란/웃음/놀람)
YOLOv11s 핸드폰 사용 탐지 및 즉시 알림
WebSocket 기반 0.1초 단위 실시간 데이터 전송
강의자 대시보드 (학습자별 상태 카드, 집중도 추이 그래프, 카테고리 필터)
세션 종료 후 Gemini LLM 기반 AI 총평 리포트
매니저 대시보드 (다중 강의 동시 모니터링)
2.2 기술 스택
분류	기술
AI/감지	MediaPipe FaceLandmarker (52 blendshape → 82 피처), RandomForest 표정 분류, YOLOv11s, EAR 졸음 감지, solvePnP Head Pose
Backend	FastAPI, WebSocket, PostgreSQL (psycopg2 ThreadedConnectionPool), uvicorn
Frontend	React 19 + Vite, Recharts (라인/레이더/바 차트), Vercel 배포
Infra	VPS + DuckDNS (HTTPS/WSS), Google Colab + ngrok (GPU 추론 서버)
LLM	Google Gemini API (강의 분석 리포트 생성)
3. 담당 역할 및 핵심 구현 사항
3-1. AI 감지 모듈 설계 및 집중도 스코어링 엔진 구현
역할: MediaPipe 기반 멀티모달 집중도 점수 산출 시스템 직접 설계·구현

세부 구현:

시선(Iris Gaze Yaw/Pitch), 머리 방향(solvePnP), 어깨 자세를 종합한 집중도 공식 설계
focus_score = gaze×0.60 + head×0.40 − shoulder_penalty×0.10
EMA 스무딩(α=0.05) 적용, 상태 전환 20~25프레임 확인 후 확정
피로도 공식 설계: EAR×0.25 + 경과시간×0.35 + 시선고착×0.25 + 머리움직임×0.15
표정 모델(RandomForest 5-class) 연동 및 혼란 보정 Binary Classifier 통합
Google Colab GPU 서버(ngrok)와 로컬 분석 병렬 추론 파이프라인 구축
성과:

집중도·피로도 두 축의 독립적 스코어링으로 "집중하지만 피로한 상태" 구별 가능
스코어러 보정 2회 반복(scorer fixed, scorer calibrate fixed)을 통한 안정화
3-2. FastAPI + WebSocket 실시간 아키텍처 설계 및 구현
역할: 학습자 ↔ 서버 ↔ 강의자 3자 간 실시간 데이터 흐름 전체 설계·구현

세부 구현:

FastAPI WebSocket 엔드포인트 2종 설계
/ws/client/{session_id}/{user_id} (학습자 감지 클라이언트)
/ws/dashboard/{session_id} (강의자/매니저 대시보드)
UUID 기반 세션 관리, 자동 재연결·Ping-Pong keepalive 구현
PostgreSQL ThreadedConnectionPool로 DB 동시성 처리
KST 타임존 통일 (서버·DB 전체 UTC+9 일관성 확보)
강의자 화면 브로드캐스트 + 학습자 화면 동기화 동시 구현
성과:

0.1초 단위 실시간 데이터 전달 달성
새 아키텍처 전환 1회(Update server, frontend, and gitignore for new architecture)로 학습자/강의자 분리 구조 확립
3-3. React 프론트엔드 개발 및 Vercel 배포
역할: 강의자 대시보드, 학습자 화면, 매니저 대시보드 전체 프론트엔드 구현

세부 구현:

학습자별 실시간 상태 카드 (집중도, 피로도, 눈 깜빡임/min, 표정 이모지)
Recharts 기반 집중도 추이 타임라인 차트, 표정 분포 레이더 차트
졸음·핸드폰 감지 토스트 알림 (쿨다운 제어: 졸음 1분, 핸드폰 30초)
카테고리 필터 (전체/집중/딴짓/졸음/핸드폰)
Gemini LLM 기반 AI 총평 + 실습 제출률 + 학습자별 집중도 순위 리포트 페이지
Vercel 배포 + DuckDNS 도메인 HTTPS/WSS 연동
4. 문제 해결 경험
4-1. 스코어러 보정 오류 — 집중도 점수 과소/과대 평가 문제
문제 상황:
초기 집중도 스코어러가 특정 자세나 조명 조건에서 비정상적인 점수를 출력하는 문제 발생. (scorer fixed → scorer calibrate fixed 2단계 수정)

해결 과정:

EMA 스무딩 파라미터(α=0.05) 재조정
상태 전환 확정 프레임 수(20~25프레임)를 조건부로 설계
보정 계수 캘리브레이션으로 0~100 범위 안정화
결과:

집중도 점수가 연속적으로 출력되지 않고 노이즈 없는 안정적인 수치 제공
4-2. colab server - websocket 반환 문제

**💡 문제**

코랩 서버로 넘어갈 때 모델은 제대로 예측을 하는데 다시 websocket으로 돌아오는 반환값이 없음으로 돌아옴..

원인

```python
학습자 브라우저 (Vercel: https://xxx.vercel.app)
    │
    ├─ fetch() → Colab ngrok (https://waylon-xxx.ngrok-free.dev/analyze)
    │               ↑
    │         다른 도메인 = 크로스 오리진 요청
    │
    └─ 브라우저가 OPTIONS preflight 요청을 먼저 보냄
                │
                ▼
         Colab FastAPI 서버
         → CORSMiddleware 없음
         → Access-Control-Allow-Origin 헤더 없이 응답
                │
                ▼
         브라우저: "허가 없음, 차단!"
         → fetch() 실패, 예외 발생
         → colabSender.js catch절 실행
         → _connected = false, _result = {}
         → phone_detected 기본값 false

```

- **Colab에서 직접 테스트할 때**: 서버→서버 요청이라 CORS 없음, 정상 동작
- **브라우저 콘솔**: CORS 오류가 뜨지만 `colabSender.js`가 `catch {}`로 조용히 삼켜버림 (에러 로깅 없음)
- **Colab 로그**: 모델 추론은 맞게 됐으니 `pass=True`가 찍힘 → "모델은 맞는데 왜 DB에 False지?" 혼란 발생

→  **브라우저가 요청 자체를 막아서** Colab 서버까지 프레임이 전달이 안 됐던 거임

**💡 해결**

CORS 미들웨어 추가

```python
pp = FastAPI(title='Focus Analyzer - Colab Model Server')
app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_methods=['*'],
    allow_headers=['*'],
)
```
4-3. 피로도 로직 개선 — 단순 EAR 기반 오탐 문제
문제 상황:
초기 피로도가 EAR 단독 지표에 의존해 안경 착용자나 조명 변화 시 오탐 발생.

해결 과정:

단일 EAR → 멀티 피처 가중 합산으로 공식 재설계 (fatigue logic modified)
시선 고착 패턴(30초 프리즈), 머리 움직임 감소 지표 추가
가중치 최적화: EAR×0.25 + 경과시간×0.35 + 시선고착×0.25 + 머리움직임×0.15
결과:

피로도 지표의 다양한 환경 대응력 향상

5. 프로젝트 성과 및 수치
5.1 정량적 성과
지표	수치
전체 커밋 수	36 commits
본인 커밋 수	34 commits (94.4% 기여)
프로젝트 기간	18일 (2026.03.16 ~ 2026.04.02)
팀 규모	4인 (본인: 집중도/피로도 로직 구현 + 풀스택, 팀원: YOLO 핸드폰 감지 및 표정 분석 모델 개발)

5.2 기술적 도전 및 성과
실시간 성능: WebSocket 0.1초 단위 전송, 표정 분류 ~1초 갱신 주기 달성
멀티모달 AI: 시선·머리·어깨·표정·EAR 5가지 신호 통합 집중도 산출
듀얼 추론 파이프라인: 로컬 MediaPipe + Colab GPU 서버 병렬 처리로 표정 분류 오프로딩
LLM 통합: Gemini API로 세션 데이터 자동 요약 → 강의 개선 코멘트 생성
보고서 기준: 강의 품질 향상, 객관적 성과 측정, 학습자 이탈 방지 3가지 기대 효과 입증

6. 마일스톤
Week 1 (2026.03.16~20): 핵심 감지 엔진 구축
✅ 시선/머리/어깨 감지 초기 구현 (본인)
✅ 집중도·피로도 스코어러 초기 설계 (본인)
✅ Colab GPU 표정 분류 서버 구성 (본인)
✅ YOLOv8 핸드폰 감지 모듈 추가 (팀원 LEE JUNSEO)
Week 2 (2026.03.23~27): 서버 아키텍처 전환 + 실시간 연동
✅ FastAPI + WebSocket 새 아키텍처 전환 (본인)
✅ 학습자 프론트엔드 + UUID 세션 관리 구현 (본인)
✅ 강의자 브로드캐스트 + 학습자 화면 동기화 (본인)
✅ 타임존 불일치 문제 해결 (KST 통일) (본인)
✅ 로그인 기능 + 실시간 모니터링 알림 연결 (본인)
Week 3 (2026.03.30~04.02): 기능 완성 + 배포
✅ 피로도 로직 개선 (본인)
✅ 표정 모델 교체 + Gemini AI 리포트 통합 (본인)
✅ 과제 제출률 DB 연동 + 리포트 페이지 실데이터 연결 (본인)
✅ Vercel 프론트엔드 배포 (본인)
✅ 스코어러 보정 수정 + README 작성 (본인)