import 'package:flutter/material.dart';

class FormTextField extends StatelessWidget {
  const FormTextField(
      {super.key,
      required this.hintText,
      this.obscureText = false,
      this.keyboardType = TextInputType.text,
      this.validator,
      this.controller});

  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextEditingController? controller;

  get kHintTextStyle => const TextStyle(
        color: Colors.grey,
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: validator,
      controller: controller,
      obscureText: obscureText,
      enableSuggestions: false,
      autocorrect: false,
      style: const TextStyle(
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        decorationThickness: 0.0,
      ),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: kHintTextStyle,
      ),
    );
  }
}
