import 'package:flutter/services.dart';

class PinpadKeys {
  const PinpadKeys._();

  static bool isEnter(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.accept;
  }

  static bool isCancel(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.cancel ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack;
  }

  static bool isClear(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.clear;
  }
}
