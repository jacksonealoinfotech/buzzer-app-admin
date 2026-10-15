part of 'player_directory_bloc.dart';

class PlayerDirectoryState {
  final bool isLoading;

  const PlayerDirectoryState({
    this.isLoading = false,
  });

  PlayerDirectoryState copyWith({
    bool? isLoading,
  }) {
    return PlayerDirectoryState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}