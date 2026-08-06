class TurnInputGate {
  bool _isLocked = false;

  bool get isLocked => _isLocked;

  Future<T?> run<T>(Future<T> Function() action) async {
    if (_isLocked) return null;
    _isLocked = true;
    try {
      return await action();
    } finally {
      _isLocked = false;
    }
  }
}
