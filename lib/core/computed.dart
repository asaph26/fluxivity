import 'dart:async';
import 'package:async/async.dart';
import 'package:fluxivity/core/snapshot.dart';

import 'reactive.dart';
import 'package:rxdart/rxdart.dart';

/// A Computed class that computes a value based on the values of one or more Reactive instances.
///
/// The computed value is updated whenever any of the source Reactive instances change,
/// and the change is propagated to its listeners.
class Computed<T> {
  final List<Reactive<dynamic>> _sources;
  final T Function(List<Reactive<dynamic>>) _compute;

  /// Returns a stream of snapshots containing the computed value. New snapshots are emitted whenever the computed value changes.
  Stream<Snapshot<T>> get stream => _controller.stream;
  final _controller = BehaviorSubject<Snapshot<T>>();
  late T _value;

  /// Constructs a new Computed instance.
  ///
  /// [_sources] is a list of Reactive instances whose values are used to compute the new value.
  /// [_compute] is a function that takes the list of Reactive instances and computes the new value.
  Computed(this._sources, this._compute) {
    _value = _compute(_sources);
    _controller.add(Snapshot(_value, _value));

    StreamGroup.merge(_sources.map((source) => source.stream)).listen((_) {
      final newValue = _compute(_sources);
      if (newValue != _value) {
        _value = newValue;
        _controller.add(Snapshot(_value, newValue));
      }
    });
  }

  /// Returns the current computed value.
  T get value => _value;

  /// Disposes of the internal stream controller.
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
