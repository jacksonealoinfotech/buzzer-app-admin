import 'package:flutter_bloc/flutter_bloc.dart';
part 'host_management_event.dart';
part 'host_management_state.dart';

class HostManagementBloc
    extends Bloc<HostManagementEvent,
        HostManagementState> {

  HostManagementBloc()
      : super(
          const HostManagementState(),
        ) {

    on<HostManagementInitialEvent>(
      _onInitial,
    );
  }

  Future<void> _onInitial(
    HostManagementInitialEvent event,
    Emitter<HostManagementState> emit,
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