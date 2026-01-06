abstract class ClassGroupsState {}

class ClassGroupsInitial extends ClassGroupsState {}

class ClassGroupsLoading extends ClassGroupsState {}

class ClassGroupsLoaded extends ClassGroupsState {
  final List<String> groupNames;
  ClassGroupsLoaded(this.groupNames);
}

class ClassGroupsError extends ClassGroupsState {
  final String message;
  ClassGroupsError(this.message);
}
