import 'package:flutter_bloc/flutter_bloc.dart';
part 'reports_moderation_event.dart';
part 'reports_moderation_state.dart';

class ReportsModerationBloc
    extends Bloc<ReportsModerationEvent,
        ReportsModerationState> {

  ReportsModerationBloc()
      : super(
          const ReportsModerationState(),
        ) {

    on<ReportsModerationInitialEvent>(
      _onInitial,
    );
  }

  Future<void> _onInitial(
    ReportsModerationInitialEvent event,
    Emitter<ReportsModerationState> emit,
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