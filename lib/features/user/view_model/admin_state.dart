import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AdminStatus { initial, loading, success, error }

class UserModel extends Equatable {
  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
    required this.isApproved,
    required this.deviceIds,
    required this.maxDevices,
  });

  final String uid;
  final String email;
  final String displayName;
  final String phoneNumber;
  final bool isApproved;
  final List<String> deviceIds;
  final int maxDevices;

  factory UserModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return UserModel(
      uid: snap.id,
      email: data['email'] ?? 'غير متاح',
      displayName: data['name'] ?? 'اسم غير متاح',
      phoneNumber: data['phone'] ?? 'رقم هاتف غير متاح',
      isApproved: data['isApproved'] ?? false,
      deviceIds: List<String>.from(data['deviceIds'] ?? []),
      maxDevices: data['maxDevices'] ?? 1,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, phoneNumber, isApproved, deviceIds, maxDevices];
}

class AdminState extends Equatable {
  const AdminState({
    this.status = AdminStatus.initial,
    this.users = const <UserModel>[],
    this.filter = 'all',
    this.errorMessage,
  });

  final AdminStatus status;
  final List<UserModel> users;
  final String filter;
  final String? errorMessage;

  AdminState copyWith({
    AdminStatus? status,
    List<UserModel>? users,
    String? filter,
    String? errorMessage,
  }) {
    return AdminState(
      status: status ?? this.status,
      users: users ?? this.users,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, users, filter, errorMessage];
}