import 'package:flutter_bloc/flutter_bloc.dart';
part 'all_games_event.dart';
part 'all_games_state.dart';

class AllGamesBloc
    extends Bloc<AllGamesEvent,
        AllGamesState> {

  AllGamesBloc()
      : super(
          const AllGamesState(),
        ) {

    on<AllGamesInitialEvent>(
      _onInitial,
    );
  }

  Future<void> _onInitial(
    AllGamesInitialEvent event,
    Emitter<AllGamesState> emit,
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