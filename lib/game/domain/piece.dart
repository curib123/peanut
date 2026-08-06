class PieceKind {
  const PieceKind(this.id) : assert(id != '');

  final String id;

  static const peanut = PieceKind('peanut');
  static const egg = PieceKind('egg');
  static const sugarCrystal = PieceKind('sugar_crystal');
  static const caramelRibbon = PieceKind('caramel_ribbon');
  static const coconutCream = PieceKind('coconut_cream');
  static const cocoaCrumb = PieceKind('cocoa_crumb');

  static const regularValues = [
    peanut,
    egg,
    sugarCrystal,
    caramelRibbon,
    coconutCream,
    cocoaCrumb,
  ];

  @override
  bool operator ==(Object other) => other is PieceKind && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PieceKind($id)';
}

class Piece {
  const Piece(this.kind);

  final PieceKind kind;

  @override
  bool operator ==(Object other) => other is Piece && kind == other.kind;

  @override
  int get hashCode => kind.hashCode;

  @override
  String toString() => 'Piece(${kind.id})';
}
