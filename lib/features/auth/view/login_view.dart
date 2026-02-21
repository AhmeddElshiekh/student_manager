import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nizam/core/navigation/app_router.dart';
import 'package:nizam/features/auth/view/signup_view.dart';
import 'package:nizam/features/auth/view/widgets/login_form.dart';
import 'package:nizam/features/auth/view/widgets/reset_password_dialog.dart';
import 'package:nizam/features/auth/view_model/auth_cubit.dart';
import 'package:nizam/features/auth/view_model/auth_state.dart';

class LoginView extends StatefulWidget {
  final String? initialMessage;
  final bool isError;

  const LoginView({
    super.key,
    this.initialMessage,
    this.isError = false,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _formKey = GlobalKey<FormState>();

    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar(widget.initialMessage!, isError: widget.isError);
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthCubit>(),
        child: const ResetPasswordDialog(),
      ),
    );
  }

  void _navigateToSignUp() {
    AppRouter.push(context, const SignUpView());
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: LoginForm(
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    onSignIn: isLoading ? null : _signIn,
                    onForgotPassword: _showResetPasswordDialog,
                    onNavigateToSignUp: _navigateToSignUp,
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withAlpha(128),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
