part of 'all_games_bloc.dart';

class AllGamesState {
  final bool isLoading;

  const AllGamesState({
    this.isLoading = false,
  });

  AllGamesState copyWith({
    bool? isLoading,
  }) {
    return AllGamesState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}