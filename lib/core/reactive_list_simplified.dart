import '../plugins/plugin_abstract.dart';
import 'reactive.dart';
import 'snapshot.dart';

extension ReactiveListExtensions<E> on List<E> {
  Reactive<List<E>> get reactive {
    return Reactive<List<E>>(List<E>.from(this));
  }

  Reactive<List<E>> toReactive(
      {List<FluxivityMiddleware<List<E>>>? middlewares}) {
    return Reactive<List<E>>(List<E>.from(this), middlewares: middlewares);
  }
}

// Helper methods for reactive lists
extension ReactiveListHelpers<E> on Reactive<List<E>> {
  void addEffect(Function(Snapshot<List<E>>) effect) {
    stream.listen(effect);
  }

  // Helper methods to support the tests with the new implementation
  List<E> unwrap() {
    return value;
  }
}
