import 'package:flutter_bloc/flutter_bloc.dart';
part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc
    extends Bloc<DashboardEvent,
        DashboardState> {

  DashboardBloc()
      : super(
          const DashboardState(),
        ) {

    on<DashboardInitialEvent>(
      _onInitial,
    );
  }

  Future<void> _onInitial(
    DashboardInitialEvent event,
    Emitter<DashboardState> emit,
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