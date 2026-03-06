/// Ren'Py AST node definitions.
/// Each node corresponds to a statement in .rpy script files.
library;

// ─── Base ────────────────────────────────────────────────────────────────────

abstract class AstNode {
  final int line;
  const AstNode({required this.line});
}

// ─── Label ───────────────────────────────────────────────────────────────────

/// label <name>:
///     <block>
class LabelNode extends AstNode {
  final String name;
  final List<AstNode> block;
  const LabelNode({required super.line, required this.name, required this.block});
}

// ─── Say ─────────────────────────────────────────────────────────────────────

/// [who] "what"
/// e "Hello!"  →  who='e', what='Hello!'
class SayNode extends AstNode {
  final String? who;   // character variable name, null = narration
  final String what;
  const SayNode({required super.line, this.who, required this.what});
}

// ─── Show / Scene / Hide ──────────────────────────────────────────────────────

/// show <image_name> [at <transform>] [with <transition>]
class ShowNode extends AstNode {
  final String imageName;   // e.g. "eileen happy"
  final String? at;         // transform name
  final String? with_;      // transition name
  const ShowNode({required super.line, required this.imageName, this.at, this.with_});
}

/// scene [<image_name>] [with <transition>]
class SceneNode extends AstNode {
  final String? imageName;
  final String? with_;
  const SceneNode({required super.line, this.imageName, this.with_});
}

/// hide <image_name> [with <transition>]
class HideNode extends AstNode {
  final String imageName;
  final String? with_;
  const HideNode({required super.line, required this.imageName, this.with_});
}

// ─── Jump / Call / Return ─────────────────────────────────────────────────────

class JumpNode extends AstNode {
  final String target;
  const JumpNode({required super.line, required this.target});
}

class CallNode extends AstNode {
  final String target;
  const CallNode({required super.line, required this.target});
}

class ReturnNode extends AstNode {
  const ReturnNode({required super.line});
}

// ─── Menu ────────────────────────────────────────────────────────────────────

class MenuChoice {
  final String label;
  final List<AstNode> block;
  final String? condition; // if condition (optional)
  const MenuChoice({required this.label, required this.block, this.condition});
}

class MenuNode extends AstNode {
  final List<MenuChoice> choices;
  const MenuNode({required super.line, required this.choices});
}

// ─── Python ──────────────────────────────────────────────────────────────────

/// $ <expression>  (single-line Python)
class PythonNode extends AstNode {
  final String code;
  const PythonNode({required super.line, required this.code});
}

// ─── If / Elif / Else ─────────────────────────────────────────────────────────

class IfBranch {
  final String? condition; // null = else
  final List<AstNode> block;
  const IfBranch({this.condition, required this.block});
}

class IfNode extends AstNode {
  final List<IfBranch> branches; // if, elif..., else
  const IfNode({required super.line, required this.branches});
}

// ─── Play / Stop ─────────────────────────────────────────────────────────────

class PlayNode extends AstNode {
  final String channel; // music, sound, voice
  final String filename;
  final bool loop;
  final double? fadeIn;
  const PlayNode({
    required super.line,
    required this.channel,
    required this.filename,
    this.loop = false,
    this.fadeIn,
  });
}

class StopNode extends AstNode {
  final String channel;
  final double? fadeOut;
  const StopNode({required super.line, required this.channel, this.fadeOut});
}

// ─── Pause ───────────────────────────────────────────────────────────────────

class PauseNode extends AstNode {
  final double? duration; // null = wait for click
  const PauseNode({required super.line, this.duration});
}

// ─── With (standalone transition) ────────────────────────────────────────────

class WithNode extends AstNode {
  final String transition;
  const WithNode({required super.line, required this.transition});
}
