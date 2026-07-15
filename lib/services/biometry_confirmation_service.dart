import 'package:flutter/foundation.dart';

enum BiometryConfirmationType { face, fingerprint }

class RemoteBiometryConfirmationArgs {
  const RemoteBiometryConfirmationArgs();
}

class BiometryConfirmationService {
  BiometryConfirmationService._();

  static final BiometryConfirmationService instance =
      BiometryConfirmationService._();

  final ValueNotifier<BiometryConfirmationType?> confirmation =
      ValueNotifier<BiometryConfirmationType?>(null);

  void confirm(BiometryConfirmationType type) {
    confirmation.value = null;
    confirmation.value = type;
  }

  void clear() => confirmation.value = null;
}
