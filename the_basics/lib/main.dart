import 'package:flutter/material.dart';
import 'package:the_basics/features/encoder/encoder_dashb.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: EncoderDashb()   // change depending page to test
    );
  }
}