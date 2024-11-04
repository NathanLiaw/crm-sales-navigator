import 'package:flutter/material.dart';

class CachedPageManager {
  static final Map<String, Widget> _cachedPages = {};

  static Widget getCachedPage(String route, Widget Function() builder) {
    return _cachedPages.putIfAbsent(route, builder);
  }

  static void clearCache() {
    _cachedPages.clear();
  }

  static void removePage(String route) {
    _cachedPages.remove(route);
  }

  static bool hasPage(String route) {
    return _cachedPages.containsKey(route);
  }
}
