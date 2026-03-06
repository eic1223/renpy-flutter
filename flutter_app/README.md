# renpy_flutter

Ren'Py 비주얼 노벨 엔진의 Flutter 포트입니다.
`.rpy` 스크립트를 파싱해 Flutter 위젯으로 렌더링합니다.

## 기능

| 구분 | 지원 항목 |
|------|----------|
| **스크립트** | `label`, `jump`, `call`, `return`, `menu`, `if/elif/else`, `$ 변수` |
| **대사** | `say` (화자 / 나레이션), 타이핑 애니메이션, `{b}` `{i}` `{color=}` 태그 |
| **이미지** | `scene`, `show`, `hide`, `with dissolve/fade/blinds` 트랜지션 |
| **선택지** | `menu` — 호버 애니메이션 포함 버튼 목록 |
| **오디오** | `play`/`stop` 이벤트 스트림 제공 (직접 연결 가능) |

---

## 설치

`pubspec.yaml`에 추가하세요.

```yaml
dependencies:
  renpy_flutter:
    git:
      url: https://github.com/eic1223/renpy-flutter
      path: flutter_app
```

또는 로컬 경로로:

```yaml
dependencies:
  renpy_flutter:
    path: ../renpy_flutter
```

---

## 빠른 시작

### 1. 스크립트 파일 작성

`assets/scripts/script.rpy`:

```renpy
label start:
    scene bg_room with dissolve

    "어두운 방에 빛이 들어온다."

    show eileen happy with dissolve

    e "안녕하세요!"

    menu:
        "계속 이야기하기":
            jump route_a
        "끝내기":
            jump ending

label route_a:
    e "좋아요, 계속해요!"
    jump ending

label ending:
    hide eileen with dissolve
    "끝."
    return
```

### 2. `pubspec.yaml`에 에셋 등록

```yaml
flutter:
  assets:
    - assets/scripts/
    - assets/images/
```

### 3. 캐릭터 등록 & 실행

```dart
import 'package:flutter/material.dart';
import 'package:renpy_flutter/renpy_flutter.dart';

void main() => runApp(const MyApp());

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
    // 캐릭터 정의
    _characters.register(const Character(
      id: 'e',
      name: 'Eileen',
      color: Color(0xFFC8A0FF),
    ));

    // 스크립트 로드
    final manager = ScriptManager();
    await manager.loadAssets(['assets/scripts/script.rpy']);

    setState(() {
      _executor = GameExecutor(
        labels: manager.labels,
        initialState: GameState.initial('start'),
      );
    });
  }

  @override
  void dispose() {
    _executor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_executor == null) return const CircularProgressIndicator();
    return GameScreen(
      executor: _executor!,
      characterRegistry: _characters,
      imageCache: _imageCache,
    );
  }
}
```

---

## 아키텍처

```
┌─────────────────────────────────────────────────────┐
│                    .rpy 스크립트                     │
└────────────────────────┬────────────────────────────┘
                         │
                    Lexer (lexer.dart)
                         │
                   RenpyParser (parser.dart)
                         │
                    AST 노드 트리 (nodes.dart)
                         │
                  GameExecutor (game_executor.dart)
                  ┌──────┴──────┐
                  │  이벤트 스트림  │
                  └──────┬──────┘
          ┌──────────────┼──────────────┐
   ShowDialogue   ShowScene/Image   ShowMenu
          │              │               │
    DialogueBox    GameLayerWidget   MenuWidget
```

### 핵심 클래스

| 클래스 | 역할 |
|--------|------|
| `RenpyParser` | `.rpy` 소스 → AST 노드 리스트 |
| `ScriptManager` | 에셋에서 스크립트 로드 + label 맵 관리 |
| `GameExecutor` | AST 노드를 순서대로 실행, 이벤트 스트림 방출 |
| `GameState` | 현재 label·index·변수·스프라이트 상태 스냅샷 |
| `CharacterRegistry` | ID → `Character` 매핑 |
| `ImageCache` | 이미지 이름 → 에셋 경로 변환 |
| `GameLayerWidget` | 배경 + 스프라이트 레이어 스택 위젯 |
| `DialogueBox` | 타이핑 대화창 위젯 |
| `MenuWidget` | 선택지 버튼 목록 위젯 |

---

## 이미지 매핑

이미지 파일 이름 규칙:

```
Ren'Py 표현식        에셋 파일 경로
───────────────────  ─────────────────────────────
scene bg_room        assets/images/bg_room.png
show eileen happy    assets/images/eileen_happy.png
show eileen sad      assets/images/eileen_sad.png
```

직접 경로를 지정하려면 `ImageCache.register()`를 사용하세요:

```dart
final imageCache = ImageCache(basePath: 'assets/images');
imageCache.register('bg room', 'assets/images/backgrounds/room.jpg');
imageCache.register('eileen happy', 'assets/images/chars/eileen/happy.png');
```

---

## 트랜지션

`with` 키워드로 트랜지션을 지정합니다.

| 이름 | 효과 |
|------|------|
| `dissolve` | 크로스페이드 (기본값) |
| `fade` | 검정으로 페이드 아웃 → 인 |
| `blinds` | 블라인드 슬랫 효과 |
| `pixellate` | 축소 + 페이드 효과 |

```renpy
scene bg_forest with fade
show eileen happy with dissolve
hide eileen with dissolve
```

---

## 지원 스크립트 문법

### 대사

```renpy
"나레이션 텍스트."          # 화자 없음
e "캐릭터 대사."            # 화자 e
```

### 이미지 제어

```renpy
scene bg_room               # 배경 변경 (스프라이트 초기화)
scene bg_room with dissolve # 트랜지션 포함
show eileen happy           # 스프라이트 표시
show eileen happy at left   # 위치 지정 (left/center/right)
hide eileen                 # 스프라이트 숨김
```

### 흐름 제어

```renpy
jump label_name             # 레이블로 이동
call label_name             # 서브루틴 호출
return                      # 호출 지점으로 복귀
```

### 선택지

```renpy
menu:
    "선택지 A":
        jump route_a
    "선택지 B":
        jump route_b
```

### 조건문

```renpy
if score >= 10:
    e "잘 했어요!"
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
```

### 오디오 (이벤트 수신 필요)

```renpy
play music bg_music.ogg loop
play music bg_music.ogg loop fadein 1.0
stop music fadeout 0.5
play sound effect.wav
```

### 일시정지

```renpy
pause          # 클릭할 때까지 대기
pause 2.0      # 2초 대기
```

---

## 오디오 연동

`GameExecutor`의 이벤트 스트림을 구독해 오디오를 직접 처리합니다:

```dart
executor.events.listen((event) {
  switch (event) {
    case PlayAudioEvent():
      // event.channel, event.filename, event.loop, event.fadeIn
      myAudioPlayer.play(event.filename, loop: event.loop);
    case StopAudioEvent():
      // event.channel, event.fadeOut
      myAudioPlayer.stop(fadeOut: event.fadeOut);
    default:
      break;
  }
});
```

---

## 저장 / 불러오기

`GameState`는 직렬화를 지원합니다:

```dart
// 저장
final json = executor.state.toJson();
final jsonString = jsonEncode(json);
await prefs.setString('save_slot_1', jsonString);

// 불러오기
final jsonString = prefs.getString('save_slot_1')!;
final state = GameState.fromJson(jsonDecode(jsonString));
final executor = GameExecutor(labels: manager.labels, initialState: state);
```

---

## 테스트

```bash
cd flutter_app
flutter test
```

```
test/
├── parser_test.dart    # Lexer + Parser 단위 테스트
└── executor_test.dart  # GameExecutor 실행 테스트
```

---

## 예제 앱 실행

```bash
cd flutter_app/example
flutter pub get
flutter run
```

---

## 라이선스

MIT
