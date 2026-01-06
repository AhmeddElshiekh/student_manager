import 'package:flutter/material.dart';

class SignUpNavigation extends StatelessWidget {
  final VoidCallback onPressed;

  const SignUpNavigation({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: const Text('ليس لديك حساب؟ إنشاء حساب جديد'),
    );
  }
}
