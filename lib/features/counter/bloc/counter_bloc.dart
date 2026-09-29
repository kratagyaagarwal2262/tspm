import 'package:tspm/core/router/exports.dart';

part 'counter_event.dart';
part 'counter_state.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState()) {
    on<CounterIncrementPressed>((event, emit) {
      emit(state.copyWith(count: state.count + 1));
    });
  }
}
