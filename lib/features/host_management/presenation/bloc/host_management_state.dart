part of 'host_management_bloc.dart';

class HostManagementState {
  final bool isLoading;

  const HostManagementState({
    this.isLoading = false,
  });

  HostManagementState copyWith({
    bool? isLoading,
  }) {
    return HostManagementState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}