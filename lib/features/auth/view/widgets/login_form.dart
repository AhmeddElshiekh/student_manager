import 'package:flutter/material.dart';
import 'package:nizam/features/auth/view/widgets/password_field.dart';
import 'package:nizam/features/auth/view/widgets/signup_navigation.dart';
import 'email_field.dart';
import 'forgot_password_button.dart';
import 'login_button.dart';
import 'login_header.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback? onSignIn;
  final VoidCallback onForgotPassword;
  final VoidCallback onNavigateToSignUp;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onSignIn,
    required this.onForgotPassword,
    required this.onNavigateToSignUp,
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
            const LoginHeader(),
            const SizedBox(height: 32),
            EmailField(controller: emailController),
            const SizedBox(height: 16),
            PasswordField(controller: passwordController),
            ForgotPasswordButton(onPressed: onForgotPassword),
            const SizedBox(height: 16),
            LoginButton(onPressed: onSignIn),
            const SizedBox(height: 16),
            SignUpNavigation(onPressed: onNavigateToSignUp),
          ],
        ),
      ),
    );
  }
}
