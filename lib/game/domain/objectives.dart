import 'blockers.dart';
import 'content.dart';
import 'piece.dart';
import 'position.dart';

enum GoalKind {
  targetScore,
  collectPieces,
  clearFrosting,
  breakCrates,
  dropRecipeBaskets,
  spreadCream,
  lightOvens,
}

class GoalState {
  GoalState({required this.kind, required this.target, this.pieceKind})
    : assert(target > 0);

  factory GoalState.fromMechanic(MechanicDefinition mechanic) {
    final kind = switch (mechanic.id) {
      'target_score' => GoalKind.targetScore,
      'collect_pieces' => GoalKind.collectPieces,
      'clear_frosting' => GoalKind.clearFrosting,
      'break_crates' => GoalKind.breakCrates,
      'drop_recipe_baskets' => GoalKind.dropRecipeBaskets,
      'spread_cream' => GoalKind.spreadCream,
      'light_ovens' => GoalKind.lightOvens,
      _ => throw ContentException('Unknown goal mechanic: ${mechanic.id}'),
    };
    final targetValue =
        mechanic.parameters['target'] ??
        mechanic.parameters['score'] ??
        mechanic.parameters['count'];
    if (targetValue is! int || targetValue <= 0) {
      throw ContentException('Goal ${mechanic.id} needs a positive target.');
    }
    final pieceId = mechanic.parameters['pieceId'];
    if (kind == GoalKind.collectPieces && pieceId is! String) {
      throw ContentException('Collect goal needs a pieceId.');
    }
    return GoalState(
      kind: kind,
      target: targetValue,
      pieceKind: pieceId is String ? PieceKind(pieceId) : null,
    );
  }

  final GoalKind kind;
  final int target;
  final PieceKind? pieceKind;
  int progress = 0;

  bool get isComplete => progress >= target;

  void add(int amount) {
    if (amount > 0) progress = (progress + amount).clamp(0, target);
  }
}

class TurnProgress {
  TurnProgress({
    this.score = 0,
    Map<PieceKind, int> collected = const {},
    Map<BlockerKind, int> removedBlockers = const {},
    this.droppedBaskets = 0,
    this.spreadCream = 0,
    this.litOvens = 0,
  }) : collected = Map.unmodifiable(collected),
       removedBlockers = Map.unmodifiable(removedBlockers);

  final int score;
  final Map<PieceKind, int> collected;
  final Map<BlockerKind, int> removedBlockers;
  final int droppedBaskets;
  final int spreadCream;
  final int litOvens;
}

class GoalTracker {
  GoalTracker(List<GoalState> goals) : goals = List.unmodifiable(goals);

  final List<GoalState> goals;

  bool get isComplete => goals.every((goal) => goal.isComplete);

  void apply(TurnProgress progress) {
    for (final goal in goals) {
      final amount = switch (goal.kind) {
        GoalKind.targetScore => progress.score,
        GoalKind.collectPieces => progress.collected[goal.pieceKind] ?? 0,
        GoalKind.clearFrosting =>
          progress.removedBlockers[BlockerKind.sugarFrosting] ?? 0,
        GoalKind.breakCrates =>
          progress.removedBlockers[BlockerKind.peanutCrate] ?? 0,
        GoalKind.dropRecipeBaskets => progress.droppedBaskets,
        GoalKind.spreadCream => progress.spreadCream,
        GoalKind.lightOvens => progress.litOvens,
      };
      goal.add(amount);
    }
  }
}

class BoardObjectives {
  BoardObjectives({
    Set<Position> recipeBaskets = const {},
    Set<Position> cream = const {},
    Set<Position> ovens = const {},
  }) : recipeBaskets = {...recipeBaskets},
       cream = {...cream},
       ovens = {...ovens};

  final Set<Position> recipeBaskets;
  final Set<Position> cream;
  final Set<Position> ovens;
  final Set<Position> litOvens = {};

  ({int creamSpread, int ovensLit}) resolveClear(Set<Position> cleared) {
    final hadCream = cleared.any(cream.contains);
    final beforeCream = cream.length;
    if (hadCream) cream.addAll(cleared);

    final beforeOvens = litOvens.length;
    for (final oven in ovens) {
      if (cleared.contains(oven) ||
          cleared.any(oven.isOrthogonallyAdjacentTo)) {
        litOvens.add(oven);
      }
    }
    return (
      creamSpread: cream.length - beforeCream,
      ovensLit: litOvens.length - beforeOvens,
    );
  }

  int settleBaskets({
    required int rows,
    required BlockerGrid blockers,
    Set<Position> clearedCells = const {},
    Set<Position> inaccessibleCells = const {},
  }) {
    var dropped = 0;
    final ordered = recipeBaskets.toList()
      ..sort((a, b) => b.row.compareTo(a.row));
    recipeBaskets.clear();
    for (final basket in ordered) {
      // Baskets are overlays: each cleared supporting cell in their gravity
      // segment lets them descend one row. Intact pieces still support them.
      var fall = 0;
      for (var row = basket.row + 1; row < rows; row++) {
        final below = Position(row, basket.column);
        if (blockers.blocksCell(below) ||
            inaccessibleCells.contains(below) ||
            recipeBaskets.contains(below)) {
          break;
        }
        if (clearedCells.contains(below)) fall++;
      }
      final target = Position(basket.row + fall, basket.column);
      if (target.row == rows - 1) {
        dropped++;
      } else {
        recipeBaskets.add(target);
      }
    }
    return dropped;
  }
}
