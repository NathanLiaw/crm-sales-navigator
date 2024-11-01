import 'package:flutter/foundation.dart';

class OrderStatusProvider extends ChangeNotifier {
  bool _shouldRefresh = false;

  bool get shouldRefresh => _shouldRefresh;

  void triggerRefresh() {
    _shouldRefresh = true;
    notifyListeners();
  }

  void resetRefresh() {
    _shouldRefresh = false;
  }
}
