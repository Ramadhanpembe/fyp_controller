import 'package:flutter/material.dart';

class AutoreleaseButtonNotifier extends ValueNotifier<ReleaseButtonState> {
  AutoreleaseButtonNotifier() : super(_initialValue);

  static const _initialValue = ReleaseButtonState.manualRelease;
}

enum ReleaseButtonState {
  autoRelease,
  manualRelease,
}
