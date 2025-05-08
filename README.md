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

## 배포

### 웹 빌드 및 배포
```
flutter build web
```

## 보안 주의사항

이 프로젝트는 Firebase API 키와 같은 민감한 정보를 사용합니다. 이러한 정보는 버전 관리 시스템에 포함되지 않도록 주의해야 합니다. `.gitignore` 파일에 다음 항목이 포함되어 있는지 확인하세요:

```
lib/firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```
