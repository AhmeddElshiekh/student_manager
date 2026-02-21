import 'package:flutter/material.dart';
import 'package:nizam/features/auth/view/widgets/password_field_signup.dart';
import 'package:nizam/features/auth/view/widgets/phone_field.dart';
import 'package:nizam/features/auth/view/widgets/signup_button.dart';
import 'package:nizam/features/auth/view/widgets/signup_header.dart';
import '../../../../core/navigation/app_router.dart';
import 'email_field.dart';
import 'name_field.dart';

class SignUpForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback? onSignUp; // MAKE IT NULLABLE

  const SignUpForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.onSignUp, // Now it's a required but nullable VoidCallback
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      constraints: BoxConstraints(maxWidth: isSmallScreen ? double.infinity : 400),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SignUpHeader(),
            const SizedBox(height: 32),
            NameField(controller: nameController),
            const SizedBox(height: 16),
            PhoneField(controller: phoneController),
            const SizedBox(height: 16),
            EmailField(controller: emailController),
            const SizedBox(height: 16),
            PasswordFieldSignUp(controller: passwordController),
            const SizedBox(height: 24),
            SignUpButton(onPressed: onSignUp), // This now correctly passes a nullable value
            const SizedBox(height: 16),
            const _LoginNavigation(),
          ],
        ),
      ),
    );
  }
}
class _LoginNavigation extends StatelessWidget {
  const _LoginNavigation();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => AppRouter.pop(context),
      child: const Text('لديك حساب؟ تسجيل الدخول'),
    );
  }
}
