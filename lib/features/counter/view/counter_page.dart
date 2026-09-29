import 'package:tspm/core/router/exports.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CounterBloc>(
      create: (_) => CounterBloc(),
      child: _CounterView(title: title),
    );
  }
}

class _CounterView extends StatelessWidget {
  const _CounterView({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(AppStrings.counterPrompt),
            BlocBuilder<CounterBloc, CounterState>(
              builder: (context, state) {
                return Text(
                  '${state.count}',
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<CounterBloc>().add(const CounterIncrementPressed());
        },
        tooltip: AppStrings.incrementTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }
}
