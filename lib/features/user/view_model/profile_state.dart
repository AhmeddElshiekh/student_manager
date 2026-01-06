import 'package:firebase_auth/firebase_auth.dart';
import 'package:equatable/equatable.dart';

enum ProfileStatus { initial, loading, success, error }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.firebaseUser,
    this.username,
    this.isAdmin = false,
    this.errorMessage,
    this.infoMessage,
  });

  final ProfileStatus status;
  final User? firebaseUser;
  final String? username;
  final bool isAdmin;
  final String? errorMessage;
  final String? infoMessage;

  ProfileState copyWith({
    ProfileStatus? status,
    User? firebaseUser,
    String? username,
    bool? isAdmin,
    String? errorMessage,
    String? infoMessage,
    bool clearMessages = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      username: username ?? this.username,
      isAdmin: isAdmin ?? this.isAdmin,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearMessages ? null : infoMessage ?? this.infoMessage,
    );
  }

  @override
  List<Object?> get props => [status, firebaseUser, username, isAdmin, errorMessage, infoMessage];
}
