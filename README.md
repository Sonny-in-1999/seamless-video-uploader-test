# Cut The Crab!

## 개요

유연한 동영상 편집 기능을 제공하는 웹서비스 입니다.


## 디렉토리 구조

```
/srv/botherless-vc/  # 서비스 배포 루트 디렉토리
├── docker-compose.yml       # Elixir, Go, DB, RabbitMQ 등 모든 서비스를 정의하고 연결
├── .env                     # 환경 변수 파일 (DB 접속 정보, 이미지 태그, API 키 등)
│
├── data/                    # Docker 볼륨을 통해 영속화될 데이터 저장 위치
│   ├── postgres_data/       # PostgreSQL 데이터 파일
│   ├── rabbitmq_data/       # RabbitMQ 데이터 파일 (메시지 큐 사용 시)
│   └── uploaded_videos/     # 업로드되거나 처리된 영상 파일 저장 (로컬 저장 시)
│
└── (선택사항) configs/         # 외부 설정 파일 마운트용 (예: 리버스 프록시 설정)

/var/log/
└── botherless-vc/    # BotherlessVC 관련 로그파일
```

## 로컬 환경 실행

(Erlang/OTP 27 버전 및 해당 버전에 맞는 Elixir가 설치되어있다고 가정합니다.)

```bash
cd cut_the_crab
mix deps.get
mix phx.server
```