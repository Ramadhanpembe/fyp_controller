import 'package:flutter/material.dart';
import 'package:fyp_controller/data/resources.dart';
import 'package:fyp_controller/notifiers/autorelease_button_notifier.dart';

class AutoreleaseButton extends StatelessWidget {
  const AutoreleaseButton({
    super.key,
    required this.onHover,
    required this.isFocused,
  });

  final Function(bool?) onHover;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18.0, bottom: 18.0, right: 8.0),
      child: ValueListenableBuilder<ReleaseButtonState>(
        valueListenable: autoreleaseButtonNotifier,
        builder: (_, val, __) {
          switch (val) {
            case ReleaseButtonState.manualRelease:
              return FilledButton(
                onHover: (value) => onHover(value),
                style: ButtonStyle(
                  backgroundColor: isFocused
                      ? MaterialStateProperty.all(Colors.grey)
                      : MaterialStateProperty.all(Colors.white),
                  elevation: MaterialStateProperty.all(20.0),
                  visualDensity: VisualDensity.comfortable,
                ),
                onPressed: () async {
                  autoreleaseButtonNotifier.value = ReleaseButtonState.autoRelease;
                  // autoNotifyDriver();
                },
                child: Text(
                  'AUTO RELEASE OFF',
                  style: TextStyle(color: isFocused ? Colors.white : Colors.black),
                ),
              );
            case ReleaseButtonState.autoRelease:
              autoReleaseOnNotifier.value = true;
              return FilledButton(
                onHover: (value) => onHover(value),
                style: ButtonStyle(
                  backgroundColor: isFocused
                      ? MaterialStateProperty.all(Colors.grey)
                      : MaterialStateProperty.all(Colors.red),
                  elevation: MaterialStateProperty.all(20.0),
                  visualDensity: VisualDensity.comfortable,
                  // foregroundColor: MaterialStateProperty.all(Colors.black),
                ),
                onPressed: () {
                  autoreleaseButtonNotifier.value = ReleaseButtonState.manualRelease;
                },
                child: Text(
                  'AUTO RELEASE ON',
                  style: TextStyle(color: isFocused ? Colors.white : Colors.white),
                ),
              );
          }
        },
      ),
    );
  }
}
