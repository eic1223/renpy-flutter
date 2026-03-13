# renpy_flutter

Ren'Py 비주얼 노벨 엔진의 Flutter 포트입니다.
`.rpy` 스크립트를 파싱해 Flutter 위젯으로 렌더링합니다.

## 목차

1. [기능](#기능)
2. [프로젝트 구조](#프로젝트-구조)
3. [예제 앱 빌드 & 실행](#예제-앱-빌드--실행)
4. [샘플 씬 목록](#샘플-씬-목록)
5. [패키지 설치](#패키지-설치)
6. [패키지 사용법](#패키지-사용법)
7. [아키텍처](#아키텍처)
8. [.rpy 문법 레퍼런스](#rpy-문법-레퍼런스)
9. [오디오 연동](#오디오-연동)
10. [저장 / 불러오기](#저장--불러오기)
11. [테스트](#테스트)

---

## 기능

| 구분 | 지원 항목 |
|------|----------|
| **스크립트** | `label`, `jump`, `call`, `return`, `menu`, `if/elif/else`, `$ 변수` |
| **대사** | `say` (화자 / 나레이션), 타이핑 애니메이션, `{b}` `{i}` `{color=}` 태그 |
| **이미지** | `scene`, `show`, `hide`, `with dissolve/fade/blinds/pixellate` |
| **선택지** | `menu` — 조건부 선택지 포함 |
| **오디오** | `play`/`stop` 이벤트 스트림 제공 (직접 연결 가능) |
| **저장/복원** | `GameState.toJson()` / `fromJson()` |

---

## 프로젝트 구조

```
renpy-flutter/
└── flutter_app/                        ← pub 패키지 루트
    ├── pubspec.yaml                    ← 패키지 메타데이터
    ├── README.md
    │
    ├── lib/                            ← 패키지 공개 API
    │   ├── renpy_flutter.dart          ← barrel export (여기서 모든 것 import)
    │   └── src/
    │       ├── ast/
    │       │   └── nodes.dart          ← AST 노드 정의 (LabelNode, SayNode 등)
    │       ├── parser/
    │       │   ├── lexer.dart          ← .rpy → 토큰 스트림
    │       │   └── parser.dart         ← 토큰 → AST 트리
    │       ├── executor/
    │       │   ├── game_executor.dart  ← AST 실행 엔진 + 이벤트 스트림
    │       │   └── script_manager.dart ← 에셋 로드 + label 맵 관리
    │       ├── models/
    │       │   ├── character.dart      ← Character, CharacterRegistry
    │       │   └── game_state.dart     ← GameState (직렬화 지원)
    │       ├── display/
    │       │   ├── game_layer.dart     ← 배경 + 스프라이트 레이어 위젯
    │       │   ├── image_cache.dart    ← 이미지 이름 → 에셋 경로 변환
    │       │   └── transitions.dart    ← dissolve / fade / blinds / pixellate
    │       └── ui/
    │           ├── dialogue_box.dart   ← 타이핑 대화창 위젯
    │           └── menu_widget.dart    ← 선택지 버튼 목록 위젯
    │
    ├── test/
    │   ├── parser_test.dart            ← Lexer + Parser 단위 테스트
    │   └── executor_test.dart          ← GameExecutor 실행 테스트
    │
    └── example/                        ← 독립 실행 예제 앱
        ├── pubspec.yaml                ← path: ../ 로 패키지 참조
        ├── lib/
        │   ├── main.dart               ← 진입점, 세로 고정 orientation
        │   ├── home_screen.dart        ← 씬 목록 홈 화면
        │   ├── scene_config.dart       ← SceneConfig 클래스 + kScenes 목록
        │   ├── scene_loader.dart       ← 씬 비동기 로더 → GameScreen
        │   └── screens/
        │       └── game_screen.dart    ← 이벤트 수신 + 위젯 렌더링
        └── assets/
            ├── scripts/
            │   ├── scene_classroom.rpy ← 샘플 씬 1: 교실의 유나
            │   ├── scene_cafe.rpy      ← 샘플 씬 2: 카페의 민호
            │   └── scene_park.rpy      ← 샘플 씬 3: 공원의 소라
            └── images/
                ├── bg_classroom.png
                ├── bg_cafe.png
                ├── bg_park.png
                ├── yuna_normal.png  yuna_happy.png  yuna_sad.png
                ├── minho_normal.png minho_happy.png minho_nervous.png
                └── sora_normal.png  sora_happy.png  sora_sad.png
```

---

## 예제 앱 빌드 & 실행

### 사전 요구사항

- Flutter SDK 3.10 이상 ([flutter.dev](https://flutter.dev/docs/get-started/install))
- Dart SDK 3.0 이상 (Flutter에 포함)
- Android Studio / Xcode (기기 빌드 시)

버전 확인:

```bash
flutter --version
flutter doctor
```

### 저장소 클론

```bash
git clone https://github.com/eic1223/renpy-flutter.git
cd renpy-flutter/flutter_app/example
```

### 의존성 설치

```bash
flutter pub get
```

### 실행

```bash
# 연결된 기기 또는 에뮬레이터로 실행
flutter run

# 특정 기기 지정
flutter run -d android
flutter run -d ios
flutter run -d chrome        # 웹 (일부 기능 제한)
```

### 빌드 (배포용)

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (macOS 필요)
flutter build ios --release
```

빌드 결과물 경로:

```
example/build/app/outputs/flutter-apk/app-release.apk   ← Android APK
example/build/app/outputs/bundle/release/app-release.aab ← App Bundle
example/build/ios/iphoneos/Runner.app                     ← iOS
```

---

## 샘플 씬 목록

앱을 실행하면 홈 화면에서 씬을 선택할 수 있습니다.

| 씬 | 파일 | 캐릭터 | 표정 | 대사 |
|----|------|--------|------|------|
| **교실의 유나** | `scene_classroom.rpy` | 유나 (`yuna`) | normal / happy / sad | 10줄 |
| **카페의 민호** | `scene_cafe.rpy` | 민호 (`minho`) | normal / happy / nervous | 10줄 |
| **공원의 소라** | `scene_park.rpy` | 소라 (`sora`) | normal / happy / sad | 10줄 |

각 씬은 `label <name>:` 으로 시작해 `return` 으로 종료됩니다.
씬을 종료하면 자동으로 홈 화면으로 돌아옵니다.

### 씬 추가 방법

1. `.rpy` 파일 작성 후 `example/assets/scripts/` 에 저장
2. 이미지 파일을 `example/assets/images/` 에 저장
3. `scene_config.dart` 의 `kScenes` 배열에 항목 추가

```dart
// scene_config.dart
const kScenes = [
  // 기존 씬들...
  SceneConfig(
    title: '새 씬 제목',
    description: '씬 설명',
    startLabel: 'my_scene',           // label my_scene: 과 일치
    scripts: ['assets/scripts/my_scene.rpy'],
    characters: [
      Character(id: 'hero', name: '주인공', color: Color(0xFFFFD700)),
    ],
    accentColor: Color(0xFFFFD700),   // 홈 화면 카드 색상
  ),
];
```

---

## 패키지 설치

### git 의존성 (권장)

```yaml
# pubspec.yaml
dependencies:
  renpy_flutter:
    git:
      url: https://github.com/eic1223/renpy-flutter
      path: flutter_app
```

### 로컬 경로

```yaml
dependencies:
  renpy_flutter:
    path: ../renpy-flutter/flutter_app
```

의존성 설치:

```bash
flutter pub get
```

---

## 패키지 사용법

모든 공개 API는 단일 import로 사용합니다:

```dart
import 'package:renpy_flutter/renpy_flutter.dart';
```

### 최소 구현 예시

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:renpy_flutter/renpy_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 세로 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(home: _GameLoader());
}

class _GameLoader extends StatefulWidget {
  const _GameLoader();
  @override
  State<_GameLoader> createState() => _GameLoaderState();
}

class _GameLoaderState extends State<_GameLoader> {
  GameExecutor? _executor;
  final _characters = CharacterRegistry();
  final _imageCache = ImageCache();

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    // 1. 캐릭터 등록
    _characters.register(const Character(
      id: 'e',
      name: 'Eileen',
      color: Color(0xFFC8A0FF),
    ));

    // 2. 스크립트 로드
    final manager = ScriptManager();
    await manager.loadAssets(['assets/scripts/script.rpy']);

    // 3. 실행기 생성
    setState(() {
      _executor = GameExecutor(
        labels: manager.labels,
        initialState: GameState.initial('start'),  // label start: 진입
      );
    });
  }

  @override
  void dispose() {
    _executor?.dispose();  // 스트림 정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_executor == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // 4. 9:16 화면 비율로 렌더링
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: _GameView(executor: _executor!, characters: _characters, imageCache: _imageCache),
          ),
        ),
      ),
    );
  }
}
```

### GameExecutor 이벤트 수신

`GameExecutor.events` 는 `Stream<GameEvent>` 입니다.
게임 상태 변화를 이벤트로 구독해 UI를 직접 제어할 수 있습니다.

```dart
executor.events.listen((event) {
  switch (event) {
    case ShowDialogueEvent():
      // event.characterId — 캐릭터 ID (null이면 나레이션)
      // event.text        — 대사 텍스트
      showDialogue(event.characterId, event.text);

    case ShowMenuEvent():
      // event.choices — List<MenuChoice>
      // MenuChoice.label, MenuChoice.condition, MenuChoice.block
      showChoices(event.choices);

    case ShowSceneEvent():
      // event.imageName — 배경 이미지 이름 (null이면 클리어)
      // event.with_     — 트랜지션 이름
      changeBackground(event.imageName, event.with_);

    case ShowImageEvent():
      // event.imageName — "eileen happy" 형식
      // event.at        — 위치 ("left", "center", "right")
      // event.with_     — 트랜지션 이름
      showSprite(event.imageName, event.at);

    case HideImageEvent():
      // event.imageName — 숨길 이미지 태그
      hideSprite(event.imageName);

    case PlayAudioEvent():
      // event.channel   — "music", "sound", "voice"
      // event.filename  — 파일 경로
      // event.loop      — 반복 여부
      // event.fadeIn    — 페이드인 시간 (초)
      playAudio(event.channel, event.filename, loop: event.loop);

    case StopAudioEvent():
      // event.channel   — 채널
      // event.fadeOut   — 페이드아웃 시간 (초)
      stopAudio(event.channel, fadeOut: event.fadeOut);

    case PauseEvent():
      // event.duration  — null이면 클릭 대기, 숫자면 자동 진행
      if (event.duration != null) autoAdvance(event.duration!);

    case GameEndedEvent():
      onGameEnd();
  }
});
```

### 사용자 입력 전달

```dart
// 대화 진행 (탭/클릭 시 호출)
executor.advance();

// 선택지 선택 (index: 0-based)
executor.selectChoice(0);
```

### 이미지 이름 → 파일 경로 규칙

```
.rpy 표현식            자동 변환 경로
────────────────────   ─────────────────────────────────
scene bg_room          assets/images/bg_room.png
show eileen happy      assets/images/eileen_happy.png
show yuna sad          assets/images/yuna_sad.png
```

공백은 `_`로, 대소문자는 소문자로 변환됩니다.
직접 경로를 지정하려면 `ImageCache.register()`를 사용합니다:

```dart
final imageCache = ImageCache(basePath: 'assets/images');
imageCache.register('bg forest', 'assets/images/bg/forest_day.jpg');
imageCache.register('eileen happy', 'assets/images/characters/eileen/happy.png');
```

### 내장 위젯 사용

패키지가 제공하는 위젯을 직접 조합할 수 있습니다:

```dart
// 배경 + 스프라이트 레이어
GameLayerWidget(
  layerState: _layers,   // LayerState (배경/스프라이트 상태)
  imageCache: _imageCache,
  overlay: myOverlayWidget,  // 대화창이나 메뉴를 올릴 위젯
)

// 타이핑 대화창
DialogueBox(
  character: character,   // Character 객체
  text: '대사 텍스트',
  onTap: () => executor.advance(),
)

// 선택지 메뉴
MenuWidget(
  choices: choices,       // List<MenuChoice>
  onSelect: (index) => executor.selectChoice(index),
)
```

---

## 아키텍처

```
.rpy 스크립트 파일
       │
  ┌────▼────┐
  │  Lexer  │  줄 단위 토큰화, 들여쓰기(INDENT/DEDENT) 추적
  └────┬────┘
       │  Token Stream
  ┌────▼──────┐
  │  Parser   │  토큰 → AST 노드 트리
  └────┬──────┘
       │  List<AstNode>
  ┌────▼──────────┐
  │ ScriptManager │  여러 파일 로드 → label 맵으로 병합
  └────┬──────────┘
       │  Map<String, LabelNode>
  ┌────▼──────────┐
  │ GameExecutor  │  노드 순서대로 실행, Stream<GameEvent> 방출
  └────┬──────────┘
       │  GameEvent
  ┌────┴──────────────────────────────────┐
  │                                       │
ShowDialogue  ShowScene/Image/Hide   ShowMenu
     │               │                   │
DialogueBox   GameLayerWidget        MenuWidget
```

### 핵심 클래스

| 클래스 | 파일 | 역할 |
|--------|------|------|
| `RenpyParser` | `parser/parser.dart` | `.rpy` 소스 → AST 노드 리스트 |
| `ScriptManager` | `executor/script_manager.dart` | 에셋 로드, 다중 파일 병합, label 맵 제공 |
| `GameExecutor` | `executor/game_executor.dart` | AST 실행, 이벤트 스트림 방출, 입력 수신 |
| `GameState` | `models/game_state.dart` | label·index·변수·스프라이트 상태 스냅샷, JSON 직렬화 |
| `Character` | `models/character.dart` | 캐릭터 ID·이름·색상 |
| `CharacterRegistry` | `models/game_state.dart` | ID → `Character` 매핑 |
| `ImageCache` | `display/image_cache.dart` | 이미지 이름 → 에셋 경로 변환 |
| `GameLayerWidget` | `display/game_layer.dart` | 배경 + 스프라이트 레이어 스택 위젯 |
| `DialogueBox` | `ui/dialogue_box.dart` | 타이핑 애니메이션 대화창 |
| `MenuWidget` | `ui/menu_widget.dart` | 선택지 버튼 목록 |

### AST 노드 종류

| 노드 | `.rpy` 문법 |
|------|------------|
| `LabelNode` | `label name:` |
| `SayNode` | `"나레이션"` / `e "대사"` |
| `ShowNode` | `show image [at pos] [with trans]` |
| `SceneNode` | `scene image [with trans]` |
| `HideNode` | `hide image [with trans]` |
| `JumpNode` | `jump label` |
| `CallNode` | `call label` |
| `ReturnNode` | `return` |
| `MenuNode` | `menu:` + `MenuChoice` 목록 |
| `IfNode` | `if/elif/else:` + `IfBranch` 목록 |
| `PythonNode` | `$ 표현식` |
| `PlayNode` | `play channel file [loop] [fadein N]` |
| `StopNode` | `stop channel [fadeout N]` |
| `PauseNode` | `pause [N]` |

---

## .rpy 문법 레퍼런스

### 대사

```renpy
"나레이션 텍스트."          # 화자 없음 (나레이션)
e "캐릭터 대사."            # 화자 e
```

텍스트 태그:

```renpy
e "이건 {b}굵게{/b}, 이건 {i}기울임{/i}."
e "{color=#ff0000}빨간 글자{/color}"
```

### 이미지 제어

```renpy
scene bg_room                    # 배경 전환 (스프라이트 전체 초기화)
scene bg_room with dissolve      # 트랜지션 포함

show eileen happy                # 스프라이트 표시
show eileen happy at left        # 위치 지정 (left / center / right)
show eileen happy with dissolve  # 트랜지션 포함

hide eileen                      # 스프라이트 숨김
hide eileen with dissolve
```

### 트랜지션

| 이름 | 효과 |
|------|------|
| `dissolve` | 크로스페이드 |
| `fade` | 검정 페이드 아웃 → 인 |
| `blinds` | 블라인드 슬랫 효과 |
| `pixellate` | 픽셀화 전환 |

### 흐름 제어

```renpy
jump label_name     # 레이블로 이동 (돌아오지 않음)
call label_name     # 서브루틴 호출 (return으로 복귀)
return              # call 지점으로 복귀, 없으면 게임 종료
```

### 선택지

```renpy
menu:
    "선택지 A":
        jump route_a
    "선택지 B" if score >= 5:   # 조건부 선택지
        jump route_b
    "선택지 C":
        e "C를 골랐네요."
```

### 조건문

```renpy
if score >= 10:
    e "최고예요!"
elif score >= 5:
    e "괜찮네요."
else:
    e "아쉽네요."
```

### 변수

```renpy
$ score = 0
$ score += 10
$ player_name = "홍길동"
$ is_good = True
```

변수는 `if` 조건 및 `menu` 조건에서 참조됩니다.

### 오디오

```renpy
play music "bgm.ogg" loop
play music "bgm.ogg" loop fadein 1.0
stop music
stop music fadeout 2.0
play sound "click.wav"
```

채널: `music`, `sound`, `voice`

### 일시정지

```renpy
pause          # 클릭할 때까지 대기
pause 2.0      # 2초 후 자동 진행
```

---

## 오디오 연동

패키지는 오디오 재생 코드를 포함하지 않습니다.
`GameExecutor` 이벤트 스트림에서 `PlayAudioEvent` / `StopAudioEvent` 를 수신해 직접 연결하세요.

예시 (`just_audio` 패키지 사용):

```dart
import 'package:just_audio/just_audio.dart';
import 'package:renpy_flutter/renpy_flutter.dart';

final _bgmPlayer = AudioPlayer();

executor.events.listen((event) {
  switch (event) {
    case PlayAudioEvent():
      if (event.channel == 'music') {
        _bgmPlayer.setAsset(event.filename).then((_) => _bgmPlayer.play());
      }
    case StopAudioEvent():
      if (event.channel == 'music') _bgmPlayer.stop();
    default:
      break;
  }
});
```

---

## 저장 / 불러오기

`GameState` 는 JSON 직렬화를 지원합니다.

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:renpy_flutter/renpy_flutter.dart';

// 저장
Future<void> saveGame(GameExecutor executor, String slot) async {
  final prefs = await SharedPreferences.getInstance();
  final json = jsonEncode(executor.state.toJson());
  await prefs.setString('save_$slot', json);
}

// 불러오기
Future<GameExecutor?> loadGame(
    Map<String, LabelNode> labels, String slot) async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString('save_$slot');
  if (json == null) return null;

  final state = GameState.fromJson(jsonDecode(json));
  return GameExecutor(labels: labels, initialState: state);
}
```

저장되는 정보: 현재 label, 실행 인덱스, 콜 스택, 변수 맵, 배경·스프라이트 상태

---

## 테스트

패키지 단위 테스트 실행:

```bash
cd flutter_app
flutter test
```

예제 앱 테스트 실행:

```bash
cd flutter_app/example
flutter test
```

테스트 파일:

```
flutter_app/test/
├── parser_test.dart    # Lexer 토큰화, Parser AST 생성 검증
└── executor_test.dart  # GameExecutor 이벤트 순서 및 흐름 제어 검증
```

---

## 라이선스

MIT
