import 'package:flutter/material.dart';

class PasswordFieldSignUp extends StatelessWidget {
  final TextEditingController controller;

  const PasswordFieldSignUp({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'كلمة المرور',
        prefixIcon: Icon(Icons.lock_outline),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال كلمة المرور';
        }
        if (value.length < 6) {
          return 'كلمة المرور يجب أن تكون 6 أحرف أو أكثر';
        }
        return null;
      },
    );
  }
}
