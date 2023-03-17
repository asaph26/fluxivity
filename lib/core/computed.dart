import 'dart:async';
import 'package:async/async.dart';
import 'package:fluxivity/core/snapshot.dart';

import 'reactive.dart';

class Computed<T> {
  final List<Reactive<dynamic>> _sources;
  final T Function(List<Reactive<dynamic>>) _compute;

  late T _value;

  Computed(this._sources, this._compute) {
    _value = _compute(_sources);

    StreamGroup.merge(_sources.map((source) => source.stream)).listen((_) {
      final newValue = _compute(_sources);
      if (newValue != _value) {
        _value = newValue;
        _controller.add(Snapshot(_value, newValue));
      }
    });
  }

  Stream<Snapshot<T>> get stream => _controller.stream;
  final _controller = StreamController<Snapshot<T>>.broadcast();

  T get value => _value;

  void dispose() {
    _controller.close();
  }

  @override
  String toString() {
    return 'Computed: ${value.toString()}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Computed &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
