# Example Use Cases of Fluzivity

The above folder contains various example apps of the Fluxivity. 

## The default Counter App

```dart
import 'package:flutter/material.dart';
import 'package:fluxivity/fluxivity.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Counter App')),
        body: const Center(child: CounterDisplay()),
        floatingActionButton: const CounterActions(),
      ),
    );
  }
}

final counter = Reactive<int>(0);

class CounterDisplay extends StatelessWidget {
  const CounterDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
      stream: counter.stream,
      builder: (context, snapshot) {
        return Text(
          'Counter: ${counter.value}',
          style: Theme.of(context).textTheme.headline4,
        );
      },
    );
  }
}

class CounterActions extends StatelessWidget {
  const CounterActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: () => counter.value += 1,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: () => counter.value -= 1,
          tooltip: 'Decrement',
          child: const Icon(Icons.remove),
        ),
      ],
    );
  }
}
```

## The Todo App

COMING SOON

## Temperature Convertor

COMING SOON