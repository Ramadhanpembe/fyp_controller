import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          color: Colors.brown,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.grey,
                child: const Center(
                  child: Text('Stacked Container : Parent'),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.red,
                    padding: const EdgeInsets.all(12),
                    child: const Text('This is Logo : Left Side'),
                  ),
                  Container(
                    color: Colors.blue,
                    padding: const EdgeInsets.all(12),
                    child: const Text('This is Icon : Right Side'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
