import 'package:flutter_bloc/flutter_bloc.dart';
part 'player_profile_event.dart';
part 'player_profile_state.dart';

class PlayerProfileBloc
    extends Bloc<PlayerProfileEvent,
        PlayerProfileState> {

  PlayerProfileBloc()
      : super(
          const PlayerProfileState(),
        ) {

    on<PlayerProfileInitialEvent>(
      _onInitial,
    );
  }

  Future<void> _onInitial(
    PlayerProfileInitialEvent event,
    Emitter<PlayerProfileState> emit,
  ) async {

    emit(
      state.copyWith(
        isLoading: true,
      ),
    );

    // Add your feature logic here

    emit(
      state.copyWith(
        isLoading: false,
      ),
    );
  }
}