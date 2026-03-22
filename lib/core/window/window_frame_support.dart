import 'dart:io';

import 'package:flutter/foundation.dart';

bool get supportsCustomWindowFrame {
  if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
    return false;
  }

  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}
