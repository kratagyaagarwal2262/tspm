part of 'counter_bloc.dart';

sealed class CounterEvent extends Equatable {
  const CounterEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class CounterIncrementPressed extends CounterEvent {
  const CounterIncrementPressed();
}
