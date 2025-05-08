# MatchHub

Flutter로 개발된 매치 대진표 및 대회 관리 애플리케이션입니다.

## 주요 기능

- 리그 대진표 생성 및 관리
- 토너먼트 대진표 생성 및 관리
- 대회 개최 및 참가 기능
- Firebase를 통한 데이터 저장 및 관리

## 기술 스택

- Flutter/Dart
- Firebase (Firestore)
- flutter_tournament_bracket 라이브러리

## 시작하기

1. Flutter 설치: [Flutter 공식 문서](https://docs.flutter.dev/get-started/install)
2. 의존성 설치:
```
flutter pub get
```
3. Firebase 설정:
   - [Firebase 콘솔](https://console.firebase.google.com/)에서 새 프로젝트 생성
   - FlutterFire CLI 설치 및 설정:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   - 또는 예제 파일을 사용하여 수동으로 설정:
     - `lib/firebase_options.example.dart` 파일을 복사하여 `lib/firebase_options.dart` 생성
     - `android/app/google-services.example.json` 파일을 복사하여 `android/app/google-services.json` 생성
     - `ios/Runner/GoogleService-Info.example.plist` 파일을 복사하여 `ios/Runner/GoogleService-Info.plist` 생성
     - 각 파일에서 `YOUR_` 접두사가 붙은 값들을 Firebase 콘솔에서 가져온 실제 값으로 변경

4. 앱 실행:
```
flutter run
```

## 개발 프로세스 및 브랜치 관리 규칙

프로젝트는 다음과 같은 브랜치 구조로 관리됩니다:

- **main**: 소스 코드 개발 브랜치
- **gh-pages**: 웹 빌드 결과물을 위한 브랜치 (GitHub Pages 호스팅용)

### 소스 코드 개발 (main 브랜치)

1. 항상 `main` 브랜치에서 작업합니다:
   ```
   git checkout main
   ```

2. 변경사항 커밋 및 푸시:
   ```
   git add .
   git commit -m "기능 설명: 변경 내용 요약"
   git push origin main
   ```

3. 다른 환경에서 작업할 경우:
   ```
   git clone https://github.com/namseokyoo/match_planner.git
   cd match_planner
   flutter pub get
   ```

### 웹 배포 프로세스 (gh-pages 브랜치)

1. 소스 코드 변경 후 웹 빌드 생성:
   ```
   flutter build web
   ```

2. gh-pages 브랜치로 전환:
   ```
   git checkout gh-pages
   ```

3. 이전 파일 삭제 및 새 빌드 파일 복사:
   ```
   git rm -rf .
   cp -r build/web/* . && cp -r build/web/.* . 2>/dev/null || true
   ```

4. 변경사항 커밋 및 푸시:
   ```
   git add -A
   git commit -m "웹 빌드 업데이트: 변경 내용 요약"
   git push -f origin gh-pages
   ```

5. 다시 메인 브랜치로 돌아오기:
   ```
   git checkout main
   ```

### 주의사항

- 소스 코드는 반드시 `main` 브랜치에만 있어야 합니다.
- `gh-pages` 브랜치에는 웹 빌드 결과물만 있어야 합니다.
- API 키와 같은 민감한 정보는 항상 `.gitignore`에 포함시켜 Git에 커밋되지 않도록 합니다.
- 웹 배포 시 `--force` 옵션 사용에 주의하세요. 항상 최신 웹 빌드만 유지됩니다.

## 배포

### 웹 빌드 및 배포
```
flutter build web
```

웹 앱은 GitHub Pages를 통해 호스팅되며, 다음 URL에서 접근할 수 있습니다:
https://namseokyoo.github.io/match_planner/

## 보안 주의사항

이 프로젝트는 Firebase API 키와 같은 민감한 정보를 사용합니다. 이러한 정보는 버전 관리 시스템에 포함되지 않도록 주의해야 합니다. `.gitignore` 파일에 다음 항목이 포함되어 있는지 확인하세요:

```
lib/firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```
