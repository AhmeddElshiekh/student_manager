import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nizam/features/auth/view_model/auth_cubit.dart';
import 'package:nizam/features/auth/view_model/auth_state.dart';

class LoginButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const LoginButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {


        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(

            onPressed: onPressed,
            child: const Text('تسجيل الدخول'),
          ),
        );
      },
    );
  }
}
