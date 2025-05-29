# Seamless Video Uploader Library

## 개요

SVU의 라이브러리를 관리하는 리포지토리입니다.


## 디렉토리 구조

```
/srv/
└── botherless-vc/
    ├── frontend/       # 프론트엔드 레포지토리
    │   ├── dist/       # 빌드 후 생성된 정적 파일 (Nginx가 서빙할 디렉토리)
    │   └── ...         # 소스 코드 및 기타 파일
    │
    ├── backend/        # 백엔드 레포지토리
    │   └── ...         # 소스 코드, 빌드 파일 및 기타 파일
    │
    └── library/        # 라이브러리 레포지토리
        └── ...         # 소스 코드 및 기타 파일

/var/log/
└── botherless-vc/    # BotherlessVC 관련 로그파일
```