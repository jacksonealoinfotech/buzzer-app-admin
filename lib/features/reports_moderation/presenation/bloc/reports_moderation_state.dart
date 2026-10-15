part of 'reports_moderation_bloc.dart';

class ReportsModerationState {
  final bool isLoading;

  const ReportsModerationState({
    this.isLoading = false,
  });

  ReportsModerationState copyWith({
    bool? isLoading,
  }) {
    return ReportsModerationState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}