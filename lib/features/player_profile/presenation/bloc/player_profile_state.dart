part of 'player_profile_bloc.dart';

class PlayerProfileState {
  final bool isLoading;

  const PlayerProfileState({
    this.isLoading = false,
  });

  PlayerProfileState copyWith({
    bool? isLoading,
  }) {
    return PlayerProfileState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}