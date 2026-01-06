import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user.uid];
}

class AuthUnauthenticated extends AuthState {
  final String? message;
  final bool isError;
  final int? timestamp;

  const AuthUnauthenticated({
    this.message,
    this.isError = false,
    this.timestamp
  });

  @override
  List<Object?> get props => [message, isError, timestamp];

  AuthUnauthenticated copyWith({String? message, bool? isError}) {
    return AuthUnauthenticated(
      message: message ?? this.message,
      isError: isError ?? this.isError,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
}