/// Ren'Py script parser: converts token stream into AST nodes.
library;

import '../ast/nodes.dart';
import 'lexer.dart';

class ParseError implements Exception {
  final String message;
  final int line;
  ParseError(this.message, this.line);

  @override
  String toString() => 'ParseError at line $line: $message';
}

class RenpyParser {
  final List<Token> _tokens;
  int _pos = 0;

  RenpyParser(this._tokens);

  factory RenpyParser.fromSource(String source) {
    final tokens = Lexer(source).tokenize();
    return RenpyParser(tokens);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Token get _current => _tokens[_pos];

  Token _consume() => _tokens[_pos++];

  bool get _atEnd => _current.type == TokenType.eof;

  void _expect(TokenType type) {
    if (_current.type != type) {
      throw ParseError('Expected $type but got ${_current.type}', _current.line);
    }
    _consume();
  }

  bool _match(TokenType type) {
    if (_current.type == type) { _consume(); return true; }
    return false;
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Parse all top-level statements and label definitions.
  List<AstNode> parseAll() {
    final nodes = <AstNode>[];
    while (!_atEnd) {
      final node = _parseStatement();
      if (node != null) nodes.add(node);
    }
    return nodes;
  }

  // ─── Block ─────────────────────────────────────────────────────────────────

  List<AstNode> _parseBlock() {
    _expect(TokenType.indent);
    final nodes = <AstNode>[];
    while (!_atEnd && _current.type != TokenType.dedent) {
      final node = _parseStatement();
      if (node != null) nodes.add(node);
    }
    _expect(TokenType.dedent);
    return nodes;
  }

  // ─── Statements ────────────────────────────────────────────────────────────

  AstNode? _parseStatement() {
    final tok = _current;

    switch (tok.type) {
      case TokenType.label:
        return _parseLabel();
      case TokenType.say:
        return _parseSay();
      case TokenType.scene:
        return _parseScene();
      case TokenType.show:
        return _parseShow();
      case TokenType.hide:
        return _parseHide();
      case TokenType.jump:
        _consume();
        return JumpNode(line: tok.line, target: tok.value);
      case TokenType.call:
        _consume();
        return CallNode(line: tok.line, target: tok.value);
      case TokenType.returnKw:
        _consume();
        return ReturnNode(line: tok.line);
      case TokenType.menu:
        return _parseMenu();
      case TokenType.python:
        _consume();
        return PythonNode(line: tok.line, code: tok.value);
      case TokenType.ifKw:
        return _parseIf();
      case TokenType.play:
        _consume();
        return _parsePlay(tok);
      case TokenType.stop:
        _consume();
        return _parseStop(tok);
      case TokenType.pause:
        _consume();
        return PauseNode(
          line: tok.line,
          duration: tok.value.isEmpty ? null : double.tryParse(tok.value),
        );
      case TokenType.with_:
        _consume();
        return WithNode(line: tok.line, transition: tok.value);
      case TokenType.indent:
      case TokenType.dedent:
      case TokenType.newline:
        _consume();
        return null;
      case TokenType.colon:
        _consume();
        return null;
      default:
        _consume(); // skip unknown
        return null;
    }
  }

  LabelNode _parseLabel() {
    final tok = _consume(); // label token, value = name
    _expect(TokenType.colon);
    final block = _parseBlock();
    return LabelNode(line: tok.line, name: tok.value, block: block);
  }

  SayNode _parseSay() {
    final tok = _consume();
    // value format: 'who\x00what'
    final parts = tok.value.split('\x00');
    final who = parts[0].isEmpty ? null : parts[0];
    final what = parts.length > 1 ? parts[1] : parts[0];
    return SayNode(line: tok.line, who: who, what: what);
  }

  ShowNode _parseShow() {
    final tok = _consume(); // value = rest after 'show'
    final (imageName, at, with_) = _parseImageArgs(tok.value);
    return ShowNode(line: tok.line, imageName: imageName, at: at, with_: with_);
  }

  SceneNode _parseScene() {
    final tok = _consume();
    if (tok.value.isEmpty) return SceneNode(line: tok.line);
    final (imageName, _, with_) = _parseImageArgs(tok.value);
    return SceneNode(line: tok.line, imageName: imageName, with_: with_);
  }

  HideNode _parseHide() {
    final tok = _consume();
    final (imageName, _, with_) = _parseImageArgs(tok.value);
    return HideNode(line: tok.line, imageName: imageName, with_: with_);
  }

  (String, String?, String?) _parseImageArgs(String rest) {
    // parse:  <image_name> [at <transform>] [with <transition>]
    String? at, with_;
    var name = rest;

    final withMatch = RegExp(r'\s+with\s+(\w+)$').firstMatch(name);
    if (withMatch != null) {
      with_ = withMatch.group(1);
      name = name.substring(0, withMatch.start);
    }

    final atMatch = RegExp(r'\s+at\s+(\w+)$').firstMatch(name);
    if (atMatch != null) {
      at = atMatch.group(1);
      name = name.substring(0, atMatch.start);
    }

    return (name.trim(), at, with_);
  }

  MenuNode _parseMenu() {
    final tok = _consume(); // menu token
    _expect(TokenType.colon);
    _expect(TokenType.indent);

    final choices = <MenuChoice>[];
    while (!_atEnd && _current.type != TokenType.dedent) {
      // Each choice: "label" [if condition]:
      if (_current.type == TokenType.string) {
        final strTok = _consume();
        String? condition;
        if (_current.type == TokenType.ifKw) {
          condition = _consume().value;
        }
        _expect(TokenType.colon);
        final block = _parseBlock();
        choices.add(MenuChoice(label: strTok.value, block: block, condition: condition));
      } else {
        _consume(); // skip unexpected
      }
    }
    _expect(TokenType.dedent);
    return MenuNode(line: tok.line, choices: choices);
  }

  IfNode _parseIf() {
    final tok = _consume(); // ifKw token, value = condition
    _expect(TokenType.colon);
    final ifBlock = _parseBlock();
    final branches = <IfBranch>[IfBranch(condition: tok.value, block: ifBlock)];

    while (_current.type == TokenType.elifKw) {
      final elifTok = _consume();
      _expect(TokenType.colon);
      final elifBlock = _parseBlock();
      branches.add(IfBranch(condition: elifTok.value, block: elifBlock));
    }

    if (_current.type == TokenType.elseKw) {
      _consume();
      _expect(TokenType.colon);
      final elseBlock = _parseBlock();
      branches.add(IfBranch(condition: null, block: elseBlock));
    }

    return IfNode(line: tok.line, branches: branches);
  }

  PlayNode _parsePlay(Token tok) {
    // value: "music bg.ogg loop fadein 1.0"
    final parts = tok.value.split(RegExp(r'\s+'));
    final channel = parts.isNotEmpty ? parts[0] : 'music';
    String filename = '';
    bool loop = false;
    double? fadeIn;

    for (var i = 1; i < parts.length; i++) {
      final p = parts[i];
      if (p == 'loop') {
        loop = true;
      } else if (p == 'fadein' && i + 1 < parts.length) {
        fadeIn = double.tryParse(parts[++i]);
      } else if (p.startsWith('"') || p.endsWith('"')) {
        filename = p.replaceAll('"', '');
      } else if (filename.isEmpty) {
        filename = p;
      }
    }

    return PlayNode(
      line: tok.line,
      channel: channel,
      filename: filename,
      loop: loop,
      fadeIn: fadeIn,
    );
  }

  StopNode _parseStop(Token tok) {
    // value: "music fadeout 1.0"
    final parts = tok.value.split(RegExp(r'\s+'));
    final channel = parts.isNotEmpty ? parts[0] : 'music';
    double? fadeOut;
    for (var i = 1; i < parts.length; i++) {
      if (parts[i] == 'fadeout' && i + 1 < parts.length) {
        fadeOut = double.tryParse(parts[++i]);
      }
    }
    return StopNode(line: tok.line, channel: channel, fadeOut: fadeOut);
  }
}
