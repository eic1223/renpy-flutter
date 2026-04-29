/// Simple line-based lexer for .rpy scripts.
library;

enum TokenType {
  label,
  say,
  scene,
  show,
  hide,
  jump,
  call,
  returnKw,
  menu,
  python,    // $ ...
  ifKw,
  elifKw,
  elseKw,
  play,
  stop,
  pause,
  with_,
  identifier,
  string,
  colon,
  indent,
  dedent,
  newline,
  eof,
}

class Token {
  final TokenType type;
  final String value;
  final int line;
  const Token(this.type, this.value, this.line);

  @override
  String toString() => 'Token($type, "$value", line:$line)';
}

class Lexer {
  final String source;
  final List<Token> _tokens = [];

  Lexer(this.source);

  List<Token> tokenize() {
    final lines = source.split('\n');
    final indentStack = <int>[0];

    for (var i = 0; i < lines.length; i++) {
      final lineNo = i + 1;
      final raw = lines[i];

      // Strip comment
      final commentIdx = _findComment(raw);
      final line = commentIdx >= 0 ? raw.substring(0, commentIdx) : raw;

      if (line.trim().isEmpty) continue;

      // Measure indent
      final indent = _countIndent(line);
      final content = line.trimLeft();

      // Emit INDENT / DEDENT
      final currentIndent = indentStack.last;
      if (indent > currentIndent) {
        indentStack.add(indent);
        _tokens.add(Token(TokenType.indent, '', lineNo));
      } else if (indent < currentIndent) {
        while (indentStack.last > indent) {
          indentStack.removeLast();
          _tokens.add(Token(TokenType.dedent, '', lineNo));
        }
      }

      _tokenizeLine(content, lineNo);
    }

    // Emit remaining DEDENTs
    while (indentStack.length > 1) {
      indentStack.removeLast();
      _tokens.add(Token(TokenType.dedent, '', -1));
    }

    _tokens.add(Token(TokenType.eof, '', -1));
    return _tokens;
  }

  int _findComment(String line) {
    bool inStr = false;
    String strChar = '';
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (inStr) {
        if (c == strChar) inStr = false;
      } else {
        if (c == '"' || c == "'") { inStr = true; strChar = c; }
        if (c == '#') return i;
      }
    }
    return -1;
  }

  int _countIndent(String line) {
    var count = 0;
    for (final c in line.runes) {
      if (c == 0x20) { // space
        count++;
      } else if (c == 0x09) { // tab
        count += 4;
      } else {
        break;
      }
    }
    return count;
  }

  void _tokenizeLine(String content, int lineNo) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    // $ python line
    if (trimmed.startsWith('\$')) {
      _tokens.add(Token(TokenType.python, trimmed.substring(1).trim(), lineNo));
      return;
    }

    // keyword: colon suffix lines
    final colonMatch = RegExp(r'^(\w+)\s*(.*?)\s*:\s*$').firstMatch(trimmed);
    if (colonMatch != null) {
      final kw = colonMatch.group(1)!;
      final rest = colonMatch.group(2)!;
      switch (kw) {
        case 'label':
          _tokens.add(Token(TokenType.label, rest.trim(), lineNo));
          _tokens.add(Token(TokenType.colon, ':', lineNo));
          return;
        case 'menu':
          _tokens.add(Token(TokenType.menu, '', lineNo));
          _tokens.add(Token(TokenType.colon, ':', lineNo));
          return;
        case 'if':
          _tokens.add(Token(TokenType.ifKw, rest.trim(), lineNo));
          _tokens.add(Token(TokenType.colon, ':', lineNo));
          return;
        case 'elif':
          _tokens.add(Token(TokenType.elifKw, rest.trim(), lineNo));
          _tokens.add(Token(TokenType.colon, ':', lineNo));
          return;
        case 'else':
          _tokens.add(Token(TokenType.elseKw, '', lineNo));
          _tokens.add(Token(TokenType.colon, ':', lineNo));
          return;
        default:
          // e.g.  "선택지 A":  (menu choice)
          break;
      }
    }

    // menu choice line: "text":
    if (trimmed.startsWith('"') || trimmed.startsWith("'")) {
      final strMatch = RegExp(r'^(["\'])(.*?)\1\s*:\s*$').firstMatch(trimmed);
      if (strMatch != null) {
        _tokens.add(Token(TokenType.string, strMatch.group(2)!, lineNo));
        _tokens.add(Token(TokenType.colon, ':', lineNo));
        return;
      }
    }

    // keyword lines (no colon)
    final words = _splitRespectingStrings(trimmed);
    if (words.isEmpty) return;

    switch (words[0]) {
      case 'scene':
        _tokens.add(Token(TokenType.scene, trimmed.substring(5).trim(), lineNo));
      case 'show':
        _tokens.add(Token(TokenType.show, trimmed.substring(4).trim(), lineNo));
      case 'hide':
        _tokens.add(Token(TokenType.hide, trimmed.substring(4).trim(), lineNo));
      case 'jump':
        _tokens.add(Token(TokenType.jump, words.length > 1 ? words[1] : '', lineNo));
      case 'call':
        _tokens.add(Token(TokenType.call, words.length > 1 ? words[1] : '', lineNo));
      case 'return':
        _tokens.add(Token(TokenType.returnKw, '', lineNo));
      case 'play':
        _tokens.add(Token(TokenType.play, trimmed.substring(4).trim(), lineNo));
      case 'stop':
        _tokens.add(Token(TokenType.stop, trimmed.substring(4).trim(), lineNo));
      case 'pause':
        _tokens.add(Token(TokenType.pause, words.length > 1 ? words[1] : '', lineNo));
      case 'with':
        _tokens.add(Token(TokenType.with_, words.length > 1 ? words[1] : '', lineNo));
      default:
        // say: [who] "text"  or  "text"
        _parseSay(trimmed, lineNo);
    }
  }

  void _parseSay(String content, int lineNo) {
    // "text"  or  who "text"
    final strPattern = RegExp(r'^(\w+\s+)?(["\'])(.*?)\2$', dotAll: true);
    final m = strPattern.firstMatch(content);
    if (m != null) {
      final who = m.group(1)?.trim();
      final what = m.group(3)!;
      _tokens.add(Token(TokenType.say, '${who ?? ''}\x00$what', lineNo));
    } else {
      // fallback: treat as identifier
      _tokens.add(Token(TokenType.identifier, content, lineNo));
    }
  }

  List<String> _splitRespectingStrings(String s) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inStr = false;
    String strChar = '';
    for (final c in s.split('')) {
      if (inStr) {
        buf.write(c);
        if (c == strChar) inStr = false;
      } else if (c == '"' || c == "'") {
        inStr = true;
        strChar = c;
        buf.write(c);
      } else if (c == ' ' || c == '\t') {
        if (buf.isNotEmpty) { result.add(buf.toString()); buf.clear(); }
      } else {
        buf.write(c);
      }
    }
    if (buf.isNotEmpty) result.add(buf.toString());
    return result;
  }
}
