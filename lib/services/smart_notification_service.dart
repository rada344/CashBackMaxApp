class SmartNotificationService {
  String? _lastStoreName;

  bool shouldNotifyForStore(String currentStoreName) {
    if (_lastStoreName == currentStoreName) return false;
    _lastStoreName = currentStoreName;
    return true;
  }
}

