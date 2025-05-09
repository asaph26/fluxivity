import '../plugins/plugin_abstract.dart';
import 'reactive.dart';
import 'snapshot.dart';

extension ReactiveMapExtensions<K, V> on Map<K, V> {
  Reactive<Map<K, V>> get reactive {
    return Reactive<Map<K, V>>(Map<K, V>.from(this));
  }

  Reactive<Map<K, V>> toReactive(
      {List<FluxivityMiddleware<Map<K, V>>>? middlewares}) {
    return Reactive<Map<K, V>>(Map<K, V>.from(this), middlewares: middlewares);
  }
}

// Helper methods for reactive maps
extension ReactiveMapHelpers<K, V> on Reactive<Map<K, V>> {
  void addEffect(Function(Snapshot<Map<K, V>>) effect) {
    stream.listen(effect);
  }

  Map<K, V> unwrap() {
    return value;
  }
}
