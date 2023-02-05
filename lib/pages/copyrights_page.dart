import 'package:flutter/material.dart';

double containerWidth = 0;

class CopyrightsPage extends StatelessWidget {
  const CopyrightsPage({super.key, required this.copyrights});
  final String? copyrights;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (MediaQuery.of(context).size.width >= 1200) {
          containerWidth = 1200;
        }
        return Scaffold(
          body: Column(
            children: [
              Container(
                color: Colors.grey,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: const Text(
                  'TomTom Maps API - Copyrights',
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: containerWidth,
                    margin: const EdgeInsets.only(top: 24),
                    child: Text('$copyrights'),
                  ),
                ),
              ),
              Container(
                color: Colors.grey,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: const Text(
                  'Footer',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
