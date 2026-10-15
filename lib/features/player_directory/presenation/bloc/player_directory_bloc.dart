import 'package:flutter_bloc/flutter_bloc.dart';
part 'player_directory_event.dart';
part 'player_directory_state.dart';

class PlayerDirectoryBloc
    extends Bloc<PlayerDirectoryEvent,
        PlayerDirectoryState> {

  PlayerDirectoryBloc()
      : super(
          const PlayerDirectoryState(),
        ) {

    on<PlayerDirectoryInitialEvent>(
      _onInitial,
    );
  }

  Future<void> _onInitial(
    PlayerDirectoryInitialEvent event,
    Emitter<PlayerDirectoryState> emit,
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