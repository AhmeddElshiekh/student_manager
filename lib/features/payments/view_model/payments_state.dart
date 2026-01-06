
abstract class PaymentsState {}

class PaymentsInitial extends PaymentsState {}

class PaymentsLoading extends PaymentsState {}

class PaymentsLoaded extends PaymentsState {
  final List<String> classNames;
  PaymentsLoaded(this.classNames);
}

class PaymentsError extends PaymentsState {
  final String message;
  PaymentsError(this.message);
}
