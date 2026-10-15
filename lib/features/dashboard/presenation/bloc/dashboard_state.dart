part of 'dashboard_bloc.dart';

class DashboardState {
  final bool isLoading;

  const DashboardState({
    this.isLoading = false,
  });

  DashboardState copyWith({
    bool? isLoading,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}