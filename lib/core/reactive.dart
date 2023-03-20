import 'dart:async';

import 'package:rxdart/rxdart.dart';

import './snapshot.dart';

/// A Reactive class that represents a value that can be observed.
///
/// The value can be updated, and the change is propagated to its listeners.
class Reactive<T> {
  Reactive(this._value) {
    _controller.add(Snapshot(_value, _value));
  }

  T _value;
  T get value => _value;

  /// Returns a stream of snapshots containing the current and new values.
  Stream<Snapshot<T>> get stream => _controller.stream;
  final _controller = BehaviorSubject<Snapshot<T>>();

  /// Updates the value and notifies listeners if the value has changed.
  set value(T newValue) {
    if (newValue != _value) {
      _value = newValue;
      _controller.add(Snapshot(_value, newValue));
    }
  }

  void dispose() {
    _controller.close();
  }

  @override
  String toString() {
    return 'Reactive: ${_value.toString()}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reactive &&
          runtimeType == other.runtimeType &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Adds an effect function that gets called whenever the value changes.
  void addEffect(Function(Snapshot<T>) effect) {
    stream.listen((snapshot) {
      effect(snapshot);
    });
  }
}
