import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class ControllerLogo extends StatelessWidget {
  const ControllerLogo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Marquee(
        text: 'PASSENGER MANAGEMENT SYSTEM',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 30.0,
          letterSpacing: 1.1,
        ),
        blankSpace: 40.0,
        velocity: 40.0,
        startPadding: 10.0,
      ),
    );
  }
}
