import '../plugins/plugin_abstract.dart';
import 'reactive.dart';
import 'snapshot.dart';

extension ReactiveSetExtensions<E> on Set<E> {
  Reactive<Set<E>> get reactive {
    return Reactive<Set<E>>(Set<E>.from(this));
  }

  Reactive<Set<E>> toReactive(
      {List<FluxivityMiddleware<Set<E>>>? middlewares}) {
    return Reactive<Set<E>>(Set<E>.from(this), middlewares: middlewares);
  }
}

// Helper methods for reactive sets
extension ReactiveSetHelpers<E> on Reactive<Set<E>> {
  void addEffect(Function(Snapshot<Set<E>>) effect) {
    stream.listen(effect);
  }

  Set<E> unwrap() {
    return value;
  }
}
