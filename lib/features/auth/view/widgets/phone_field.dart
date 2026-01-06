import 'package:flutter/material.dart';

class PhoneField extends StatelessWidget {
  final TextEditingController controller;

  const PhoneField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        labelText: 'رقم الهاتف',
        prefixIcon: Icon(Icons.phone_outlined),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال رقم الهاتف';
        }
        if (value.length != 11 || !value.startsWith('01')) {
          return 'أدخل رقم هاتف مصري صحيح (11 رقم يبدأ بـ 01)';
        }
        return null;
      },
    );
  }
}
